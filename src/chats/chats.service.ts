import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import {
  ChatMemberEntity,
  ChatMessageEntity,
  ChatThreadEntity,
  ChatThreadType,
  MatchEntity,
  MatchParticipantEntity,
  ParticipantStatus,
  UserEntity,
} from '../database/entities';

type ChatThreadView = ChatThreadEntity & {
  messages: ChatMessageEntity[];
  unreadCount: number;
};

@Injectable()
export class ChatsService {
  constructor(
    @InjectRepository(ChatThreadEntity)
    private readonly threadsRepo: Repository<ChatThreadEntity>,
    @InjectRepository(ChatMemberEntity)
    private readonly membersRepo: Repository<ChatMemberEntity>,
    @InjectRepository(ChatMessageEntity)
    private readonly messagesRepo: Repository<ChatMessageEntity>,
    @InjectRepository(UserEntity)
    private readonly usersRepo: Repository<UserEntity>,
    @InjectRepository(MatchEntity)
    private readonly matchesRepo: Repository<MatchEntity>,
    @InjectRepository(MatchParticipantEntity)
    private readonly participantsRepo: Repository<MatchParticipantEntity>,
  ) {}

  async listForUser(userId: string): Promise<ChatThreadView[]> {
    await this.ensureUser(userId);
    const memberships = await this.membersRepo.find({ where: { userId } });
    if (!memberships.length) {
      return [];
    }

    const rawThreads = await this.threadsRepo.find({
      where: { id: In(memberships.map((entry) => entry.threadId)) },
      order: { updatedAt: 'DESC' },
    });

    const threads: ChatThreadEntity[] = [];
    for (const thread of rawThreads) {
      if (thread.type === ChatThreadType.Match && thread.matchId) {
        try {
          const match = await this.matchesRepo.findOne({
            where: { id: thread.matchId },
          });
          if (!match) {
            continue;
          }
          await this.ensureCanAccessMatchChat(match, userId);
        } catch (_) {
          continue;
        }
      }
      threads.push(thread);
    }

    if (!threads.length) {
      return [];
    }

    const messages = await this.messagesRepo.find({
      where: { threadId: In(threads.map((thread) => thread.id)) },
      order: { createdAt: 'ASC' },
    });

    const views: ChatThreadView[] = [];
    for (const thread of threads) {
      views.push(
        Object.assign(thread, {
          title: await this.titleForUser(thread, userId),
          messages: this.threadMessages(thread, messages),
          unreadCount: 0,
        }),
      );
    }
    return views;
  }

  async ensureDirectThread(
    userId: string,
    targetUserId: string,
  ): Promise<ChatThreadView> {
    if (userId === targetUserId) {
      throw new BadRequestException('Cannot chat with yourself');
    }

    const [user, target] = await Promise.all([
      this.ensureUser(userId),
      this.ensureUser(targetUserId),
    ]);

    const userMemberships = await this.membersRepo.find({ where: { userId } });
    const directThreads = userMemberships.length
      ? await this.threadsRepo.find({
          where: {
            id: In(userMemberships.map((entry) => entry.threadId)),
            type: ChatThreadType.Direct,
          },
        })
      : [];

    for (const thread of directThreads) {
      const targetMembership = await this.membersRepo.findOne({
        where: { threadId: thread.id, userId: targetUserId },
      });
      if (targetMembership) {
        return this.threadView(thread.id, userId);
      }
    }

    const thread = await this.threadsRepo.save(
      this.threadsRepo.create({
        type: ChatThreadType.Direct,
        title: target.name,
        matchId: null,
      }),
    );
    await this.membersRepo.save(
      this.membersRepo.create([
        { threadId: thread.id, userId: user.id },
        { threadId: thread.id, userId: target.id },
      ]),
    );
    return this.threadView(thread.id, userId);
  }

