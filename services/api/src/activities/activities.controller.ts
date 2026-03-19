import { Body, Controller, Delete, Get, HttpCode, Param, Post, Query, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CreateActivityEntryDto } from './dto/create-activity-entry.dto';
import { ActivitiesService } from './activities.service';

@UseGuards(JwtAuthGuard)
@Controller()
export class ActivitiesController {
  constructor(private readonly activitiesService: ActivitiesService) {}

  @Get('activities/search')
  search(@Query('q') query?: string) {
    return this.activitiesService.search(query);
  }

  @Get('dogs/:dogId/activities')
  findAll(@CurrentUser('sub') userId: string, @Param('dogId') dogId: string) {
    return this.activitiesService.findAll(userId, dogId);
  }

  @Post('dogs/:dogId/activities')
  create(@CurrentUser('sub') userId: string, @Param('dogId') dogId: string, @Body() dto: CreateActivityEntryDto) {
    return this.activitiesService.create(userId, dogId, dto);
  }

  @Delete('activities/:id')
  @HttpCode(204)
  async remove(@CurrentUser('sub') userId: string, @Param('id') id: string) {
    await this.activitiesService.remove(userId, id);
  }
}
