import {
  IsEnum,
  IsOptional,
  IsString,
  IsNumber,
  IsBoolean,
  IsArray,
  IsDateString,
  Min,
} from 'class-validator';
import { MachineType, MachineStatus } from '../../common/enums';

export class CreateMachineDto {
  @IsEnum(MachineType)
  type: MachineType;

  @IsOptional()
  @IsString()
  model?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photos?: string[];

  @IsOptional()
  @IsNumber()
  @Min(0)
  pricePerHour?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  pricePerAcre?: number;

  @IsOptional()
  @IsNumber()
  @Min(1)
  serviceRadiusKm?: number;

  @IsOptional()
  @IsBoolean()
  operatorIncluded?: boolean;

  @IsNumber()
  latitude: number;

  @IsNumber()
  longitude: number;

  @IsOptional()
  @IsString()
  description?: string;
}

export class UpdateMachineDto {
  @IsOptional()
  @IsEnum(MachineType)
  type?: MachineType;

  @IsOptional()
  @IsString()
  model?: string;

  @IsOptional()
  @IsArray()
  photos?: string[];

  @IsOptional()
  @IsNumber()
  pricePerHour?: number;

  @IsOptional()
  @IsNumber()
  pricePerAcre?: number;

  @IsOptional()
  @IsNumber()
  serviceRadiusKm?: number;

  @IsOptional()
  @IsBoolean()
  operatorIncluded?: boolean;

  @IsOptional()
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @IsNumber()
  longitude?: number;

  @IsOptional()
  @IsEnum(MachineStatus)
  status?: MachineStatus;

  @IsOptional()
  @IsString()
  description?: string;
}

export class SearchMachinesDto {
  @IsOptional()
  @IsEnum(MachineType)
  type?: MachineType;

  @IsNumber()
  latitude: number;

  @IsNumber()
  longitude: number;

  @IsOptional()
  @IsNumber()
  radiusKm?: number;

  @IsOptional()
  @IsDateString()
  date?: string;
}

export class BlockAvailabilityDto {
  @IsDateString()
  startDate: string;

  @IsDateString()
  endDate: string;
}
