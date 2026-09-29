import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { v4 as uuidv4 } from 'uuid';
import { NotificationsService } from '../firebase/notifications.service';
import { ConfigService } from '@nestjs/config';
import { InitiatePaymentDto, ConfirmPaymentDto } from './dto/payments.dto';
import { PaymentMode, PaymentStatus, BookingStatus } from '../common/enums';

@Injectable()
export class PaymentsService {
  constructor(
    private notificationsService: NotificationsService,
    private config: ConfigService,
  ) {}

  async initiate(userId: string, dto: InitiatePaymentDto) {
    const db = getFirestore();
    const bookingDoc = await db.collection('bookings').doc(dto.bookingId).get();
    if (!bookingDoc.exists) throw new NotFoundException('Booking not found');
    const booking = bookingDoc.data()!;
    if (booking.renterId !== userId) throw new ForbiddenException();

    const paymentsSnap = await db
      .collection('payments')
      .where('bookingId', '==', dto.bookingId)
      .limit(1)
      .get();
    if (!paymentsSnap.empty) throw new BadRequestException('Payment already initiated');

    const machineDoc = await db.collection('machines').doc(booking.machineId).get();
    const machine = machineDoc.exists ? machineDoc.data() : null;

    const commissionRate = this.config.get<number>('commission.ratePercent') ?? 10;
    const commissionAmount = (Number(booking.priceTotal) * commissionRate) / 100;

    const paymentId = uuidv4();
    const payment = {
      id: paymentId,
      bookingId: dto.bookingId,
      amount: booking.priceTotal,
      mode: dto.mode,
      status: dto.mode === PaymentMode.CASH ? PaymentStatus.HELD : PaymentStatus.PENDING,
      commissionAmount,
      gatewayPaymentId: null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    await db.collection('payments').doc(paymentId).set(payment);

    if (dto.mode === PaymentMode.UPI) {
      // TODO: create Razorpay order and return checkout params
      return {
        payment,
        gateway: 'razorpay',
        orderId: `order_dev_${paymentId}`,
        keyId: this.config.get('razorpay.keyId'),
        message: 'Complete payment via UPI',
      };
    }

    // Cash mode
    await db.collection('bookings').doc(dto.bookingId).update({
      depositPaid: true,
      status: BookingStatus.CONFIRMED,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Notify owner of Cash booking
    if (machine) {
      try {
        await this.notificationsService.sendNotification(
          machine.ownerId,
          'Cash Booking Confirmed',
          `Booking for ${machine.model || machine.type} was confirmed with Cash on pickup.`,
          { bookingId: dto.bookingId },
        );
      } catch (err) {
        console.error('Failed to send cash payment notification', err);
      }
    }

    return { payment, message: 'Cash on pickup — pay owner directly at handover' };
  }

  async confirm(userId: string, dto: ConfirmPaymentDto) {
    const db = getFirestore();
    const paymentsSnap = await db
      .collection('payments')
      .where('bookingId', '==', dto.bookingId)
      .limit(1)
      .get();
    if (paymentsSnap.empty) throw new NotFoundException('Payment not found');
    const paymentDoc = paymentsSnap.docs[0];
    const payment = paymentDoc.data()!;

    // Fetch booking
    const bookingDoc = await db.collection('bookings').doc(dto.bookingId).get();
    if (!bookingDoc.exists) throw new NotFoundException('Booking not found');
    const booking = bookingDoc.data()!;
    if (booking.renterId !== userId) throw new ForbiddenException();

    // Fetch machine to get ownerId
    const machineDoc = await db.collection('machines').doc(booking.machineId).get();
    const machine = machineDoc.exists ? machineDoc.data() : null;

    const updatedPayment = {
      status: PaymentStatus.HELD,
      gatewayPaymentId: dto.gatewayPaymentId ?? payment.gatewayPaymentId,
      updatedAt: FieldValue.serverTimestamp(),
    };

    await db.collection('payments').doc(payment.id).update(updatedPayment);

    await db.collection('bookings').doc(dto.bookingId).update({
      depositPaid: true,
      status: BookingStatus.CONFIRMED,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Notify owner of UPI booking payment confirmation
    if (machine) {
      try {
        await this.notificationsService.sendNotification(
          machine.ownerId,
          'Payment Confirmed',
          `Payment of ₹${booking.priceTotal} was confirmed. Booking is now confirmed!`,
          { bookingId: dto.bookingId },
        );
      } catch (err) {
        console.error('Failed to send payment confirmation notification', err);
      }
    }

    return {
      ...payment,
      ...updatedPayment,
    };
  }

  async release(bookingId: string) {
    const db = getFirestore();
    const paymentsSnap = await db
      .collection('payments')
      .where('bookingId', '==', bookingId)
      .limit(1)
      .get();
    if (paymentsSnap.empty) throw new NotFoundException('Payment not found');
    const paymentDoc = paymentsSnap.docs[0];
    const payment = paymentDoc.data()!;

    const bookingDoc = await db.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) throw new NotFoundException('Booking not found');
    const booking = bookingDoc.data()!;
    if (booking.status !== BookingStatus.COMPLETED) {
      throw new BadRequestException('Job must be completed before payout release');
    }

    // Fetch machine to get ownerId
    const machineDoc = await db.collection('machines').doc(booking.machineId).get();
    const machine = machineDoc.exists ? machineDoc.data() : null;

    await db.collection('payments').doc(payment.id).update({
      status: PaymentStatus.RELEASED,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Notify owner that payment has been released
    if (machine) {
      try {
        await this.notificationsService.sendNotification(
          machine.ownerId,
          'Payment Released',
          `Payout of ₹${Number(booking.priceTotal) - Number(payment.commissionAmount)} has been released to your account.`,
          { bookingId },
        );
      } catch (err) {
        console.error('Failed to send release notification', err);
      }
    }

    return {
      ...payment,
      status: PaymentStatus.RELEASED,
    };
  }
}
