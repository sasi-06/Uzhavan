import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { getFirestore } from 'firebase-admin/firestore';

export interface JwtPayload {
  sub: string;
  phone: string;
  role: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.get<string>('jwt.secret') ?? 'dev-secret',
    });
  }

  async validate(payload: JwtPayload) {
    const db = getFirestore();
    const userDoc = await db.collection('users').doc(payload.sub).get();
    if (!userDoc.exists) throw new UnauthorizedException();
    const user = userDoc.data()!;
    return { id: userDoc.id, phone: user.phone, role: user.role, name: user.name };
  }
}
