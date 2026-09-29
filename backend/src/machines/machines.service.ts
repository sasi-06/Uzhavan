import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { v4 as uuidv4 } from 'uuid';
import {
  CreateMachineDto,
  UpdateMachineDto,
  SearchMachinesDto,
  BlockAvailabilityDto,
} from './dto/machines.dto';
import { MachineStatus } from '../common/enums';

@Injectable()
export class MachinesService {
  async create(ownerId: string, dto: CreateMachineDto) {
    const db = getFirestore();
    const id = uuidv4();
    const machine = {
      id,
      ownerId,
      type: dto.type,
      model: dto.model ?? null,
      photos: dto.photos ?? [],
      pricePerHour: dto.pricePerHour !== undefined ? Number(dto.pricePerHour) : null,
      pricePerAcre: dto.pricePerAcre !== undefined ? Number(dto.pricePerAcre) : null,
      serviceRadiusKm: dto.serviceRadiusKm !== undefined ? Number(dto.serviceRadiusKm) : 10,
      operatorIncluded: dto.operatorIncluded ?? false,
      status: MachineStatus.PENDING_APPROVAL,
      latitude: dto.latitude !== undefined ? Number(dto.latitude) : null,
      longitude: dto.longitude !== undefined ? Number(dto.longitude) : null,
      description: dto.description ?? null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    await db.collection('machines').doc(id).set(machine);
    
    return this.findOne(id);
  }

  async findByOwner(ownerId: string) {
    const db = getFirestore();
    const snap = await db
      .collection('machines')
      .where('ownerId', '==', ownerId)
      .get();
    
    const list = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        ...data,
        createdAt: data.createdAt?.toDate?.() || data.createdAt,
        updatedAt: data.updatedAt?.toDate?.() || data.updatedAt,
      };
    });

    return list.sort((a: any, b: any) => b.createdAt - a.createdAt);
  }

  async findOne(id: string) {
    const db = getFirestore();
    const doc = await db.collection('machines').doc(id).get();
    if (!doc.exists) throw new NotFoundException('Machine not found');
    const machine = doc.data()!;

    const ownerDoc = await db.collection('users').doc(machine.ownerId).get();
    const owner = ownerDoc.exists ? ownerDoc.data() : null;

    return {
      ...machine,
      createdAt: machine.createdAt?.toDate?.() || machine.createdAt,
      updatedAt: machine.updatedAt?.toDate?.() || machine.updatedAt,
      owner,
    } as any;
  }

  async update(id: string, ownerId: string, dto: UpdateMachineDto) {
    const db = getFirestore();
    const machine = await this.findOne(id);
    if (machine.ownerId !== ownerId) throw new ForbiddenException();

    const updateData: any = {};
    if (dto.type !== undefined) updateData.type = dto.type;
    if (dto.model !== undefined) updateData.model = dto.model;
    if (dto.photos !== undefined) updateData.photos = dto.photos;
    if (dto.pricePerHour !== undefined) updateData.pricePerHour = Number(dto.pricePerHour);
    if (dto.pricePerAcre !== undefined) updateData.pricePerAcre = Number(dto.pricePerAcre);
    if (dto.serviceRadiusKm !== undefined) updateData.serviceRadiusKm = Number(dto.serviceRadiusKm);
    if (dto.operatorIncluded !== undefined) updateData.operatorIncluded = dto.operatorIncluded;
    if (dto.latitude !== undefined) updateData.latitude = Number(dto.latitude);
    if (dto.longitude !== undefined) updateData.longitude = Number(dto.longitude);
    if (dto.description !== undefined) updateData.description = dto.description;
    if (dto.status !== undefined) updateData.status = dto.status;
    updateData.updatedAt = FieldValue.serverTimestamp();

    await db.collection('machines').doc(id).update(updateData);
    return this.findOne(id);
  }

  async search(dto: SearchMachinesDto) {
    const db = getFirestore();
    const radius = dto.radiusKm ?? 50;
    
    let query: any = db
      .collection('machines')
      .where('status', '==', MachineStatus.ACTIVE);

    if (dto.type) {
      query = query.where('type', '==', dto.type);
    }

    const snap = await query.get();
    const userLat = Number(dto.latitude);
    const userLng = Number(dto.longitude);

    const machines = await Promise.all(
      snap.docs.map(async (doc: any) => {
        const m = doc.data();
        const ownerDoc = await db.collection('users').doc(m.ownerId).get();
        const owner = ownerDoc.exists ? ownerDoc.data() : null;

        const distance = this.haversineKm(
          userLat,
          userLng,
          Number(m.latitude ?? 0),
          Number(m.longitude ?? 0),
        );

        return {
          ...m,
          createdAt: m.createdAt?.toDate?.() || m.createdAt,
          updatedAt: m.updatedAt?.toDate?.() || m.updatedAt,
          owner,
          distanceKm: distance,
        };
      }),
    );

    const filtered = machines.filter(
      (m: any) => m.distanceKm <= Math.min(Number(m.serviceRadiusKm ?? 10), radius),
    );

    return filtered.sort((a: any, b: any) => a.distanceKm - b.distanceKm);
  }

  async blockAvailability(machineId: string, ownerId: string, dto: BlockAvailabilityDto) {
    const db = getFirestore();
    const machine = await this.findOne(machineId);
    if (machine.ownerId !== ownerId) throw new ForbiddenException();

    const id = uuidv4();
    const block = {
      id,
      machineId,
      startDate: Timestamp.fromDate(new Date(dto.startDate)),
      endDate: Timestamp.fromDate(new Date(dto.endDate)),
      isBlocked: true,
      createdAt: FieldValue.serverTimestamp(),
    };

    await db.collection('availabilities').doc(id).set(block);

    return {
      ...block,
      startDate: block.startDate.toDate(),
      endDate: block.endDate.toDate(),
    };
  }

  async approveListing(id: string) {
    const db = getFirestore();
    const machine = await this.findOne(id);
    if (machine.status !== MachineStatus.PENDING_APPROVAL) {
      throw new BadRequestException('Machine is not pending approval');
    }
    await db.collection('machines').doc(id).update({
      status: MachineStatus.ACTIVE,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return this.findOne(id);
  }

  async rejectListing(id: string) {
    const db = getFirestore();
    await db.collection('machines').doc(id).update({
      status: MachineStatus.INACTIVE,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return this.findOne(id);
  }

  private haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLng = ((lng2 - lng1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLng / 2) ** 2;
    return Math.round(R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)) * 10) / 10;
  }
}
