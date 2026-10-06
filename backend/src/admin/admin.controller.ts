import { Controller, Get, Post, Param } from '@nestjs/common';
import { AdminService } from './admin.service';

@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('overview')
  getOverview() {
    return this.adminService.getOverview();
  }

  @Get('machines')
  getMachines() {
    return this.adminService.getMachines();
  }

  @Post('machines/:id/approve')
  approveMachine(@Param('id') id: string) {
    return this.adminService.approveMachine(id);
  }

  @Post('machines/:id/reject')
  rejectMachine(@Param('id') id: string) {
    return this.adminService.rejectMachine(id);
  }

  @Get('bookings')
  getBookings() {
    return this.adminService.getBookings();
  }

  @Get('users')
  getUsers() {
    return this.adminService.getUsers();
  }

  @Post('users/:id/kyc-approve')
  approveUserKyc(@Param('id') id: string) {
    return this.adminService.approveUserKyc(id);
  }
}
