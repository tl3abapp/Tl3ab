import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import {
  MatchEntity,
  MatchParticipantEntity,
  ParticipantStatus,
  UserEntity,
} from '../database/entities';
import { CreateMatchDto } from './dto/create-match.dto';
import { InvitePlayersDto } from './dto/invite-players.dto';
import { JoinMatchDto } from './dto/join-match.dto';
import { NotificationsService } from '../notifications/notifications.service';
import { randomBytes } from 'crypto';

type MatchParticipantView = MatchParticipantEntity & {
  userName: string;
  userHandle: string;
};

type MatchView = MatchEntity & {
  hostName: string;
  hostHandle: string;
  participants: MatchParticipantView[];
};

@Injectable()
export class MatchesService {
  constructor(
    @InjectRepository(MatchEntity)
    private readonly matchesRepo: Repository<MatchEntity>,
    @InjectRepository(MatchParticipantEntity)
    private readonly participantsRepo: Repository<MatchParticipantEntity>,
    @InjectRepository(UserEntity)
    private readonly usersRepo: Repository<UserEntity>,
    private readonly notificationsService: NotificationsService,
  ) {}

  async list(
    area?: string,
    privateOnly?: boolean,
    userId?: string,
  ): Promise<MatchView[]> {
    const matches = await this.matchesRepo.find({
      where: {
        ...(area ? { area } : {}),
        ...(privateOnly ? { isPrivate: true } : {}),
      },
      order: { startsAt: 'ASC' },
      take: 80,
    });

    const participants = matches.length
      ? await this.participantsRepo.find({
          where: { matchId: In(matches.map((match) => match.id)) },
          order: { createdAt: 'ASC' },
        })
      : [];

    const userIds = new Set<string>();
    for (const match of matches) {
      userIds.add(match.hostId);
    }
    for (const participant of participants) {
      userIds.add(participant.userId);
    }

    const users = userIds.size
      ? await this.usersRepo.findBy({ id: In([...userIds]) })
      : [];
    const userById = new Map(users.map((user) => [user.id, user]));

    return matches
      .map((match) => {
        const matchParticipants = participants.filter(
          (row) => row.matchId === match.id,
        );
        if (!this.canUserSeeMatch(match, matchParticipants, userId)) {
          return null;
        }

        return this.toMatchView(match, matchParticipants, userById);
      })
      .filter((match): match is MatchView => match !== null);
  }

  async details(matchId: string): Promise<{
    match: MatchView;
  }> {
    const match = await this.matchesRepo.findOne({ where: { id: matchId } });
    if (!match) {
      throw new NotFoundException('Match not found');
    }

    const participants = await this.participantsRepo.find({
      where: { matchId },
      order: { createdAt: 'ASC' },
    });

    const users = await this.usersRepo.findBy({
      id: In([match.hostId, ...participants.map((row) => row.userId)]),
    });

    return {
      match: this.toMatchView(
        match,
        participants,
        new Map(users.map((user) => [user.id, user])),
      ),
    };
  }

  async create(dto: CreateMatchDto): Promise<MatchEntity> {
    const host = await this.usersRepo.findOne({ where: { id: dto.hostId } });
    if (!host) {
      throw new BadRequestException('Host user not found');
    }

    const skillMin = Math.min(dto.skillMin ?? 1, dto.skillMax ?? 10);
    const skillMax = Math.max(dto.skillMin ?? 1, dto.skillMax ?? 10);
    const inviteCode = dto.isPrivate ? this.buildInviteCode() : null;

    const match = this.matchesRepo.create({
      hostId: dto.hostId,
      title: dto.title.trim(),
      area: dto.area.trim(),
      courtName: dto.courtName.trim(),
      startsAt: new Date(dto.startsAt),
      isPrivate: dto.isPrivate ?? false,
      maxPlayers: dto.maxPlayers ?? 4,
      joinedPlayers: 1,
      skillMin,
      skillMax,
      inviteCode,
      inviteLink: inviteCode
        ? `https://padelconnect.app/join?m=temp&code=${inviteCode}`
        : null,
      status: 'open',
      targetScope: dto.targetScope ?? (dto.isPrivate ? 'friends' : 'public'),
    });

    const created = await this.matchesRepo.save(match);

    if (created.inviteCode) {
      created.inviteLink = `https://padelconnect.app/join?m=${created.id}&code=${created.inviteCode}`;
      await this.matchesRepo.save(created);
    }

    await this.participantsRepo.save(
      this.participantsRepo.create({
        matchId: created.id,
        userId: dto.hostId,
        status: ParticipantStatus.Accepted,
      }),
    );

    if (dto.inviteUserIds?.length) {
      await this.invite(created.id, {
        hostId: dto.hostId,
        targetUserIds: dto.inviteUserIds,
      });
    }

    return created;
  }

