import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotificationEntity } from '../database/entities';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(NotificationEntity)
    private readonly notificationsRepo: Repository<NotificationEntity>,
  ) {}

  async listForUser(userId: string): Promise<NotificationEntity[]> {
    return this.notificationsRepo.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: 100,
    });
  }

  async create(data: {
    userId: string;
    type: string;
    title: string;
    body: string;
    matchId?: string | null;
  }): Promise<NotificationEntity> {
    const notification = this.notificationsRepo.create({
      userId: data.userId,
      type: data.type,
      title: data.title,
      body: data.body,
      matchId: data.matchId ?? null,
    });
    return this.notificationsRepo.save(notification);
  }

  async markRead(id: string): Promise<NotificationEntity> {
    const notification = await this.notificationsRepo.findOne({
      where: { id },
    });
    if (!notification) {
      throw new NotFoundException('Notification not found');
    }
    notification.isRead = true;
    return this.notificationsRepo.save(notification);
  }
}
