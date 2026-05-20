import { IsInt, IsOptional, Max, Min } from 'class-validator';

export class DeactivateUserDto {
  @IsInt()
  @Min(1)
  @Max(90)
  @IsOptional()
  days?: number;
}