  async invite(
    matchId: string,
    dto: InvitePlayersDto,
  ): Promise<{ invited: number }> {
    const match = await this.matchesRepo.findOne({ where: { id: matchId } });
    if (!match) {
      throw new NotFoundException('Match not found');
    }
    if (match.hostId !== dto.hostId) {
      throw new BadRequestException('Only host can invite players');
    }

    const users = await this.usersRepo.findBy({ id: In(dto.targetUserIds) });
    if (!users.length) {
      return { invited: 0 };
    }

    let invited = 0;
    for (const user of users) {
      if (user.id === match.hostId) {
        continue;
      }

      const existing = await this.participantsRepo.findOne({
        where: { matchId, userId: user.id },
      });

      if (!existing) {
        await this.participantsRepo.save(
          this.participantsRepo.create({
            matchId,
            userId: user.id,
            status: ParticipantStatus.Invited,
          }),
        );
        invited += 1;

        await this.notificationsService.create({
          userId: user.id,
          type: 'invitation',
          title: 'New match invite',
          body: `${match.title} • ${match.area}`,
          matchId,
        });
      }
    }

    return { invited };
  }

  async join(
    matchId: string,
    dto: JoinMatchDto,
  ): Promise<{ status: ParticipantStatus }> {
    const match = await this.matchesRepo.findOne({ where: { id: matchId } });
    if (!match) {
      throw new NotFoundException('Match not found');
    }

    const existing = await this.participantsRepo.findOne({
      where: { matchId, userId: dto.userId },
    });

    if (match.isPrivate && !existing) {
      const inviteCode = dto.inviteCode?.trim().toUpperCase();
      if (!inviteCode || !match.inviteCode || inviteCode !== match.inviteCode) {
        throw new BadRequestException('Invalid invite code');
      }
    }

    const user = await this.usersRepo.findOne({ where: { id: dto.userId } });
    if (!user) {
      throw new BadRequestException('User not found');
    }

    if (existing && existing.status === ParticipantStatus.Accepted) {
      return { status: existing.status };
    }
    if (
      existing &&
      [
        ParticipantStatus.Pending,
        ParticipantStatus.OnHold,
        ParticipantStatus.Full,
      ].includes(existing.status)
    ) {
      return { status: existing.status };
    }

    const hasSpot = match.joinedPlayers < match.maxPlayers;
    const nextStatus = !hasSpot
      ? ParticipantStatus.Full
      : match.targetScope === 'public'
        ? ParticipantStatus.Pending
        : ParticipantStatus.Accepted;

    if (!existing) {
      await this.participantsRepo.save(
        this.participantsRepo.create({
          matchId,
          userId: dto.userId,
          status: nextStatus,
        }),
      );
    } else {
      existing.status = nextStatus;
      await this.participantsRepo.save(existing);
    }

    if (nextStatus === ParticipantStatus.Accepted) {
      match.joinedPlayers += 1;
      if (match.joinedPlayers >= match.maxPlayers) {
        match.status = 'full';
      }
      await this.matchesRepo.save(match);
    }

    await this.notificationsService.create({
      userId: match.hostId,
      type: 'join_request',
      title:
        nextStatus === ParticipantStatus.Pending
          ? 'New join request'
          : nextStatus === ParticipantStatus.Full
            ? 'Game full'
            : 'Player joined',
      body: `${user.name} for ${match.title}`,
      matchId,
    });

    return { status: nextStatus };
  }

  async leave(matchId: string, dto: JoinMatchDto): Promise<{ ok: true }> {
    const match = await this.matchesRepo.findOne({ where: { id: matchId } });
    if (!match) {
      throw new NotFoundException('Match not found');
    }

    const participant = await this.participantsRepo.findOne({
      where: { matchId, userId: dto.userId },
    });
    if (!participant) {
      throw new NotFoundException('Participant not found');
    }

    if (
      participant.status === ParticipantStatus.Accepted &&
      match.joinedPlayers > 0
    ) {
      match.joinedPlayers -= 1;
      match.status = 'open';
      await this.matchesRepo.save(match);
    }

    participant.status = ParticipantStatus.Left;
    await this.participantsRepo.save(participant);

    return { ok: true };
  }

  async updatePrivacy(
    matchId: string,
    dto: {
      hostId: string;
      isPrivate: boolean;
      targetScope?: 'public' | 'friends' | 'circle' | 'selected';
      inviteUserIds?: string[];
    },
  ): Promise<MatchEntity> {
    const match = await this.matchesRepo.findOne({ where: { id: matchId } });
    if (!match) {
      throw new NotFoundException('Match not found');
    }
    if (match.hostId !== dto.hostId) {
      throw new BadRequestException('Only host can update this match');
    }

    match.isPrivate = dto.isPrivate;
    match.targetScope =
      dto.targetScope ?? (dto.isPrivate ? 'friends' : 'public');

    if (dto.isPrivate && !match.inviteCode) {
      match.inviteCode = this.buildInviteCode();
    }
    match.inviteLink = match.inviteCode
      ? `https://padelconnect.app/join?m=${match.id}&code=${match.inviteCode}`
      : null;

    const saved = await this.matchesRepo.save(match);

    if (dto.isPrivate && dto.inviteUserIds?.length) {
      await this.invite(matchId, {
        hostId: dto.hostId,
        targetUserIds: dto.inviteUserIds,
      });
    }

    return saved;
  }

