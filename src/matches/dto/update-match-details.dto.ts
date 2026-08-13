import {
  IsArray,
  IsDateString,
  IsOptional,
  IsString,
  IsUUID,
} from 'class-validator';

export class UpdateMatchDetailsDto {
  @IsUUID()
  hostId!: string;

  @IsDateString()
  @IsOptional()
  startsAt?: string;

  @IsArray()
  @IsDateString({}, { each: true })
  @IsOptional()
  timeOptions?: string[];

  @IsString()
  @IsOptional()
  courtName?: string;

  @IsString()
  @IsOptional()
  courtPhotoData?: string;
}
