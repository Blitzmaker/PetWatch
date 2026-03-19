import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { FoodStatus, MealType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateRecipeDto, CreateRecipeItemDto, CreateRecipeStepDto } from './dto/create-recipe.dto';
import { UpdateRecipeDto } from './dto/update-recipe.dto';
import { RecipeTrackingMode, TrackRecipeMealDto } from './dto/track-recipe-meal.dto';

@Injectable()
export class RecipesService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(userId: string) {
    const recipes = await this.prisma.recipe.findMany({
      where: { createdByUserId: userId },
      include: this.recipeInclude(),
      orderBy: [{ updatedAt: 'desc' }],
    });
    return recipes.map((recipe) => this.serializeRecipe(recipe));
  }

  async create(userId: string, dto: CreateRecipeDto) {
    await this.ensureFoodsAccessible(userId, dto.items.map((item) => item.foodId));
    const recipe = await this.prisma.recipe.create({
      data: {
        createdByUserId: userId,
        title: dto.title.trim(),
        description: dto.description?.trim() || null,
        notes: dto.notes?.trim() || null,
        defaultPortions: dto.defaultPortions,
        yieldTotalGrams: dto.yieldTotalGrams,
        items: {
          create: this.mapRecipeItems(dto.items),
        },
        steps: dto.steps?.length ? { create: this.mapRecipeSteps(dto.steps) } : undefined,
      },
      include: this.recipeInclude(),
    });

    return this.serializeRecipe(recipe);
  }

  async findOne(userId: string, recipeId: string) {
    const recipe = await this.prisma.recipe.findFirst({
      where: { id: recipeId, createdByUserId: userId },
      include: this.recipeInclude(),
    });
    if (!recipe) throw new NotFoundException('Recipe not found');
    return this.serializeRecipe(recipe);
  }

  async update(userId: string, recipeId: string, dto: UpdateRecipeDto) {
    await this.ensureOwnRecipe(userId, recipeId);
    if (dto.items?.length) {
      await this.ensureFoodsAccessible(userId, dto.items.map((item) => item.foodId));
    }

    const recipe = await this.prisma.$transaction(async (tx) => {
      await tx.recipe.update({
        where: { id: recipeId },
        data: {
          title: dto.title?.trim(),
          description: dto.description !== undefined ? dto.description?.trim() || null : undefined,
          notes: dto.notes !== undefined ? dto.notes?.trim() || null : undefined,
          defaultPortions: dto.defaultPortions,
          yieldTotalGrams: dto.yieldTotalGrams,
        },
      });

      if (dto.items) {
        await tx.recipeItem.deleteMany({ where: { recipeId } });
        await tx.recipeItem.createMany({
          data: this.mapRecipeItems(dto.items).map((item) => ({ ...item, recipeId })),
        });
      }

      if (dto.steps) {
        await tx.recipeStep.deleteMany({ where: { recipeId } });
        if (dto.steps.length) {
          await tx.recipeStep.createMany({
            data: this.mapRecipeSteps(dto.steps).map((step) => ({ ...step, recipeId })),
          });
        }
      }

      return tx.recipe.findUniqueOrThrow({ where: { id: recipeId }, include: this.recipeInclude() });
    });

    return this.serializeRecipe(recipe);
  }

  async remove(userId: string, recipeId: string) {
    await this.ensureOwnRecipe(userId, recipeId);
    await this.prisma.recipe.delete({ where: { id: recipeId } });
  }

  async trackMeal(userId: string, dogId: string, dto: TrackRecipeMealDto) {
    const recipe = await this.prisma.recipe.findFirst({
      where: { id: dto.recipeId, createdByUserId: userId },
      include: this.recipeInclude(),
    });
    if (!recipe) throw new NotFoundException('Recipe not found');

    const dog = await this.prisma.dog.findFirst({ where: { id: dogId, userId } });
    if (!dog) throw new NotFoundException('Dog not found');

    if (!recipe.items.length || recipe.yieldTotalGrams <= 0) {
      throw new BadRequestException('Recipe cannot be tracked without ingredients and total grams');
    }

    const gramsToTrack = dto.mode === RecipeTrackingMode.PORTIONS
      ? (dto.portions ?? 0) * (recipe.defaultPortions ? recipe.yieldTotalGrams / recipe.defaultPortions : 0)
      : dto.grams ?? 0;

    if (dto.mode === RecipeTrackingMode.PORTIONS && !recipe.defaultPortions) {
      throw new BadRequestException('Recipe has no default portions configured');
    }
    if (!gramsToTrack || gramsToTrack <= 0) {
      throw new BadRequestException('Tracked grams must be greater than zero');
    }

    const scale = gramsToTrack / recipe.yieldTotalGrams;
    const mealType = dto.mealType ?? MealType.DINNER;

    return this.prisma.$transaction(async (tx) => {
      const meal = await tx.meal.create({ data: { dogId, eatenAt: new Date(dto.eatenAt), note: dto.note } });
      await tx.mealEntry.createMany({
        data: recipe.items.map((item) => ({
          mealId: meal.id,
          foodId: item.foodId,
          grams: Number((item.grams * scale).toFixed(3)),
          mealType,
          sourceRecipeId: recipe.id,
          sourceRecipeTitleSnapshot: recipe.title,
        })),
      });
      const savedMeal = await tx.meal.findUniqueOrThrow({
        where: { id: meal.id },
        include: { entries: { include: { food: true } } },
      });
      return {
        ...savedMeal,
        recipeTracking: {
          recipeId: recipe.id,
          recipeTitle: recipe.title,
          mode: dto.mode,
          gramsTracked: gramsToTrack,
          portionsTracked: dto.mode === RecipeTrackingMode.PORTIONS ? dto.portions ?? null : recipe.defaultPortions ? gramsToTrack / (recipe.yieldTotalGrams / recipe.defaultPortions) : null,
        },
      };
    });
  }

  private recipeInclude() {
    return {
      items: { include: { food: true }, orderBy: { sortOrder: 'asc' as const } },
      steps: { orderBy: { sortOrder: 'asc' as const } },
    };
  }

  private serializeRecipe(recipe: any) {
    const nutrition = this.calculateNutrition(recipe.items ?? [], recipe.yieldTotalGrams);
    return { ...recipe, nutrition, gramsPerPortion: recipe.defaultPortions ? recipe.yieldTotalGrams / recipe.defaultPortions : null };
  }

  private calculateNutrition(items: Array<{ grams: number; food: any }>, totalGrams: number) {
    let kcalTotal = 0;
    let proteinTotal = 0;
    let fatTotal = 0;
    let crudeAshTotal = 0;
    let crudeFiberTotal = 0;

    for (const item of items) {
      const factor = item.grams / 100;
      kcalTotal += factor * (item.food?.kcalPer100g ?? 0);
      proteinTotal += factor * (item.food?.proteinPercent ?? 0);
      fatTotal += factor * (item.food?.fatPercent ?? 0);
      crudeAshTotal += factor * (item.food?.crudeAshPercent ?? 0);
      crudeFiberTotal += factor * (item.food?.crudeFiberPercent ?? 0);
    }

    const perHundredFactor = totalGrams > 0 ? 100 / totalGrams : 0;
    return {
      kcalTotal,
      proteinTotal,
      fatTotal,
      crudeAshTotal,
      crudeFiberTotal,
      kcalPer100g: kcalTotal * perHundredFactor,
      proteinPer100g: proteinTotal * perHundredFactor,
      fatPer100g: fatTotal * perHundredFactor,
      crudeAshPer100g: crudeAshTotal * perHundredFactor,
      crudeFiberPer100g: crudeFiberTotal * perHundredFactor,
    };
  }

  private async ensureOwnRecipe(userId: string, recipeId: string) {
    const recipe = await this.prisma.recipe.findFirst({ where: { id: recipeId, createdByUserId: userId }, select: { id: true } });
    if (!recipe) throw new NotFoundException('Recipe not found');
  }

  private async ensureFoodsAccessible(userId: string, foodIds: string[]) {
    const uniqueFoodIds = [...new Set(foodIds)];
    const count = await this.prisma.food.count({
      where: {
        id: { in: uniqueFoodIds },
        OR: [
          { status: FoodStatus.APPROVED_PUBLIC },
          { createdByUserId: userId, status: { in: [FoodStatus.DRAFT_LOCAL, FoodStatus.PENDING_REVIEW] } },
        ],
      },
    });
    if (count !== uniqueFoodIds.length) {
      throw new BadRequestException('One or more foods are not accessible');
    }
  }

  private mapRecipeItems(items: CreateRecipeItemDto[]) {
    return items.map((item, index) => ({ foodId: item.foodId, grams: item.grams, sortOrder: item.sortOrder ?? index }));
  }

  private mapRecipeSteps(steps: CreateRecipeStepDto[]) {
    return steps.map((step, index) => ({ title: step.title?.trim() || null, instruction: step.instruction.trim(), sortOrder: step.sortOrder ?? index }));
  }
}