  async deleteMatch(matchId: string, hostId: string): Promise<{ ok: true }> {
    const match = await this.matchesRepo.findOne({ where: { id: matchId } });
    if (!match) {
      throw new NotFoundException('Match not found');
    }
    if (match.hostId !== hostId) {
      throw new BadRequestException('Only host can delete this match');
    }

    await this.participantsRepo.delete({ matchId });
    await this.matchesRepo.delete({ id: matchId });
    return { ok: true };
  }

  async approve(
    matchId: string,
    participantId: string,
    hostId: string,
  ): Promise<{ ok: true }> {
    const { match, participant } = await this.ensureModeration(
      matchId,
      participantId,
      hostId,
    );

    if (match.joinedPlayers >= match.maxPlayers) {
      participant.status = ParticipantStatus.Full;
      await this.participantsRepo.save(participant);
      return { ok: true };
    }

    participant.status = ParticipantStatus.Accepted;
    await this.participantsRepo.save(participant);

    match.joinedPlayers += 1;
    if (match.joinedPlayers >= match.maxPlayers) {
      match.status = 'full';
      await this.markPendingAsFull(match.id);
    }
    await this.matchesRepo.save(match);

    await this.notificationsService.create({
      userId: participant.userId,
      type: 'request_approved',
      title: 'Request approved',
      body: `${match.title} is confirmed for you`,
      matchId,
    });

    return { ok: true };
  }

  async reject(
    matchId: string,
    participantId: string,
    hostId: string,
  ): Promise<{ ok: true }> {
    const { match, participant } = await this.ensureModeration(
      matchId,
      participantId,
      hostId,
    );
    participant.status = ParticipantStatus.Rejected;
    await this.participantsRepo.save(participant);

    await this.notificationsService.create({
      userId: participant.userId,
      type: 'request_rejected',
      title: 'Request declined',
      body: `${match.title} was declined`,
      matchId,
    });

    return { ok: true };
  }

  async hold(
    matchId: string,
    participantId: string,
    hostId: string,
  ): Promise<{ ok: true }> {
    const { match, participant } = await this.ensureModeration(
      matchId,
      participantId,
      hostId,
    );
    participant.status = ParticipantStatus.OnHold;
    await this.participantsRepo.save(participant);

    await this.notificationsService.create({
      userId: participant.userId,
      type: 'request_hold',
      title: 'Request on hold',
      body: `${match.title} is on hold right now`,
      matchId,
    });

    return { ok: true };
  }

  private async ensureModeration(
    matchId: string,
    participantId: string,
    hostId: string,
  ) {
    const match = await this.matchesRepo.findOne({ where: { id: matchId } });
    if (!match) {
      throw new NotFoundException('Match not found');
    }
    if (match.hostId !== hostId) {
      throw new BadRequestException('Only host can moderate requests');
    }

    const participant = await this.participantsRepo.findOne({
      where: { id: participantId, matchId },
    });
    if (!participant) {
      throw new NotFoundException('Participant not found');
    }

    return { match, participant };
  }

  private async markPendingAsFull(matchId: string): Promise<void> {
    const rows = await this.participantsRepo.find({ where: { matchId } });
    for (const row of rows) {
      if (
        [
          ParticipantStatus.Pending,
          ParticipantStatus.OnHold,
          ParticipantStatus.Invited,
        ].includes(row.status)
      ) {
        row.status = ParticipantStatus.Full;
        await this.participantsRepo.save(row);
      }
    }
  }

  private buildInviteCode(): string {
    return randomBytes(4).toString('hex').toUpperCase().slice(0, 6);
  }

  private canUserSeeMatch(
    match: MatchEntity,
    participants: MatchParticipantEntity[],
    userId?: string,
  ): boolean {
    if (!match.isPrivate) {
      return true;
    }
    if (!userId) {
      return false;
    }
    if (match.hostId === userId) {
      return true;
    }

    return participants.some(
      (participant) =>
        participant.userId === userId &&
        participant.status !== ParticipantStatus.Rejected &&
        participant.status !== ParticipantStatus.Left,
    );
  }

  private toMatchView(
    match: MatchEntity,
    participants: MatchParticipantEntity[],
    userById: Map<string, UserEntity>,
  ): MatchView {
    const host = userById.get(match.hostId);

    return Object.assign(match, {
      hostName: host?.name ?? 'Host',
      hostHandle: host?.handle ?? 'host',
      participants: participants.map((participant) => {
        const user = userById.get(participant.userId);
        return Object.assign(participant, {
          userName: user?.name ?? 'Player',
          userHandle: user?.handle ?? 'player',
        });
      }),
    });
  }
}
