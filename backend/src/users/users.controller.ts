import { Controller, Get, Patch, Post, Body, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UpdateProfileDto, SubmitKycDto, RegisterFcmTokenDto } from './dto/users.dto';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get('me')
  getProfile(@CurrentUser('id') userId: string) {
    return this.usersService.getProfile(userId);
  }

  @Patch('me')
  updateProfile(@CurrentUser('id') userId: string, @Body() dto: UpdateProfileDto) {
    return this.usersService.updateProfile(userId, dto);
  }

  @Post('me/kyc')
  submitKyc(@CurrentUser('id') userId: string, @Body() dto: SubmitKycDto) {
    return this.usersService.submitKyc(userId, dto);
  }

  @Post('fcm-token')
  registerFcmToken(@CurrentUser('id') userId: string, @Body() dto: RegisterFcmTokenDto) {
    return this.usersService.registerFcmToken(userId, dto.token);
  }
}
