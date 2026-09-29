import { IsOptional, IsString, IsNumber, IsEnum } from 'class-validator';
import { PreferredLanguage } from '../../common/enums';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsEnum(PreferredLanguage)
  preferredLanguage?: PreferredLanguage;

  @IsOptional()
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @IsNumber()
  longitude?: number;
}

export class SubmitKycDto {
  @IsString()
  kycDocumentUrl: string;
}

export class RegisterFcmTokenDto {
  @IsString()
  token: string;
}
