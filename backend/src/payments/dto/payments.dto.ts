import { IsUUID, IsEnum } from 'class-validator';
import { PaymentMode } from '../../common/enums';

export class InitiatePaymentDto {
  @IsUUID()
  bookingId: string;

  @IsEnum(PaymentMode)
  mode: PaymentMode;
}

export class ConfirmPaymentDto {
  @IsUUID()
  bookingId: string;

  gatewayPaymentId?: string;
}
