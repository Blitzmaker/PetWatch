import { Body, Controller, Delete, Get, Param, ParseEnumPipe, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { FoodStatus, UserRole } from '@prisma/client';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AdminService } from './admin.service';
import { CreateCmsCategoryDto } from './dto/create-cms-category.dto';
import { CreateCmsPostDto } from './dto/create-cms-post.dto';
import { CreateCommunityPostDto } from './dto/create-community-post.dto';
import { CreateCommunityThreadDto } from './dto/create-community-thread.dto';
import { CreateCommunityTopicDto } from './dto/create-community-topic.dto';
import { ReviewFoodDto } from './dto/review-food.dto';
import { UpdateUserDto } from './dto/update-user.dto';

@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.MODERATOR)
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('users')
  @Roles(UserRole.MODERATOR)
  listUsers() {
    return this.adminService.listUsers();
  }

  @Patch('users/:id')
  @Roles(UserRole.ADMIN)
  updateUser(@Param('id') id: string, @Body() dto: UpdateUserDto) {
    return this.adminService.updateUser(id, dto);
  }

  @Delete('users/:id')
  @Roles(UserRole.ADMIN)
  softDeleteUser(@Param('id') id: string) {
    return this.adminService.softDeleteUser(id);
  }

  @Get('dogs')
  @Roles(UserRole.MODERATOR)
  listDogs() {
    return this.adminService.listDogs();
  }

  @Get('foods')
  @Roles(UserRole.FOOD_REVIEWER)
  listFoods(@Query('status', new ParseEnumPipe(FoodStatus, { optional: true })) status?: FoodStatus) {
    return this.adminService.listFoods(status);
  }

  @Patch('foods/:id/review')
  @Roles(UserRole.FOOD_REVIEWER)
  reviewFood(@Param('id') id: string, @CurrentUser('sub') adminId: string, @Body() dto: ReviewFoodDto) {
    return this.adminService.reviewFood(id, adminId, dto);
  }

  @Get('cms/categories')
  @Roles(UserRole.CURATOR)
  listCmsCategories() {
    return this.adminService.listCmsCategories();
  }

  @Post('cms/categories')
  @Roles(UserRole.CURATOR)
  createCmsCategory(@Body() dto: CreateCmsCategoryDto) {
    return this.adminService.createCmsCategory(dto);
  }

  @Get('cms/posts')
  @Roles(UserRole.CURATOR)
  listCmsPosts() {
    return this.adminService.listCmsPosts();
  }

  @Post('cms/posts')
  @Roles(UserRole.CURATOR)
  createCmsPost(@CurrentUser('sub') authorId: string, @Body() dto: CreateCmsPostDto) {
    return this.adminService.createCmsPost(authorId, dto);
  }

  @Get('community/topics')
  @Roles(UserRole.MODERATOR)
  listTopics() {
    return this.adminService.listTopics();
  }

  @Post('community/topics')
  @Roles(UserRole.MODERATOR)
  createTopic(@Body() dto: CreateCommunityTopicDto) {
    return this.adminService.createTopic(dto);
  }

  @Get('community/threads')
  @Roles(UserRole.MODERATOR)
  listThreads(@Query('topicId') topicId?: string) {
    return this.adminService.listThreads(topicId);
  }

  @Post('community/threads')
  @Roles(UserRole.MODERATOR)
  createThread(@CurrentUser('sub') authorId: string, @Body() dto: CreateCommunityThreadDto) {
    return this.adminService.createThread(authorId, dto);
  }

  @Get('community/threads/:threadId/posts')
  @Roles(UserRole.MODERATOR)
  listThreadPosts(@Param('threadId') threadId: string) {
    return this.adminService.listThreadPosts(threadId);
  }

  @Post('community/posts')
  @Roles(UserRole.MODERATOR)
  createThreadPost(@CurrentUser('sub') authorId: string, @Body() dto: CreateCommunityPostDto) {
    return this.adminService.createThreadPost(authorId, dto);
  }
}
