import {
  IsDateString,
  IsEmail,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  Min,
  MinLength,
} from 'class-validator';

export class CreateUserDto {
  @IsString()
  @MinLength(2)
  name!: string;

  @IsString()
  @MinLength(2)
  handle!: string;

  @IsEmail()
  email!: string;

  @IsString()
  @Matches(/^\+?[0-9]{8,15}$/)
  phoneNumber!: string;

  @IsDateString()
  birthDate!: string;

  @IsString()
  @MinLength(6)
  password!: string;

  @IsString()
  @IsOptional()
  photoData?: string;

  @IsInt()
  @Min(1)
  @Max(10)
  @IsOptional()
  skillLevel?: number;

  @IsString()
  @IsOptional()
  area?: string;

  @IsString()
  @IsOptional()
  avatarColor?: string;
}
