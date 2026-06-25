import { IsUUID } from 'class-validator';

export class CreateDirectThreadDto {
  @IsUUID()
  userId!: string;

  @IsUUID()
  targetUserId!: string;
}
