import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { CreateUserDto } from './dto/create-user.dto';
import { LoginUserDto } from './dto/login-user.dto';
import {
  FollowEntity,
  MatchEntity,
  MatchParticipantEntity,
  NotificationEntity,
  PostEntity,
  UserEntity,
} from '../database/entities';
import { hashPassword, verifyPassword } from '../common/password';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(UserEntity)
    private readonly usersRepo: Repository<UserEntity>,
    @InjectRepository(FollowEntity)
    private readonly followsRepo: Repository<FollowEntity>,
    @InjectRepository(MatchEntity)
    private readonly matchesRepo: Repository<MatchEntity>,
    @InjectRepository(MatchParticipantEntity)
    private readonly participantsRepo: Repository<MatchParticipantEntity>,
    @InjectRepository(PostEntity)
    private readonly postsRepo: Repository<PostEntity>,
    @InjectRepository(NotificationEntity)
    private readonly notificationsRepo: Repository<NotificationEntity>,
  ) {}

  async create(dto: CreateUserDto): Promise<UserEntity> {
    const handle = dto.handle.trim().toLowerCase();
    const email = dto.email.trim().toLowerCase();
    const phoneNumber = dto.phoneNumber.trim();
    const birthDate = new Date(dto.birthDate);

    if (Number.isNaN(birthDate.getTime())) {
      throw new BadRequestException('Invalid birth date');
    }

    const handleExists = await this.usersRepo.findOne({ where: { handle } });
    if (handleExists) {
      throw new BadRequestException('Handle already exists');
    }

    const emailExists = await this.usersRepo.findOne({ where: { email } });
    if (emailExists) {
      throw new BadRequestException('Email already exists');
    }

    const phoneExists = await this.usersRepo.findOne({
      where: { phoneNumber },
    });
    if (phoneExists) {
      throw new BadRequestException('Phone number already exists');
    }

    const user = this.usersRepo.create({
      name: dto.name.trim(),
      handle,
      email,
      phoneNumber,
      birthDate: birthDate.toISOString().slice(0, 10),
      photoData: dto.photoData?.trim() || null,
      passwordHash: hashPassword(dto.password),
      skillLevel: dto.skillLevel ?? 5,
      area: dto.area?.trim() ?? null,
      avatarColor: dto.avatarColor ?? '#0A6C4D',
      accountStatus: 'active',
      deactivatedAt: null,
      deleteScheduledAt: null,
    });
    const saved = await this.usersRepo.save(user);
    return this.findById(saved.id);
  }

  async findAll(): Promise<UserEntity[]> {
    const users = await this.usersRepo.find({ order: { createdAt: 'DESC' } });
    return this.filterActiveUsers(users);
  }

  async findById(id: string): Promise<UserEntity> {
    const user = await this.usersRepo.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (this.isDeletionExpired(user)) {
      await this.hardDeleteUserData(user.id);
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async login(dto: LoginUserDto): Promise<UserEntity> {
    const email = dto.email.trim().toLowerCase();
    const password = dto.password;

    const user = await this.usersRepo
      .createQueryBuilder('user')
      .addSelect('user.passwordHash')
      .where('user.email = :email', { email })
      .getOne();

    if (!user || !verifyPassword(password, user.passwordHash)) {
      throw new BadRequestException('Invalid email or password');
    }

    if (this.isDeletionExpired(user)) {
      await this.hardDeleteUserData(user.id);
      throw new BadRequestException('Account no longer exists');
    }

    return this.findById(user.id);
  }

  async updatePhoto(
    userId: string,
    photoData: string | null,
  ): Promise<UserEntity> {
    const user = await this.findById(userId);
    const cleanPhoto = photoData?.trim();
    user.photoData = cleanPhoto ? cleanPhoto : null;
    await this.usersRepo.save(user);
    return this.findById(userId);
  }

  async deactivate(userId: string, days: number): Promise<UserEntity> {
    const user = await this.findById(userId);
    const normalizedDays = Math.min(Math.max(days, 1), 90);
    const now = new Date();
    const deleteScheduledAt = new Date(
      now.getTime() + normalizedDays * 24 * 60 * 60 * 1000,
    );

    user.accountStatus = 'deactivated';
    user.deactivatedAt = now;
    user.deleteScheduledAt = deleteScheduledAt;
    await this.usersRepo.save(user);
    return this.findById(userId);
  }

  async reactivate(userId: string): Promise<UserEntity> {
    const user = await this.findById(userId);
    user.accountStatus = 'active';
    user.deactivatedAt = null;
    user.deleteScheduledAt = null;
    await this.usersRepo.save(user);
    return this.findById(userId);
  }

  async deleteAccount(userId: string): Promise<{ ok: true }> {
    await this.findById(userId);
    await this.hardDeleteUserData(userId);
    return { ok: true };
  }

  async follow(followerId: string, targetId: string): Promise<{ ok: true }> {
    if (followerId === targetId) {
      throw new BadRequestException('Cannot follow yourself');
    }

    const follower = await this.findById(followerId);
    const target = await this.findById(targetId);

    this.ensureActiveUser(follower, 'Follower account is not active');
    this.ensureActiveUser(target, 'Target account is not active');

    const exists = await this.followsRepo.findOne({
      where: { followerId, followingId: targetId },
    });
    if (!exists) {
      await this.followsRepo.save(
        this.followsRepo.create({ followerId, followingId: targetId }),
      );
    }
    return { ok: true };
  }

  async unfollow(followerId: string, targetId: string): Promise<{ ok: true }> {
    await this.followsRepo.delete({ followerId, followingId: targetId });
    return { ok: true };
  }

  async followers(userId: string): Promise<UserEntity[]> {
    await this.findById(userId);
    const rows = await this.followsRepo.find({
      where: { followingId: userId },
    });
    if (!rows.length) {
      return [];
    }
    const ids = rows.map((row) => row.followerId);
    const users = await this.usersRepo.findBy({ id: In(ids) });
    return this.filterActiveUsers(users);
  }

  async following(userId: string): Promise<UserEntity[]> {
    await this.findById(userId);
    const rows = await this.followsRepo.find({ where: { followerId: userId } });
    if (!rows.length) {
      return [];
    }
    const ids = rows.map((row) => row.followingId);
    const users = await this.usersRepo.findBy({ id: In(ids) });
    return this.filterActiveUsers(users);
  }

  private ensureActiveUser(user: UserEntity, message: string): void {
    if (user.accountStatus !== 'active') {
      throw new BadRequestException(message);
    }
  }

  private isDeletionExpired(user: UserEntity): boolean {
    if (user.accountStatus !== 'deactivated' || !user.deleteScheduledAt) {
      return false;
    }
    return user.deleteScheduledAt.getTime() <= Date.now();
  }

  private async filterActiveUsers(users: UserEntity[]): Promise<UserEntity[]> {
    const active: UserEntity[] = [];
    for (const user of users) {
      if (this.isDeletionExpired(user)) {
        await this.hardDeleteUserData(user.id);
        continue;
      }
      if (user.accountStatus === 'active') {
        active.push(user);
      }
    }
    return active;
  }

  private async hardDeleteUserData(userId: string): Promise<void> {
    const hostedMatches = await this.matchesRepo.find({
      select: { id: true },
      where: { hostId: userId },
    });
    const hostedMatchIds = hostedMatches.map((entry) => entry.id);

    if (hostedMatchIds.length) {
      await this.participantsRepo.delete({ matchId: In(hostedMatchIds) });
      await this.matchesRepo.delete({ id: In(hostedMatchIds) });
    }

    await this.followsRepo
      .createQueryBuilder()
      .delete()
      .where('followerId = :userId OR followingId = :userId', { userId })
      .execute();

    await this.participantsRepo.delete({ userId });
    await this.postsRepo.delete({ authorId: userId });
    await this.notificationsRepo.delete({ userId });
    await this.usersRepo.delete({ id: userId });
  }
}
