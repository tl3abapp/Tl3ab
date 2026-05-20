import { IsUUID } from 'class-validator';

export class ModerateRequestDto {
  @IsUUID()
  hostId!: string;
}
