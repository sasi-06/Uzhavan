import { Injectable, NotFoundException } from '@nestjs/common';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { UpdateProfileDto, SubmitKycDto } from './dto/users.dto';
import { KycStatus } from '../common/enums';

@Injectable()
export class UsersService {
  async getProfile(userId: string) {
    const db = getFirestore();
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) throw new NotFoundException('User not found');
    const user = userDoc.data()!;
    const { name, phone, role, preferredLanguage, kycStatus, latitude, longitude } = user;
    return { id: userDoc.id, name, phone, role, preferredLanguage, kycStatus, latitude, longitude };
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const db = getFirestore();
    const updateData: any = {};
    if (dto.name !== undefined) updateData.name = dto.name;
    if (dto.preferredLanguage !== undefined) updateData.preferredLanguage = dto.preferredLanguage;
    if (dto.latitude !== undefined) updateData.latitude = dto.latitude;
    if (dto.longitude !== undefined) updateData.longitude = dto.longitude;
    
    updateData.updatedAt = FieldValue.serverTimestamp();

    await db.collection('users').doc(userId).update(updateData);
    return this.getProfile(userId);
  }

  async submitKyc(userId: string, dto: SubmitKycDto) {
    const db = getFirestore();
    await db.collection('users').doc(userId).update({
      kycDocumentUrl: dto.kycDocumentUrl,
      kycStatus: KycStatus.SUBMITTED,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return this.getProfile(userId);
  }

  async registerFcmToken(userId: string, token: string) {
    const db = getFirestore();
    await db.collection('users').doc(userId).update({
      fcmTokens: FieldValue.arrayUnion(token),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { success: true };
  }
}
