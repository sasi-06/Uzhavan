import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { v4 as uuidv4 } from 'uuid';
import { NotificationsService } from '../firebase/notifications.service';
import { CreateBookingDto } from './dto/bookings.dto';
import { BookingStatus, MachineStatus } from '../common/enums';

@Injectable()
export class BookingsService {
  constructor(
    private notificationsService: NotificationsService,
  ) {}

  async create(renterId: string, dto: CreateBookingDto) {
    const db = getFirestore();
    const start = new Date(dto.startDate);
    const end = new Date(dto.endDate);
    if (end <= start) throw new BadRequestException('End date must be after start date');

    const bookingId = uuidv4();
    let machine: any = null;

    // Run transaction for concurrency locking
    await db.runTransaction(async (transaction) => {
      const machineRef = db.collection('machines').doc(dto.machineId);
      const machineDoc = await transaction.get(machineRef);

      if (!machineDoc.exists) {
        throw new NotFoundException('Machine not found');
      }
      machine = machineDoc.data()!;
      if (machine.status !== MachineStatus.ACTIVE) {
        throw new NotFoundException('Machine not available');
      }

      // Check blocked dates
      const availabilitiesSnap = await transaction.get(
        db.collection('availabilities').where('machineId', '==', dto.machineId),
      );
      const blocked = availabilitiesSnap.docs.some((doc) => {
        const data = doc.data();
        if (!data.isBlocked) return false;
        const blockStart = data.startDate.toDate();
        const blockEnd = data.endDate.toDate();
        // Check overlap
        return start < blockEnd && end > blockStart;
      });
      if (blocked) {
        throw new BadRequestException('Machine is blocked for selected dates');
      }

      // Check conflicting bookings — PENDING, ACCEPTED, CONFIRMED, IN_PROGRESS all block dates
      const bookingsSnap = await transaction.get(
        db.collection('bookings').where('machineId', '==', dto.machineId),
      );
      const conflicting = bookingsSnap.docs.some((doc) => {
        const data = doc.data();
        // Only cancelled/disputed bookings do NOT block dates
        if (
          data.status === BookingStatus.CANCELLED ||
          data.status === BookingStatus.DISPUTED
        ) return false;
        const bookStart = data.startDate.toDate();
        const bookEnd = data.endDate.toDate();
        return start < bookEnd && end > bookStart;
      });
      if (conflicting) {
        throw new BadRequestException(
          'Machine already booked for these dates. Please choose different dates.',
        );
      }

      const priceTotal = this.calculatePrice(machine, dto);

      const bookingData = {
        id: bookingId,
        machineId: dto.machineId,
        renterId,
        startDate: Timestamp.fromDate(start),
        endDate: Timestamp.fromDate(end),
        areaAcres: dto.areaAcres ?? null,
        hours: dto.hours ?? null,
        operatorIncluded: dto.operatorIncluded ?? machine.operatorIncluded,
        priceTotal,
        status: BookingStatus.PENDING,
        depositPaid: false,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      };

      transaction.set(db.collection('bookings').doc(bookingId), bookingData);
    });

    // Notify owner about the new booking request
    try {
      await this.notificationsService.sendNotification(
        machine.ownerId,
        'New Booking Request',
        `A renter wants to book your machine (${machine.model || machine.type}) starting ${dto.startDate}.`,
        { bookingId },
      );
    } catch (err) {
      console.error('Failed to send booking notification', err);
    }

    return this.findOne(bookingId);
  }

  async findByRenter(renterId: string) {
    const db = getFirestore();
    const snap = await db
      .collection('bookings')
      .where('renterId', '==', renterId)
      .get();

    const bookings = await Promise.all(
      snap.docs.map(async (doc) => {
        const b = doc.data();
        const machine = await this.getMachineWithOwner(b.machineId);
        return {
          ...b,
          startDate: b.startDate.toDate(),
          endDate: b.endDate.toDate(),
          createdAt: b.createdAt?.toDate?.() || b.createdAt,
          updatedAt: b.updatedAt?.toDate?.() || b.updatedAt,
          machine,
        };
      }),
    );

    return bookings.sort((a, b) => b.createdAt - a.createdAt);
  }

