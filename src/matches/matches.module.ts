import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import {
  MatchEntity,
  MatchParticipantEntity,
  UserEntity,
} from '../database/entities';
import { NotificationsModule } from '../notifications/notifications.module';
import { MatchesController } from './matches.controller';
import { MatchesService } from './matches.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([MatchEntity, MatchParticipantEntity, UserEntity]),
    NotificationsModule,
  ],
  providers: [MatchesService],
  controllers: [MatchesController],
  exports: [MatchesService],
})
export class MatchesModule {}
