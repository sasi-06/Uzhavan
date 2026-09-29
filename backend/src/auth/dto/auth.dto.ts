import { IsString, IsNotEmpty, Length, Matches, IsOptional, MinLength } from 'class-validator';

export class SendOtpDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^\+?[6-9]\d{9}$/, { message: 'Invalid Indian phone number' })
  phone: string;
}

export class VerifyOtpDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^\+?[6-9]\d{9}$/)
  phone: string;

  @IsString()
  @Length(6, 6)
  otp: string;
}

export class RegisterDto extends VerifyOtpDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsOptional()
  role?: string;

  @IsString()
  @IsOptional()
  preferredLanguage?: string;

  @IsString()
  @IsOptional()
  @MinLength(6, { message: 'Password must be at least 6 characters' })
  password?: string;

  @IsString()
  @IsOptional()
  village?: string;

  @IsString()
  @IsOptional()
  district?: string;
}
