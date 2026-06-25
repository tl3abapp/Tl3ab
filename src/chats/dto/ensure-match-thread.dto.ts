import { IsUUID } from 'class-validator';

export class EnsureMatchThreadDto {
  @IsUUID()
  userId!: string;
}