  async findByOwner(ownerId: string) {
    const db = getFirestore();
    // 1. Get owner's machine IDs
    const machinesSnap = await db
      .collection('machines')
      .where('ownerId', '==', ownerId)
      .get();

    if (machinesSnap.empty) return [];
    const machineIds = machinesSnap.docs.map((doc) => doc.id);

    // 2. Fetch bookings for these machines (filter client-side; Firestore
    //    does not support IN with >10 items without multiple queries)
    const bookingsSnap = await db.collection('bookings').get();

    const ownerBookings = bookingsSnap.docs.filter((doc) =>
      machineIds.includes(doc.data().machineId),
    );

    const bookings = await Promise.all(
      ownerBookings.map(async (doc) => {
        const b = doc.data();
        const machine = await this.getMachineWithOwner(b.machineId);
        const renterDoc = await db.collection('users').doc(b.renterId).get();
        const renter = renterDoc.exists ? renterDoc.data() : null;

        return {
          ...b,
          startDate: b.startDate.toDate(),
          endDate: b.endDate.toDate(),
          createdAt: b.createdAt?.toDate?.() || b.createdAt,
          updatedAt: b.updatedAt?.toDate?.() || b.updatedAt,
          machine,
          renter,
        };
      }),
    );

    return bookings.sort((a, b) => b.createdAt - a.createdAt);
  }

  async findOne(id: string): Promise<any> {
    const db = getFirestore();
    const doc = await db.collection('bookings').doc(id).get();
    if (!doc.exists) throw new NotFoundException('Booking not found');
    const booking = doc.data()!;

    const machine = await this.getMachineWithOwner(booking.machineId);
    const renterDoc = await db.collection('users').doc(booking.renterId).get();
    const renter = renterDoc.exists ? renterDoc.data() : null;

    // Populate payment
    const paymentsSnap = await db
      .collection('payments')
      .where('bookingId', '==', id)
      .limit(1)
      .get();
    const payment = !paymentsSnap.empty ? paymentsSnap.docs[0].data() : null;

    return {
      ...booking,
      startDate: booking.startDate.toDate(),
      endDate: booking.endDate.toDate(),
      createdAt: booking.createdAt?.toDate?.() || booking.createdAt,
      updatedAt: booking.updatedAt?.toDate?.() || booking.updatedAt,
      machine,
      renter,
      payment,
    };
  }

  /**
   * Owner accepts a pending request → status becomes ACCEPTED.
   * This locks the machine dates so no other farmer can book for the same period.
   */
  async ownerAccept(id: string, ownerId: string) {
    const db = getFirestore();
    const booking = await this.findOne(id);
    if (booking.machine.ownerId !== ownerId) throw new ForbiddenException();

    if (booking.status !== BookingStatus.PENDING) {
      throw new BadRequestException(
        `Cannot accept a booking with status "${booking.status}". Only pending requests can be accepted.`,
      );
    }

    await db.collection('bookings').doc(id).update({
      status: BookingStatus.ACCEPTED,
      updatedAt: FieldValue.serverTimestamp(),
    });

    const updated = await this.findOne(id);

    try {
      await this.notificationsService.sendNotification(
        booking.renterId,
        'Booking Accepted! ✅',
        `Your booking request for ${booking.machine.model || booking.machine.type} has been accepted by the owner. Get ready!`,
        { bookingId: id },
      );
    } catch (err) {
      console.error('Failed to send acceptance notification', err);
    }

    return updated;
  }

  /**
   * Owner declines a pending request → status becomes CANCELLED.
   * Dates are freed and other farmers can now book this machine.
   */
  async ownerDecline(id: string, ownerId: string) {
    const db = getFirestore();
    const booking = await this.findOne(id);
    if (booking.machine.ownerId !== ownerId) throw new ForbiddenException();

    if (booking.status !== BookingStatus.PENDING) {
      throw new BadRequestException(
        `Cannot decline a booking with status "${booking.status}".`,
      );
    }

    await db.collection('bookings').doc(id).update({
      status: BookingStatus.CANCELLED,
      declinedBy: 'owner',
      updatedAt: FieldValue.serverTimestamp(),
    });

    const updated = await this.findOne(id);

    try {
      await this.notificationsService.sendNotification(
        booking.renterId,
        'Booking Declined',
        `Sorry, the owner has declined your booking request for ${booking.machine.model || booking.machine.type}. Please try another machine.`,
        { bookingId: id },
      );
    } catch (err) {
      console.error('Failed to send decline notification', err);
    }

    return updated;
  }

