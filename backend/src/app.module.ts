import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import configuration from './config/configuration';
import { FirebaseModule } from './firebase/firebase.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { MachinesModule } from './machines/machines.module';
import { BookingsModule } from './bookings/bookings.module';
import { PaymentsModule } from './payments/payments.module';
import { SeedModule } from './seed/seed.module';
import { HealthController } from './health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, load: [configuration] }),
    FirebaseModule,
    AuthModule,
    UsersModule,
    MachinesModule,
    BookingsModule,
    PaymentsModule,
    SeedModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
