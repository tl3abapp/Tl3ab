import { IsOptional, IsUUID } from 'class-validator';

export class ReplacePlayerDto {
  @IsUUID()
  hostId!: string;

  @IsUUID()
  removeUserId!: string;

  @IsUUID()
  inviteUserId!: string;

  @IsOptional()
  side?: 'left' | 'right';
}
