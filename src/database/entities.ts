import {
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  Column,
  type ColumnType,
  Unique,
  UpdateDateColumn,
} from 'typeorm';

const dateTimeColumnType: ColumnType =
  process.env.DB_DRIVER?.toLowerCase() === 'sqljs' || !process.env.DATABASE_URL
    ? 'datetime'
    : 'timestamptz';

export enum ParticipantStatus {
  Invited = 'invited',
  Pending = 'pending',
  Accepted = 'accepted',
  Rejected = 'rejected',
  OnHold = 'on_hold',
  Full = 'full',
  Left = 'left',
}

@Entity('users')
export class UserEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ unique: true, length: 32 })
  handle!: string;

  @Column({ length: 80 })
  name!: string;

  @Column({ unique: true, length: 120 })
  email!: string;

  @Column({ unique: true, length: 24 })
  phoneNumber!: string;

  @Column({ type: 'date' })
  birthDate!: string;

  @Column({ type: 'text', nullable: true })
  photoData!: string | null;

  @Column({ type: 'varchar', length: 255, select: false })
  passwordHash!: string;

  @Column({ type: 'int', default: 5 })
  skillLevel!: number;

  @Column({ type: 'varchar', length: 80, nullable: true })
  area!: string | null;

  @Column({ type: 'varchar', length: 16, default: '#0A6C4D' })
  avatarColor!: string;

  @Column({ type: 'varchar', length: 16, default: 'active' })
  accountStatus!: 'active' | 'deactivated';

  @Column({ type: dateTimeColumnType, nullable: true })
  deactivatedAt!: Date | null;

  @Column({ type: dateTimeColumnType, nullable: true })
  deleteScheduledAt!: Date | null;

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}

@Entity('follows')
@Unique(['followerId', 'followingId'])
export class FollowEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  followerId!: string;

  @Column({ type: 'uuid' })
  followingId!: string;

  @CreateDateColumn()
  createdAt!: Date;
}

@Entity('posts')
export class PostEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  authorId!: string;

  @Column({ type: 'text' })
  content!: string;

  @Column({ type: 'int', default: 0 })
  likes!: number;

  @Column({ type: 'int', default: 0 })
  comments!: number;

  @CreateDateColumn()
  createdAt!: Date;
}

@Entity('matches')
export class MatchEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  hostId!: string;

  @Column({ length: 120 })
  title!: string;

  @Column({ length: 80 })
  area!: string;

  @Column({ length: 120 })
  courtName!: string;

  @Column({ type: dateTimeColumnType })
  startsAt!: Date;

  @Column({ type: 'boolean', default: false })
  isPrivate!: boolean;

  @Column({ type: 'int', default: 4 })
  maxPlayers!: number;

  @Column({ type: 'int', default: 1 })
  joinedPlayers!: number;

  @Column({ type: 'int', default: 1 })
  skillMin!: number;

  @Column({ type: 'int', default: 10 })
  skillMax!: number;

  @Column({ type: 'varchar', length: 12, nullable: true })
  inviteCode!: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  inviteLink!: string | null;

  @Column({ type: 'varchar', length: 16, default: 'open' })
  status!: string;

  @Column({ type: 'varchar', length: 16, default: 'public' })
  targetScope!: 'public' | 'friends' | 'circle' | 'selected';

  @CreateDateColumn()
  createdAt!: Date;
}

@Entity('match_participants')
@Unique(['matchId', 'userId'])
export class MatchParticipantEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  matchId!: string;

  @Column({ type: 'uuid' })
  userId!: string;

  @Column({
    type: 'simple-enum',
    enum: ParticipantStatus,
    default: ParticipantStatus.Pending,
  })
  status!: ParticipantStatus;

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}

@Entity('notifications')
export class NotificationEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  userId!: string;

  @Column({ length: 32 })
  type!: string;

  @Column({ length: 120 })
  title!: string;

  @Column({ type: 'text' })
  body!: string;

  @Column({ type: 'uuid', nullable: true })
  matchId!: string | null;

  @Column({ type: 'boolean', default: false })
  isRead!: boolean;

  @CreateDateColumn()
  createdAt!: Date;
}

export const databaseEntities = [
  UserEntity,
  FollowEntity,
  PostEntity,
  MatchEntity,
  MatchParticipantEntity,
  NotificationEntity,
] as const;
