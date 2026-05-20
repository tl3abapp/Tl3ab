import { IsArray, IsUUID } from 'class-validator';

export class InvitePlayersDto {
  @IsUUID()
  hostId!: string;

  @IsArray()
  @IsUUID('4', { each: true })
  targetUserIds!: string[];
}
