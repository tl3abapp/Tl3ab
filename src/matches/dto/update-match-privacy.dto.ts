import { IsArray, IsBoolean, IsIn, IsOptional, IsUUID } from 'class-validator';

export class UpdateMatchPrivacyDto {
  @IsUUID()
  hostId!: string;

  @IsBoolean()
  isPrivate!: boolean;

  @IsIn(['public', 'friends', 'circle', 'selected'])
  @IsOptional()
  targetScope?: 'public' | 'friends' | 'circle' | 'selected';

  @IsArray()
  @IsUUID('4', { each: true })
  @IsOptional()
  inviteUserIds?: string[];
}
