import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  Min,
  MinLength,
} from 'class-validator';

export class CreateMatchDto {
  @IsUUID()
  hostId!: string;

  @IsString()
  @MinLength(2)
  title!: string;

  @IsString()
  area!: string;

  @IsString()
  courtName!: string;

  @IsDateString()
  startsAt!: string;

  @IsBoolean()
  @IsOptional()
  isPrivate?: boolean;

  @IsInt()
  @Min(2)
  @Max(8)
  @IsOptional()
  maxPlayers?: number;

  @IsInt()
  @Min(1)
  @Max(10)
  @IsOptional()
  skillMin?: number;

  @IsInt()
  @Min(1)
  @Max(10)
  @IsOptional()
  skillMax?: number;

  @IsArray()
  @IsUUID('4', { each: true })
  @IsOptional()
  inviteUserIds?: string[];

  @IsIn(['public', 'friends', 'circle', 'selected'])
  @IsOptional()
  targetScope?: 'public' | 'friends' | 'circle' | 'selected';
}
