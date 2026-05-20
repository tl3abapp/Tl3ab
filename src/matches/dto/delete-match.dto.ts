import { IsUUID } from 'class-validator';

export class DeleteMatchDto {
  @IsUUID()
  hostId!: string;
}
