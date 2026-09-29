import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { MachinesService } from './machines.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import {
  CreateMachineDto,
  UpdateMachineDto,
  SearchMachinesDto,
  BlockAvailabilityDto,
} from './dto/machines.dto';
import { UserRole } from '../common/enums';

@Controller('machines')
export class MachinesController {
  constructor(private machinesService: MachinesService) {}

  @Get('search')
  search(@Query() dto: SearchMachinesDto) {
    return this.machinesService.search(dto);
  }

  @Get('owner/mine')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.OWNER, UserRole.BOTH)
  findMine(@CurrentUser('id') ownerId: string) {
    return this.machinesService.findByOwner(ownerId);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.machinesService.findOne(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.OWNER, UserRole.BOTH)
  create(@CurrentUser('id') ownerId: string, @Body() dto: CreateMachineDto) {
    return this.machinesService.create(ownerId, dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.OWNER, UserRole.BOTH)
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser('id') ownerId: string,
    @Body() dto: UpdateMachineDto,
  ) {
    return this.machinesService.update(id, ownerId, dto);
  }

  @Post(':id/availability/block')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.OWNER, UserRole.BOTH)
  blockAvailability(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser('id') ownerId: string,
    @Body() dto: BlockAvailabilityDto,
  ) {
    return this.machinesService.blockAvailability(id, ownerId, dto);
  }

  @Post(':id/approve')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  approve(@Param('id', ParseUUIDPipe) id: string) {
    return this.machinesService.approveListing(id);
  }

  @Post(':id/reject')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  reject(@Param('id', ParseUUIDPipe) id: string) {
    return this.machinesService.rejectListing(id);
  }
}