  /**
   * Legacy confirm method — kept for backward compatibility.
   * Owner confirm → ACCEPTED, farmer confirm on ACCEPTED → CONFIRMED.
   */
  async confirm(id: string, userId: string, isOwner: boolean) {
    const db = getFirestore();
    const booking = await this.findOne(id);
    if (isOwner && booking.machine.ownerId !== userId) throw new ForbiddenException();
    if (!isOwner && booking.renterId !== userId) throw new ForbiddenException();

    if (isOwner) {
      // Owner acting on a PENDING booking → ACCEPTED
      if (booking.status !== BookingStatus.PENDING) {
        throw new BadRequestException(
          `Owner can only accept PENDING bookings (current: ${booking.status}).`,
        );
      }
      return this.ownerAccept(id, userId);
    } else {
      // Farmer acting on an ACCEPTED booking → CONFIRMED (job ready)
      if (booking.status !== BookingStatus.ACCEPTED) {
        throw new BadRequestException(
          `You can only confirm a booking after the owner has accepted it (current: ${booking.status}).`,
        );
      }
      await db.collection('bookings').doc(id).update({
        status: BookingStatus.CONFIRMED,
        updatedAt: FieldValue.serverTimestamp(),
      });
      const updated = await this.findOne(id);
      try {
        await this.notificationsService.sendNotification(
          booking.machine.ownerId,
          'Farmer Confirmed Booking ✅',
          'The farmer has confirmed the booking. Please head to the location!',
          { bookingId: id },
        );
      } catch (err) {
        console.error('Failed to send farmer-confirm notification', err);
      }
      return updated;
    }
  }

  async cancel(id: string, userId: string) {
    const db = getFirestore();
    const booking = await this.findOne(id);
    if (booking.renterId !== userId && booking.machine.ownerId !== userId) {
      throw new ForbiddenException();
    }
    if ([BookingStatus.COMPLETED, BookingStatus.CANCELLED].includes(booking.status)) {
      throw new BadRequestException('Booking cannot be cancelled');
    }

    await db.collection('bookings').doc(id).update({
      status: BookingStatus.CANCELLED,
      updatedAt: FieldValue.serverTimestamp(),
    });

    const updated = await this.findOne(id);

    // Notify the other party
    try {
      const isRenter = booking.renterId === userId;
      const notifyTarget = isRenter ? booking.machine.ownerId : booking.renterId;
      const notifyMessage = isRenter
        ? 'Farmer has cancelled the booking. Machine dates are now free.'
        : 'Owner has cancelled the booking. You may rebook another machine.';
      await this.notificationsService.sendNotification(
        notifyTarget,
        'Booking Cancelled',
        notifyMessage,
        { bookingId: id },
      );
    } catch (err) {
      console.error('Failed to send cancellation notification', err);
    }

    return updated;
  }

  async complete(id: string, ownerId: string) {
    const db = getFirestore();
    const booking = await this.findOne(id);
    if (booking.machine.ownerId !== ownerId) throw new ForbiddenException();

    const allowedStatuses = [
      BookingStatus.CONFIRMED,
      BookingStatus.IN_PROGRESS,
    ];
    if (!allowedStatuses.includes(booking.status)) {
      throw new BadRequestException(
        `Only CONFIRMED or IN_PROGRESS bookings can be completed (current: ${booking.status}).`,
      );
    }

    await db.collection('bookings').doc(id).update({
      status: BookingStatus.COMPLETED,
      updatedAt: FieldValue.serverTimestamp(),
    });

    const updated = await this.findOne(id);

    // Notify renter
    try {
      await this.notificationsService.sendNotification(
        booking.renterId,
        'Job Completed ✅',
        `The owner has marked the job as completed for ${booking.machine.model || booking.machine.type}. Please release the payment.`,
        { bookingId: id },
      );
    } catch (err) {
      console.error('Failed to send completion notification', err);
    }

    return updated;
  }

  private async getMachineWithOwner(machineId: string) {
    const db = getFirestore();
    const machineDoc = await db.collection('machines').doc(machineId).get();
    if (!machineDoc.exists) return null;
    const machine = machineDoc.data()!;
    const ownerDoc = await db.collection('users').doc(machine.ownerId).get();
    const owner = ownerDoc.exists ? ownerDoc.data() : null;
    return {
      ...machine,
      owner,
    };
  }

  private calculatePrice(machine: any, dto: CreateBookingDto): number {
    if (dto.areaAcres && machine.pricePerAcre) {
      return Number(machine.pricePerAcre) * dto.areaAcres;
    }
    if (dto.hours && machine.pricePerHour) {
      return Number(machine.pricePerHour) * dto.hours;
    }
    const days =
      (new Date(dto.endDate).getTime() - new Date(dto.startDate).getTime()) /
      (1000 * 60 * 60 * 24);
    return Number(machine.pricePerHour ?? machine.pricePerAcre ?? 0) * Math.max(days, 1);
  }
}
