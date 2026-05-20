import { Body, Controller, Delete, Get, Param, Post } from '@nestjs/common';
import { CreateUserDto } from './dto/create-user.dto';
import { DeactivateUserDto } from './dto/deactivate-user.dto';
import { LoginUserDto } from './dto/login-user.dto';
import { UpdateUserPhotoDto } from './dto/update-user-photo.dto';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  findAll() {
    return this.usersService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.usersService.findById(id);
  }

  @Post()
  create(@Body() dto: CreateUserDto) {
    return this.usersService.create(dto);
  }

  @Post('login')
  login(@Body() dto: LoginUserDto) {
    return this.usersService.login(dto);
  }

  @Post(':id/photo')
  updatePhoto(@Param('id') id: string, @Body() dto: UpdateUserPhotoDto) {
    return this.usersService.updatePhoto(id, dto.photoData ?? null);
  }

  @Post(':id/deactivate')
  deactivate(@Param('id') id: string, @Body() dto: DeactivateUserDto) {
    return this.usersService.deactivate(id, dto.days ?? 40);
  }

  @Post(':id/reactivate')
  reactivate(@Param('id') id: string) {
    return this.usersService.reactivate(id);
  }

  @Delete(':id')
  deleteAccount(@Param('id') id: string) {
    return this.usersService.deleteAccount(id);
  }

  @Post(':id/follow/:targetId')
  follow(@Param('id') id: string, @Param('targetId') targetId: string) {
    return this.usersService.follow(id, targetId);
  }

  @Delete(':id/follow/:targetId')
  unfollow(@Param('id') id: string, @Param('targetId') targetId: string) {
    return this.usersService.unfollow(id, targetId);
  }

  @Get(':id/followers')
  followers(@Param('id') id: string) {
    return this.usersService.followers(id);
  }

  @Get(':id/following')
  following(@Param('id') id: string) {
    return this.usersService.following(id);
  }
}
