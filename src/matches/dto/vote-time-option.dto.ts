import { IsString, IsUUID } from 'class-validator';

export class VoteTimeOptionDto {
  @IsUUID()
  userId!: string;

  @IsString()
  optionId!: string;
}
