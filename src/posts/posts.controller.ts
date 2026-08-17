import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Param,
  Post,
} from '@nestjs/common';
import { CurrentUserId } from '../auth/current-user.decorator';
import { CreatePostDto } from './dto/create-post.dto';
import { PostsService } from './posts.service';

@Controller('posts')
export class PostsController {
  constructor(private readonly postsService: PostsService) {}

  @Get()
  list(@CurrentUserId() currentUserId: string) {
    return this.postsService.list(currentUserId);
  }

  @Post()
  create(@Body() dto: CreatePostDto, @CurrentUserId() currentUserId: string) {
    this.ensureSelf(dto.authorId, currentUserId);
    return this.postsService.create(dto);
  }

  @Post(':id/like')
  like(@Param('id') id: string, @CurrentUserId() currentUserId: string) {
    return this.postsService.like(id, currentUserId);
  }

  @Post(':id/comment')
  comment(@Param('id') id: string) {
    return this.postsService.comment(id);
  }

  @Post(':id/report')
  report(
    @Param('id') id: string,
    @CurrentUserId() currentUserId: string,
    @Body('reason') reason?: string,
  ) {
    return this.postsService.report(id, currentUserId, reason);
  }

  @Post(':id/block-author')
  blockAuthor(@Param('id') id: string, @CurrentUserId() currentUserId: string) {
    return this.postsService.blockAuthor(id, currentUserId);
  }

  @Delete(':id')
  deletePost(
    @Param('id') id: string,
    @Body('authorId') authorId: string,
    @CurrentUserId() currentUserId: string,
  ) {
    this.ensureSelf(authorId, currentUserId);
    return this.postsService.delete(id, authorId);
  }

  private ensureSelf(id: string, currentUserId: string): void {
    if (id !== currentUserId) {
      throw new ForbiddenException('Cannot act as another user');
    }
  }
}
