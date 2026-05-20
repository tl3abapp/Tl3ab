import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PostEntity, UserEntity } from '../database/entities';
import { CreatePostDto } from './dto/create-post.dto';

@Injectable()
export class PostsService {
  constructor(
    @InjectRepository(PostEntity)
    private readonly postsRepo: Repository<PostEntity>,
    @InjectRepository(UserEntity)
    private readonly usersRepo: Repository<UserEntity>,
  ) {}

  async list(): Promise<PostEntity[]> {
    return this.postsRepo.find({ order: { createdAt: 'DESC' }, take: 60 });
  }

  async create(dto: CreatePostDto): Promise<PostEntity> {
    const author = await this.usersRepo.findOne({
      where: { id: dto.authorId },
    });
    if (!author) {
      throw new BadRequestException('Author not found');
    }

    const post = this.postsRepo.create({
      authorId: dto.authorId,
      content: dto.content.trim(),
    });
    return this.postsRepo.save(post);
  }

  async like(postId: string): Promise<PostEntity> {
    const post = await this.postsRepo.findOne({ where: { id: postId } });
    if (!post) {
      throw new NotFoundException('Post not found');
    }
    post.likes += 1;
    return this.postsRepo.save(post);
  }

  async comment(postId: string): Promise<PostEntity> {
    const post = await this.postsRepo.findOne({ where: { id: postId } });
    if (!post) {
      throw new NotFoundException('Post not found');
    }
    post.comments += 1;
    return this.postsRepo.save(post);
  }

  async delete(postId: string, authorId: string): Promise<{ ok: true }> {
    const post = await this.postsRepo.findOne({ where: { id: postId } });
    if (!post) {
      throw new NotFoundException('Post not found');
    }
    if (post.authorId !== authorId) {
      throw new BadRequestException('Only the author can delete this post');
    }

    await this.postsRepo.remove(post);
    return { ok: true };
  }
}
