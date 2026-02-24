import { Body, Controller, Delete, Get, HttpCode, Param, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CreateMealDto } from './dto/create-meal.dto';
import { MealsService } from './meals.service';

@UseGuards(JwtAuthGuard)
@Controller()
export class MealsController {
  constructor(private readonly mealsService: MealsService) {}

  @Get('dogs/:dogId/meals')
  findAll(@CurrentUser('sub') userId: string, @Param('dogId') dogId: string) {
    return this.mealsService.findAll(userId, dogId);
  }

  @Post('dogs/:dogId/meals')
  create(@CurrentUser('sub') userId: string, @Param('dogId') dogId: string, @Body() dto: CreateMealDto) {
    return this.mealsService.create(userId, dogId, dto);
  }

  @Get('meals/:id')
  findOne(@CurrentUser('sub') userId: string, @Param('id') id: string) {
    return this.mealsService.findOne(userId, id);
  }

  @Delete('meals/:id')
  @HttpCode(204)
  async remove(@CurrentUser('sub') userId: string, @Param('id') id: string) {
    await this.mealsService.remove(userId, id);
  }
}
