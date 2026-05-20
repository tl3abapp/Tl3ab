import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
} from '@nestjs/common';
import { CreateMatchDto } from './dto/create-match.dto';
import { DeleteMatchDto } from './dto/delete-match.dto';
import { InvitePlayersDto } from './dto/invite-players.dto';
import { JoinMatchDto } from './dto/join-match.dto';
import { MatchesService } from './matches.service';
import { ModerateRequestDto } from './dto/moderate-request.dto';
import { UpdateMatchPrivacyDto } from './dto/update-match-privacy.dto';

@Controller('matches')
export class MatchesController {
  constructor(private readonly matchesService: MatchesService) {}

  @Get()
  list(
    @Query('area') area?: string,
    @Query('privateOnly') privateOnly?: string,
  ) {
    return this.matchesService.list(area, privateOnly === 'true');
  }

  @Get(':id')
  details(@Param('id') id: string) {
    return this.matchesService.details(id);
  }

  @Post()
  create(@Body() dto: CreateMatchDto) {
    return this.matchesService.create(dto);
  }

  @Post(':id/join')
  join(@Param('id') id: string, @Body() dto: JoinMatchDto) {
    return this.matchesService.join(id, dto);
  }

  @Post(':id/leave')
  leave(@Param('id') id: string, @Body() dto: JoinMatchDto) {
    return this.matchesService.leave(id, dto);
  }

  @Post(':id/invite')
  invite(@Param('id') id: string, @Body() dto: InvitePlayersDto) {
    return this.matchesService.invite(id, dto);
  }

  @Post(':id/privacy')
  updatePrivacy(@Param('id') id: string, @Body() dto: UpdateMatchPrivacyDto) {
    return this.matchesService.updatePrivacy(id, dto);
  }

  @Delete(':id')
  deleteMatch(@Param('id') id: string, @Body() dto: DeleteMatchDto) {
    return this.matchesService.deleteMatch(id, dto.hostId);
  }

  @Post(':id/requests/:participantId/approve')
  approve(
    @Param('id') id: string,
    @Param('participantId') participantId: string,
    @Body() dto: ModerateRequestDto,
  ) {
    return this.matchesService.approve(id, participantId, dto.hostId);
  }

  @Post(':id/requests/:participantId/reject')
  reject(
    @Param('id') id: string,
    @Param('participantId') participantId: string,
    @Body() dto: ModerateRequestDto,
  ) {
    return this.matchesService.reject(id, participantId, dto.hostId);
  }

  @Post(':id/requests/:participantId/hold')
  hold(
    @Param('id') id: string,
    @Param('participantId') participantId: string,
    @Body() dto: ModerateRequestDto,
  ) {
    return this.matchesService.hold(id, participantId, dto.hostId);
  }
}
