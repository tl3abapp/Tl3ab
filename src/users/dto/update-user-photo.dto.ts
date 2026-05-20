import { IsOptional, IsString } from 'class-validator';

export class UpdateUserPhotoDto {
  @IsOptional()
  @IsString()
  photoData?: string | null;
}
