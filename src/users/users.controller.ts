import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Param,
  Post,
} from '@nestjs/common';
import { AuthTokenService } from '../auth/auth-token.service';
import { CurrentUserId } from '../auth/current-user.decorator';
import { Public } from '../auth/public.decorator';
import { CreateUserDto } from './dto/create-user.dto';
import { DeactivateUserDto } from './dto/deactivate-user.dto';
import { LoginUserDto } from './dto/login-user.dto';
import { UpdateUserPhotoDto } from './dto/update-user-photo.dto';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly authTokenService: AuthTokenService,
  ) {}

  @Get()
  findAll() {
    return this.usersService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.usersService.findById(id);
  }

  @Post()
  @Public()
  async create(@Body() dto: CreateUserDto) {
    const user = await this.usersService.create(dto);
    return this.withToken(user);
  }

  @Post('login')
  @Public()
  async login(@Body() dto: LoginUserDto) {
    const user = await this.usersService.login(dto);
    return this.withToken(user);
  }

  @Post(':id/photo')
  updatePhoto(
    @Param('id') id: string,
    @Body() dto: UpdateUserPhotoDto,
    @CurrentUserId() currentUserId: string,
  ) {
    this.ensureSelf(id, currentUserId);
    return this.usersService.updatePhoto(id, dto.photoData ?? null);
  }

  @Post(':id/deactivate')
  deactivate(
    @Param('id') id: string,
    @Body() dto: DeactivateUserDto,
    @CurrentUserId() currentUserId: string,
  ) {
    this.ensureSelf(id, currentUserId);
    return this.usersService.deactivate(id, dto.days ?? 40);
  }

  @Post(':id/reactivate')
  reactivate(@Param('id') id: string, @CurrentUserId() currentUserId: string) {
    this.ensureSelf(id, currentUserId);
    return this.usersService.reactivate(id);
  }

  @Delete(':id')
  deleteAccount(
    @Param('id') id: string,
    @CurrentUserId() currentUserId: string,
  ) {
    this.ensureSelf(id, currentUserId);
    return this.usersService.deleteAccount(id);
  }

  @Post(':id/follow/:targetId')
  follow(
    @Param('id') id: string,
    @Param('targetId') targetId: string,
    @CurrentUserId() currentUserId: string,
  ) {
    this.ensureSelf(id, currentUserId);
    return this.usersService.follow(id, targetId);
  }

  @Delete(':id/follow/:targetId')
  unfollow(
    @Param('id') id: string,
    @Param('targetId') targetId: string,
    @CurrentUserId() currentUserId: string,
  ) {
    this.ensureSelf(id, currentUserId);
    return this.usersService.unfollow(id, targetId);
  }

  @Get(':id/followers')
  followers(@Param('id') id: string, @CurrentUserId() currentUserId: string) {
    this.ensureSelf(id, currentUserId);
    return this.usersService.followers(id);
  }

  @Get(':id/following')
  following(@Param('id') id: string, @CurrentUserId() currentUserId: string) {
    this.ensureSelf(id, currentUserId);
    return this.usersService.following(id);
  }

  private withToken<T extends { id: string }>(user: T): T & { token: string } {
    return Object.assign(user, {
      token: this.authTokenService.signUser(user.id),
    });
  }

  private ensureSelf(id: string, currentUserId: string): void {
    if (id !== currentUserId) {
      throw new ForbiddenException('Cannot access another account');
    }
  }
}
