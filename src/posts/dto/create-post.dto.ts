import { IsString, IsUUID, MaxLength, MinLength } from 'class-validator';

export class CreatePostDto {
  @IsUUID()
  authorId!: string;

  @IsString()
  @MinLength(2)
  @MaxLength(600)
  content!: string;
}
