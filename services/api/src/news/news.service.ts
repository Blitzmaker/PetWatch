import { Injectable } from '@nestjs/common';
import { NewsReactionType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class NewsService {
  constructor(private readonly prisma: PrismaService) {}

  async setReaction(userId: string, newsPostId: string, reaction: NewsReactionType) {
    await this.prisma.newsReaction.upsert({
      where: { userId_newsPostId: { userId, newsPostId } },
      create: { userId, newsPostId, reaction },
      update: { reaction },
    });

    return this.getReactionSummary(userId, newsPostId);
  }

  async getReactions(userId: string, newsPostIds: string[]) {
    const uniquePostIds = [...new Set(newsPostIds.map((id) => id.trim()).filter((id) => id.length > 0))];
    if (!uniquePostIds.length) {
      return [];
    }

    const reactions = await this.prisma.newsReaction.groupBy({
      by: ['newsPostId', 'reaction'],
      where: { newsPostId: { in: uniquePostIds } },
      _count: { _all: true },
    });

    const ownReactions = await this.prisma.newsReaction.findMany({
      where: { userId, newsPostId: { in: uniquePostIds } },
      select: { newsPostId: true, reaction: true },
    });

    const ownByPostId = new Map(ownReactions.map((entry) => [entry.newsPostId, entry.reaction] as const));

    return uniquePostIds.map((postId) => this.mapSummary(postId, reactions, ownByPostId.get(postId) ?? null));
  }

  private async getReactionSummary(userId: string, newsPostId: string) {
    const grouped = await this.prisma.newsReaction.groupBy({
      by: ['newsPostId', 'reaction'],
      where: { newsPostId },
      _count: { _all: true },
    });

    const ownReaction = await this.prisma.newsReaction.findUnique({
      where: { userId_newsPostId: { userId, newsPostId } },
      select: { reaction: true },
    });

    return this.mapSummary(newsPostId, grouped, ownReaction?.reaction ?? null);
  }

  private mapSummary(
    newsPostId: string,
    grouped: Array<{ newsPostId: string; reaction: NewsReactionType; _count: { _all: number } }>,
    ownReaction: NewsReactionType | null,
  ) {
    const counts: Record<NewsReactionType, number> = {
      LIKE: 0,
      LOVE: 0,
      LAUGH: 0,
      WOW: 0,
      SAD: 0,
    };

    for (const entry of grouped) {
      if (entry.newsPostId === newsPostId) {
        counts[entry.reaction] = entry._count._all;
      }
    }

    return {
      newsPostId,
      ownReaction,
      counts,
      total: Object.values(counts).reduce((sum, next) => sum + next, 0),
    };
  }
}
