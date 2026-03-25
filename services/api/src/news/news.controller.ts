import { Body, Controller, Get, Param, Put, Query, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { SetNewsReactionDto } from './dto/set-news-reaction.dto';
import { NewsService } from './news.service';

@UseGuards(JwtAuthGuard)
@Controller('news')
export class NewsController {
  constructor(private readonly newsService: NewsService) {}

  @Get('reactions')
  getReactions(@CurrentUser('sub') userId: string, @Query('postIds') postIds?: string) {
    const parsedPostIds = (postIds ?? '')
      .split(',')
      .map((id) => id.trim())
      .filter((id) => id.length > 0);

    return this.newsService.getReactions(userId, parsedPostIds);
  }

  @Put(':postId/reaction')
  setReaction(@CurrentUser('sub') userId: string, @Param('postId') postId: string, @Body() dto: SetNewsReactionDto) {
    return this.newsService.setReaction(userId, postId, dto.reaction);
  }
}
