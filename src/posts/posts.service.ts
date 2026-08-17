import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  PostEntity,
  PostLikeEntity,
  PostReportEntity,
  UserBlockEntity,
  UserEntity,
} from '../database/entities';
import { CreatePostDto } from './dto/create-post.dto';

@Injectable()
export class PostsService {
  constructor(
    @InjectRepository(PostEntity)
    private readonly postsRepo: Repository<PostEntity>,
    @InjectRepository(PostLikeEntity)
    private readonly postLikesRepo: Repository<PostLikeEntity>,
    @InjectRepository(PostReportEntity)
    private readonly postReportsRepo: Repository<PostReportEntity>,
    @InjectRepository(UserBlockEntity)
    private readonly userBlocksRepo: Repository<UserBlockEntity>,
    @InjectRepository(UserEntity)
    private readonly usersRepo: Repository<UserEntity>,
  ) {}

  async list(currentUserId?: string): Promise<PostEntity[]> {
    const posts = await this.postsRepo.find({
      order: { createdAt: 'DESC' },
      take: 80,
    });
    if (!currentUserId) {
      return posts.slice(0, 60);
    }

    const blockedRows = await this.userBlocksRepo.find({
      where: { blockerId: currentUserId },
    });
    const blockedIds = new Set(blockedRows.map((row) => row.blockedUserId));
    return posts.filter((post) => !blockedIds.has(post.authorId)).slice(0, 60);
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

  async like(postId: string, userId: string): Promise<PostEntity> {
    const post = await this.postsRepo.findOne({ where: { id: postId } });
    if (!post) {
      throw new NotFoundException('Post not found');
    }

    const existing = await this.postLikesRepo.findOne({
      where: { postId, userId },
    });

    if (existing) {
      await this.postLikesRepo.remove(existing);
      post.likes = Math.max(0, post.likes - 1);
    } else {
      await this.postLikesRepo.save(
        this.postLikesRepo.create({ postId, userId }),
      );
      post.likes += 1;
    }

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

  async report(
    postId: string,
    reporterId: string,
    reason?: string,
  ): Promise<{ ok: true }> {
    const post = await this.postsRepo.findOne({ where: { id: postId } });
    if (!post) {
      throw new NotFoundException('Post not found');
    }
    if (post.authorId === reporterId) {
      throw new BadRequestException('You cannot report your own post');
    }

    const existing = await this.postReportsRepo.findOne({
      where: { postId, reporterId },
    });
    if (existing) {
      existing.reason = reason?.trim() || existing.reason;
      await this.postReportsRepo.save(existing);
      return { ok: true };
    }

    await this.postReportsRepo.save(
      this.postReportsRepo.create({
        postId,
        reporterId,
        reason: reason?.trim() || null,
      }),
    );
    return { ok: true };
  }

  async blockAuthor(
    postId: string,
    blockerId: string,
  ): Promise<{ ok: true; blockedUserId: string }> {
    const post = await this.postsRepo.findOne({ where: { id: postId } });
    if (!post) {
      throw new NotFoundException('Post not found');
    }
    if (post.authorId === blockerId) {
      throw new BadRequestException('You cannot block yourself');
    }

    const existing = await this.userBlocksRepo.findOne({
      where: { blockerId, blockedUserId: post.authorId },
    });
    if (!existing) {
      await this.userBlocksRepo.save(
        this.userBlocksRepo.create({
          blockerId,
          blockedUserId: post.authorId,
        }),
      );
    }

    return { ok: true, blockedUserId: post.authorId };
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
