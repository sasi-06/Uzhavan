import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { getFirestore, Timestamp, FieldValue } from 'firebase-admin/firestore';
import { v4 as uuidv4 } from 'uuid';
import * as bcrypt from 'bcrypt';
import { SendOtpDto, VerifyOtpDto, RegisterDto } from './dto/auth.dto';
import { UserRole, PreferredLanguage, KycStatus } from '../common/enums';


@Injectable()
export class AuthService {
  constructor(
    private jwtService: JwtService,
    private config: ConfigService,
  ) {}

  async sendOtp(dto: SendOtpDto): Promise<{ message: string; devOtp?: string }> {
    const db = getFirestore();
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const ttl = this.config.get<number>('otp.expiresSeconds') ?? 300;
    const expiresAt = new Date(Date.now() + ttl * 1000);

    await db.collection('otps').doc(dto.phone).set({
      phone: dto.phone,
      otp,
      expiresAt: Timestamp.fromDate(expiresAt),
    });

    // TODO: integrate SMS gateway (Twilio / local telecom)
    const isDev = process.env.NODE_ENV !== 'production';
    return {
      message: 'OTP sent successfully',
      ...(isDev ? { devOtp: otp } : {}),
    };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    const db = getFirestore();
    const otpDoc = await db.collection('otps').doc(dto.phone).get();
    if (!otpDoc.exists) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }

    const data = otpDoc.data()!;
    const now = Date.now();
    const expiresAt = data.expiresAt.toDate().getTime();

    if (data.otp !== dto.otp || now > expiresAt) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }

    await db.collection('otps').doc(dto.phone).delete();

    const usersSnap = await db
      .collection('users')
      .where('phone', '==', dto.phone)
      .limit(1)
      .get();

    if (usersSnap.empty) {
      throw new BadRequestException('User not registered. Complete registration first.');
    }

    const userDoc = usersSnap.docs[0];
    const user = userDoc.data();

    return this.issueToken({
      id: userDoc.id,
      name: user.name,
      phone: user.phone,
      role: user.role,
      preferredLanguage: user.preferredLanguage,
      kycStatus: user.kycStatus,
    });
  }

  async register(dto: RegisterDto) {
    const db = getFirestore();
    const otpDoc = await db.collection('otps').doc(dto.phone).get();
    if (!otpDoc.exists) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }

    const data = otpDoc.data()!;
    const now = Date.now();
    const expiresAt = data.expiresAt.toDate().getTime();

    if (data.otp !== dto.otp || now > expiresAt) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }

    await db.collection('otps').doc(dto.phone).delete();

    const usersSnap = await db
      .collection('users')
      .where('phone', '==', dto.phone)
      .limit(1)
      .get();

    if (!usersSnap.empty) {
      throw new BadRequestException('Phone number already registered');
    }

    const id = uuidv4();
    const passwordHash = dto.password
      ? await bcrypt.hash(dto.password, 10)
      : null;

    const user = {
      phone: dto.phone,
      name: dto.name,
      role: (dto.role as UserRole) ?? UserRole.FARMER,
      preferredLanguage:
        (dto.preferredLanguage as PreferredLanguage) ?? PreferredLanguage.TAMIL,
      kycStatus: KycStatus.PENDING,
      kycDocumentUrl: null,
      village: dto.village ?? null,
      district: dto.district ?? null,
      passwordHash,
      latitude: null,
      longitude: null,
      fcmTokens: [],
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };


    await db.collection('users').doc(id).set(user);

    return this.issueToken({
      id,
      name: user.name,
      phone: user.phone,
      role: user.role,
      preferredLanguage: user.preferredLanguage,
      kycStatus: user.kycStatus,
    });
  }

  private issueToken(user: any) {
    const payload = { sub: user.id, phone: user.phone, role: user.role };
    return {
      accessToken: this.jwtService.sign(payload),
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        role: user.role,
        preferredLanguage: user.preferredLanguage,
        kycStatus: user.kycStatus,
      },
    };
  }
}
