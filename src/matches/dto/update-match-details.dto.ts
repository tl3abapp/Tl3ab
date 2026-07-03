import { IsDateString, IsOptional, IsString, IsUUID } from 'class-validator';

export class UpdateMatchDetailsDto {
  @IsUUID()
  hostId!: string;

  @IsDateString()
  @IsOptional()
  startsAt?: string;

  @IsString()
  @IsOptional()
  courtName?: string;

  @IsString()
  @IsOptional()
  courtPhotoData?: string;
}
