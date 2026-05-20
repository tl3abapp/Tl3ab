import { IsOptional, IsString, IsUUID } from 'class-validator';

export class JoinMatchDto {
  @IsUUID()
  userId!: string;

  @IsString()
  @IsOptional()
  inviteCode?: string;
}
