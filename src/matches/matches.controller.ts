import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Param,
  Post,
  Query,
} from '@nestjs/common';
import { CurrentUserId } from '../auth/current-user.decorator';
import { CreateMatchDto } from './dto/create-match.dto';
import { DeleteMatchDto } from './dto/delete-match.dto';
import { InvitePlayersDto } from './dto/invite-players.dto';
import { JoinMatchDto } from './dto/join-match.dto';
import { MatchesService } from './matches.service';
import { ModerateRequestDto } from './dto/moderate-request.dto';
import { UpdateMatchPrivacyDto } from './dto/update-match-privacy.dto';
import { ReplacePlayerDto } from './dto/replace-player.dto';
import { UpdateMatchDetailsDto } from './dto/update-match-details.dto';

@Controller('matches')
export class MatchesController {
  constructor(private readonly matchesService: MatchesService) {}

  @Get()
  list(
    @Query('area') area?: string,
    @Query('privateOnly') privateOnly?: string,
    @Query('userId') userId?: string,
    @CurrentUserId() currentUserId?: string,
  ) {
    if (userId && userId !== currentUserId) {
      throw new ForbiddenException('Cannot list matches as another user');
    }
    return this.matchesService.list(
      area,
      privateOnly === 'true',
      userId ?? currentUserId,
    );
  }

  @Get(':id')
  details(@Param('id') id: string) {
    return this.matchesService.details(id);
  }

  @Post()
  create(@Body() dto: CreateMatchDto, @CurrentUserId() currentUserId: string) {
    this.ensureSelf(dto.hostId, currentUserId);
    return this.matchesService.create(dto);
  }

  @Post(':id/join')
  join(
    @Param('id') id: string,
    @Body() dto: JoinMatchDto,
    @CurrentUserId() currentUserId: string,
  ) {
    this.ensureSelf(dto.userId, currentUserId);
    return this.matchesService.join(id, dto);
  }

  @Post(':id/leave')
  leave(
    @Param('id') id: string,
    @Body() dto: JoinMatchDto,
    @CurrentUserId() currentUserId: string,
  ) {
    this.ensureSelf(dto.userId, currentUserId);
    return this.matchesService.leave(id, dto);
  }

  @Post(':id/invite')
  invite(
    @Param('id') id: string,
    @Body() dto: InvitePlayersDto,
    @CurrentUserId() currentUserId: string,
  ) {
    this.ensureSelf(dto.hostId, currentUserId);
    return this.matchesService.invite(id, dto);
  }

  @Post(':id/privacy')
  updatePrivacy(
    @Param('id') id: string,
    @Body() dto: UpdateMatchPrivacyDto,
    @CurrentUserId() currentUserId: string,
  ) {
    this.ensureSelf(dto.hostId, currentUserId);
    return this.matchesService.updatePrivacy(id, dto);
  }

  @Post(':id/details')
  updateDetails(
    @Param('id') id: string,
    @Body() dto: UpdateMatchDetailsDto,
    @CurrentUserId() currentUserId: string,
  ) {
    this.ensureSelf(dto.hostId, currentUserId);
    return this.matchesService.updateDetails(id, dto);
  }

  @Post(':id/replace-player')
  replacePlayer(
    @Param('id') id: string,
    @Body() dto: ReplacePlayerDto,
    @CurrentUserId() currentUserId: string,
  ) {
    this.ensureSelf(dto.hostId, currentUserId);
    return this.matchesService.replacePlayer(id, dto);
  }

  @Delete(':id')
  deleteMatch(
    @Param('id') id: string,
    @Body() dto: DeleteMatchDto,
    @CurrentUserId() currentUserId: string,
  ) {
    this.ensureSelf(dto.hostId, currentUserId);
    return this.matchesService.deleteMatch(id, dto.hostId);
  }

  @Post(':id/requests/:participantId/approve')
  approve(
    @Param('id') id: string,
    @Param('participantId') participantId: string,
    @Body() dto: ModerateRequestDto,
    @CurrentUserId() currentUserId: string,
  ) {
    this.ensureSelf(dto.hostId, currentUserId);
    return this.matchesService.approve(id, participantId, dto.hostId);
  }

  @Post(':id/requests/:participantId/reject')
  reject(
    @Param('id') id: string,
    @Param('participantId') participantId: string,
    @Body() dto: ModerateRequestDto,
    @CurrentUserId() currentUserId: string,
  ) {
    this.ensureSelf(dto.hostId, currentUserId);
    return this.matchesService.reject(id, participantId, dto.hostId);
  }

  @Post(':id/requests/:participantId/hold')
  hold(
    @Param('id') id: string,
    @Param('participantId') participantId: string,
    @Body() dto: ModerateRequestDto,
    @CurrentUserId() currentUserId: string,
  ) {
    this.ensureSelf(dto.hostId, currentUserId);
    return this.matchesService.hold(id, participantId, dto.hostId);
  }

  private ensureSelf(id: string, currentUserId: string): void {
    if (id !== currentUserId) {
      throw new ForbiddenException('Cannot act as another user');
    }
  }
}
