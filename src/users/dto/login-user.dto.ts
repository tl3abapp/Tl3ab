import { IsString, MinLength } from 'class-validator';

export class LoginUserDto {
  @IsString()
  @MinLength(2)
  email!: string;

  @IsString()
  @MinLength(6)
  password!: string;
}