  async ensureMatchThread(
    matchId: string,
    userId: string,
  ): Promise<ChatThreadView> {
    const match = await this.matchesRepo.findOne({ where: { id: matchId } });
    if (!match) {
      throw new NotFoundException('Match not found');
    }

    await this.ensureCanAccessMatchChat(match, userId);

    let thread = await this.threadsRepo.findOne({
      where: { matchId, type: ChatThreadType.Match },
    });
    if (!thread) {
      thread = await this.threadsRepo.save(
        this.threadsRepo.create({
          type: ChatThreadType.Match,
          title: match.title,
          matchId,
        }),
      );
    }

    await this.syncMatchMembers(thread.id, match);
    return this.threadView(thread.id, userId);
  }

  async sendMessage(
    threadId: string,
    userId: string,
    text: string,
  ): Promise<ChatMessageEntity> {
    const cleanText = text.trim();
    if (!cleanText) {
      throw new BadRequestException('Message is empty');
    }

    const thread = await this.threadsRepo.findOne({ where: { id: threadId } });
    if (!thread) {
      throw new NotFoundException('Chat thread not found');
    }

    if (thread.type === ChatThreadType.Match && thread.matchId) {
      const match = await this.matchesRepo.findOne({
        where: { id: thread.matchId },
      });
      if (!match) {
        throw new NotFoundException('Match not found');
      }
      await this.ensureCanAccessMatchChat(match, userId);
    }

    const member = await this.membersRepo.findOne({
      where: { threadId, userId },
    });
    if (!member) {
      throw new ForbiddenException('Not a member of this chat');
    }

    const user = await this.ensureUser(userId);
    const message = await this.messagesRepo.save(
      this.messagesRepo.create({
        threadId,
        userId,
        senderName: user.name,
        text: cleanText,
      }),
    );
    thread.updatedAt = new Date();
    await this.threadsRepo.save(thread);
    return message;
  }

  private async threadView(
    threadId: string,
    userId: string,
  ): Promise<ChatThreadView> {
    const thread = await this.threadsRepo.findOne({ where: { id: threadId } });
    if (!thread) {
      throw new NotFoundException('Chat thread not found');
    }
    const messages = await this.messagesRepo.find({
      where: { threadId },
      order: { createdAt: 'ASC' },
      take: 80,
    });
    return Object.assign(thread, {
      title: await this.titleForUser(thread, userId),
      messages,
      unreadCount: 0,
    });
  }

  private async ensureUser(userId: string): Promise<UserEntity> {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user || user.accountStatus !== 'active') {
      throw new NotFoundException('User not found');
    }
    return user;
  }

  private async titleForUser(
    thread: ChatThreadEntity,
    userId: string,
  ): Promise<string> {
    if (thread.type !== ChatThreadType.Direct) {
      return thread.title;
    }

    const members = await this.membersRepo.find({
      where: { threadId: thread.id },
    });
    const otherMember = members.find((member) => member.userId !== userId);
    if (!otherMember) {
      return thread.title;
    }
    const otherUser = await this.usersRepo.findOne({
      where: { id: otherMember.userId },
    });
    return otherUser?.name ?? thread.title;
  }

  private threadMessages(
    thread: ChatThreadEntity,
    messages: ChatMessageEntity[],
  ): ChatMessageEntity[] {
    return messages
      .filter((message) => message.threadId === thread.id)
      .slice(-40);
  }

  private async ensureCanAccessMatchChat(
    match: MatchEntity,
    userId: string,
  ): Promise<void> {
    if (match.hostId === userId) {
      return;
    }
    const participant = await this.participantsRepo.findOne({
      where: { matchId: match.id, userId },
    });
    if (!participant || participant.status !== ParticipantStatus.Accepted) {
      throw new ForbiddenException('Join the game before opening chat');
    }
  }

  private async syncMatchMembers(
    threadId: string,
    match: MatchEntity,
  ): Promise<void> {
    const participants = await this.participantsRepo.find({
      where: { matchId: match.id, status: ParticipantStatus.Accepted },
    });
    const userIds = new Set([
      match.hostId,
      ...participants.map((entry) => entry.userId),
    ]);

    for (const userId of userIds) {
      const existing = await this.membersRepo.findOne({
        where: { threadId, userId },
      });
      if (!existing) {
        await this.membersRepo.save(
          this.membersRepo.create({ threadId, userId }),
        );
      }
    }
  }
}
