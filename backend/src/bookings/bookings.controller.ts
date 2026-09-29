import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { BookingsService } from './bookings.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { CreateBookingDto } from './dto/bookings.dto';
import { UserRole } from '../common/enums';

@Controller('bookings')
@UseGuards(JwtAuthGuard)
export class BookingsController {
  constructor(private bookingsService: BookingsService) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(UserRole.FARMER, UserRole.BOTH)
  create(@CurrentUser('id') renterId: string, @Body() dto: CreateBookingDto) {
    return this.bookingsService.create(renterId, dto);
  }

  @Get('mine')
  findMine(@CurrentUser('id') userId: string, @CurrentUser('role') role: string) {
    if (role === UserRole.OWNER) {
      return this.bookingsService.findByOwner(userId);
    }
    return this.bookingsService.findByRenter(userId);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.bookingsService.findOne(id);
  }

  @Post(':id/confirm')
  confirm(@Param('id', ParseUUIDPipe) id: string, @CurrentUser('id') userId: string) {
    return this.bookingsService.confirm(id, userId, false);
  }

  @Post(':id/owner-accept')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER, UserRole.BOTH)
  ownerAccept(@Param('id', ParseUUIDPipe) id: string, @CurrentUser('id') ownerId: string) {
    return this.bookingsService.ownerAccept(id, ownerId);
  }

  @Post(':id/owner-decline')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER, UserRole.BOTH)
  ownerDecline(@Param('id', ParseUUIDPipe) id: string, @CurrentUser('id') ownerId: string) {
    return this.bookingsService.ownerDecline(id, ownerId);
  }

  /** @deprecated Use owner-accept instead */
  @Post(':id/owner-confirm')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER, UserRole.BOTH)
  ownerConfirm(@Param('id', ParseUUIDPipe) id: string, @CurrentUser('id') ownerId: string) {
    return this.bookingsService.ownerAccept(id, ownerId);
  }

  @Post(':id/cancel')
  cancel(@Param('id', ParseUUIDPipe) id: string, @CurrentUser('id') userId: string) {
    return this.bookingsService.cancel(id, userId);
  }

  @Post(':id/complete')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER, UserRole.BOTH)
  complete(@Param('id', ParseUUIDPipe) id: string, @CurrentUser('id') ownerId: string) {
    return this.bookingsService.complete(id, ownerId);
  }
}
