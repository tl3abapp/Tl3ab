import {
  Controller,
  ForbiddenException,
  Get,
  Param,
  Post,
} from '@nestjs/common';
import { CurrentUserId } from '../auth/current-user.decorator';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get(':userId')
  list(
    @Param('userId') userId: string,
    @CurrentUserId() currentUserId: string,
  ) {
    this.ensureSelf(userId, currentUserId);
    return this.notificationsService.listForUser(userId);
  }

  @Post(':id/read')
  markRead(@Param('id') id: string, @CurrentUserId() currentUserId: string) {
    return this.notificationsService.markReadForUser(id, currentUserId);
  }

  private ensureSelf(id: string, currentUserId: string): void {
    if (id !== currentUserId) {
      throw new ForbiddenException('Cannot access another account');
    }
  }
}
