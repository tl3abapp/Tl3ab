import { Body, Controller, Delete, Get, Param, Post } from '@nestjs/common';
import { CreatePostDto } from './dto/create-post.dto';
import { PostsService } from './posts.service';

@Controller('posts')
export class PostsController {
  constructor(private readonly postsService: PostsService) {}

  @Get()
  list() {
    return this.postsService.list();
  }

  @Post()
  create(@Body() dto: CreatePostDto) {
    return this.postsService.create(dto);
  }

  @Post(':id/like')
  like(@Param('id') id: string) {
    return this.postsService.like(id);
  }

  @Post(':id/comment')
  comment(@Param('id') id: string) {
    return this.postsService.comment(id);
  }

  @Delete(':id')
  deletePost(@Param('id') id: string, @Body('authorId') authorId: string) {
    return this.postsService.delete(id, authorId);
  }
}
