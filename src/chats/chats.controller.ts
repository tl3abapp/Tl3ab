import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { ChatsService } from './chats.service';
import { CreateDirectThreadDto } from './dto/create-direct-thread.dto';
import { EnsureMatchThreadDto } from './dto/ensure-match-thread.dto';
import { SendMessageDto } from './dto/send-message.dto';

@Controller('chats')
export class ChatsController {
  constructor(private readonly chatsService: ChatsService) {}

  @Get(':userId')
  list(@Param('userId') userId: string) {
    return this.chatsService.listForUser(userId);
  }

  @Get('thread/:threadId/messages')
  messages(
    @Param('threadId') threadId: string,
    @Query('userId') userId: string,
  ) {
    return this.chatsService.listForUser(userId).then((threads) => {
      const thread = threads.find((entry) => entry.id === threadId);
      return thread?.messages ?? [];
    });
  }

  @Post('direct')
  direct(@Body() dto: CreateDirectThreadDto) {
    return this.chatsService.ensureDirectThread(dto.userId, dto.targetUserId);
  }

  @Post('match/:matchId')
  match(@Param('matchId') matchId: string, @Body() dto: EnsureMatchThreadDto) {
    return this.chatsService.ensureMatchThread(matchId, dto.userId);
  }

  @Post(':threadId/messages')
  send(@Param('threadId') threadId: string, @Body() dto: SendMessageDto) {
    return this.chatsService.sendMessage(threadId, dto.userId, dto.text);
  }
}
