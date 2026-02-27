import { Injectable, NotFoundException } from '@nestjs/common';
import { FoodStatus, PublicationStatus } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCmsCategoryDto } from './dto/create-cms-category.dto';
import { CreateCmsPostDto } from './dto/create-cms-post.dto';
import { CreateCommunityPostDto } from './dto/create-community-post.dto';
import { CreateCommunityThreadDto } from './dto/create-community-thread.dto';
import { CreateCommunityTopicDto } from './dto/create-community-topic.dto';
import { ReviewFoodDto } from './dto/review-food.dto';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  listUsers() {
    return this.prisma.user.findMany({
      orderBy: { createdAt: 'desc' },
      select: { id: true, email: true, role: true, isBlocked: true, deletedAt: true, createdAt: true, updatedAt: true },
    });
  }

  async updateUser(userId: string, dto: UpdateUserDto) {
    const existing = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!existing) throw new NotFoundException('User not found');

    const data: {
      role?: UpdateUserDto['role'];
      isBlocked?: boolean;
      passwordHash?: string;
    } = {};

    if (dto.role) data.role = dto.role;
    if (dto.isBlocked !== undefined) data.isBlocked = dto.isBlocked;
    if (dto.resetPassword) data.passwordHash = await bcrypt.hash(dto.resetPassword, 10);

    return this.prisma.user.update({
      where: { id: userId },
      data,
      select: { id: true, email: true, role: true, isBlocked: true, updatedAt: true },
    });
  }

  async softDeleteUser(userId: string) {
    const existing = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!existing) throw new NotFoundException('User not found');

    return this.prisma.user.update({ where: { id: userId }, data: { deletedAt: new Date() } });
  }

  listDogs() {
    return this.prisma.dog.findMany({
      orderBy: { createdAt: 'desc' },
      include: { user: { select: { id: true, email: true } } },
    });
  }

  listFoods(status?: FoodStatus) {
    return this.prisma.food.findMany({
      where: status ? { status } : undefined,
      orderBy: { createdAt: 'desc' },
      include: {
        createdBy: { select: { id: true, email: true } },
        reviewedBy: { select: { id: true, email: true } },
      },
    });
  }

  async reviewFood(foodId: string, adminId: string, dto: ReviewFoodDto) {
    const existing = await this.prisma.food.findUnique({ where: { id: foodId } });
    if (!existing) throw new NotFoundException('Food not found');

    return this.prisma.food.update({
      where: { id: foodId },
      data: {
        status: dto.status,
        reviewComment: dto.reviewComment,
        reviewedByAdminId: adminId,
        approvedAt: dto.status === FoodStatus.APPROVED_PUBLIC ? new Date() : null,
      },
    });
  }

  listCmsCategories() {
    return this.prisma.cmsCategory.findMany({ orderBy: { title: 'asc' } });
  }

  createCmsCategory(dto: CreateCmsCategoryDto) {
    return this.prisma.cmsCategory.create({ data: dto });
  }

  listCmsPosts() {
    return this.prisma.cmsPost.findMany({
      orderBy: { createdAt: 'desc' },
      include: { author: { select: { id: true, email: true } }, category: true },
    });
  }

  createCmsPost(authorId: string, dto: CreateCmsPostDto) {
    const shouldPublish = dto.status === PublicationStatus.PUBLISHED;

    return this.prisma.cmsPost.create({
      data: {
        title: dto.title,
        slug: dto.slug,
        teaser: dto.teaser,
        content: dto.content,
        status: dto.status,
        authorId,
        categoryId: dto.categoryId,
        publishedAt: shouldPublish ? new Date() : null,
      },
    });
  }

  listTopics() {
    return this.prisma.communityTopic.findMany({ orderBy: { createdAt: 'desc' } });
  }

  createTopic(dto: CreateCommunityTopicDto) {
    return this.prisma.communityTopic.create({ data: dto });
  }

  listThreads(topicId?: string) {
    return this.prisma.communityThread.findMany({
      where: topicId ? { topicId } : undefined,
      orderBy: { createdAt: 'desc' },
      include: {
        topic: true,
        author: { select: { id: true, email: true } },
        _count: { select: { posts: true } },
      },
    });
  }

  createThread(authorId: string, dto: CreateCommunityThreadDto) {
    return this.prisma.communityThread.create({
      data: {
        topicId: dto.topicId,
        authorId,
        title: dto.title,
        content: dto.content,
      },
    });
  }

  listThreadPosts(threadId: string) {
    return this.prisma.communityPost.findMany({
      where: { threadId },
      orderBy: { createdAt: 'asc' },
      include: { author: { select: { id: true, email: true } } },
    });
  }

  createThreadPost(authorId: string, dto: CreateCommunityPostDto) {
    return this.prisma.communityPost.create({
      data: {
        threadId: dto.threadId,
        authorId,
        content: dto.content,
      },
    });
  }
}
