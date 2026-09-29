import { Controller, Post, Body, UseGuards, Param, ParseUUIDPipe } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { InitiatePaymentDto, ConfirmPaymentDto } from './dto/payments.dto';
import { UserRole } from '../common/enums';

@Controller('payments')
@UseGuards(JwtAuthGuard)
export class PaymentsController {
  constructor(private paymentsService: PaymentsService) {}

  @Post('initiate')
  initiate(@CurrentUser('id') userId: string, @Body() dto: InitiatePaymentDto) {
    return this.paymentsService.initiate(userId, dto);
  }

  @Post('confirm')
  confirm(@CurrentUser('id') userId: string, @Body() dto: ConfirmPaymentDto) {
    return this.paymentsService.confirm(userId, dto);
  }

  @Post(':bookingId/release')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  release(@Param('bookingId', ParseUUIDPipe) bookingId: string) {
    return this.paymentsService.release(bookingId);
  }
}
