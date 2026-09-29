import {
  IsUUID,
  IsDateString,
  IsOptional,
  IsNumber,
  IsBoolean,
  Min,
} from 'class-validator';

export class CreateBookingDto {
  @IsUUID()
  machineId: string;

  @IsDateString()
  startDate: string;

  @IsDateString()
  endDate: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  areaAcres?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  hours?: number;

  @IsOptional()
  @IsBoolean()
  operatorIncluded?: boolean;
}

export class UpdateBookingStatusDto {
  @IsOptional()
  status?: string;
}
