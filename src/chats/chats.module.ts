import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import {
  ChatMemberEntity,
  ChatMessageEntity,
  ChatThreadEntity,
  MatchEntity,
  MatchParticipantEntity,
  UserEntity,
} from '../database/entities';
import { ChatsController } from './chats.controller';
import { ChatsService } from './chats.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      ChatThreadEntity,
      ChatMemberEntity,
      ChatMessageEntity,
      UserEntity,
      MatchEntity,
      MatchParticipantEntity,
    ]),
  ],
  controllers: [ChatsController],
  providers: [ChatsService],
  exports: [ChatsService],
})
export class ChatsModule {}
