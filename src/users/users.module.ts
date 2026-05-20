import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import {
  FollowEntity,
  MatchEntity,
  MatchParticipantEntity,
  NotificationEntity,
  PostEntity,
  UserEntity,
} from '../database/entities';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      UserEntity,
      FollowEntity,
      MatchEntity,
      MatchParticipantEntity,
      PostEntity,
      NotificationEntity,
    ]),
  ],
  providers: [UsersService],
  controllers: [UsersController],
  exports: [UsersService, TypeOrmModule],
})
export class UsersModule {}
