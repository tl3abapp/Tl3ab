import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import {
  PostEntity,
  PostLikeEntity,
  PostReportEntity,
  UserBlockEntity,
  UserEntity,
} from '../database/entities';
import { PostsController } from './posts.controller';
import { PostsService } from './posts.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      PostEntity,
      PostLikeEntity,
      PostReportEntity,
      UserBlockEntity,
      UserEntity,
    ]),
  ],
  providers: [PostsService],
  controllers: [PostsController],
  exports: [PostsService],
})
export class PostsModule {}
