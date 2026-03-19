import { Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CreateRecipeDto } from './dto/create-recipe.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';
import { TrackRecipeMealDto } from './dto/track-recipe-meal.dto';
import { RecipesService } from './recipes.service';

@UseGuards(JwtAuthGuard)
@Controller()
export class RecipesController {
  constructor(private readonly recipesService: RecipesService) {}

  @Get('recipes')
  findAll(@CurrentUser('sub') userId: string) {
    return this.recipesService.findAll(userId);
  }

  @Post('recipes')
  create(@CurrentUser('sub') userId: string, @Body() dto: CreateRecipeDto) {
    return this.recipesService.create(userId, dto);
  }

  @Get('recipes/:id')
  findOne(@CurrentUser('sub') userId: string, @Param('id') id: string) {
    return this.recipesService.findOne(userId, id);
  }

  @Patch('recipes/:id')
  update(@CurrentUser('sub') userId: string, @Param('id') id: string, @Body() dto: UpdateRecipeDto) {
    return this.recipesService.update(userId, id, dto);
  }

  @Delete('recipes/:id')
  @HttpCode(204)
  async remove(@CurrentUser('sub') userId: string, @Param('id') id: string) {
    await this.recipesService.remove(userId, id);
  }

  @Post('dogs/:dogId/meals/from-recipe')
  trackMeal(@CurrentUser('sub') userId: string, @Param('dogId') dogId: string, @Body() dto: TrackRecipeMealDto) {
    return this.recipesService.trackMeal(userId, dogId, dto);
  }
}
