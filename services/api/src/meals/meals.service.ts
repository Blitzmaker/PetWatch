import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { DogsService } from '../dogs/dogs.service';
import { CreateMealDto } from './dto/create-meal.dto';

@Injectable()
export class MealsService {
  constructor(private readonly prisma: PrismaService, private readonly dogsService: DogsService) {}

  async findAll(userId: string, dogId: string) {
    await this.dogsService.findOne(userId, dogId);
    return this.prisma.meal.findMany({ where: { dogId }, include: { entries: { include: { food: true } } }, orderBy: { eatenAt: 'desc' } });
  }

  async create(userId: string, dogId: string, dto: CreateMealDto) {
    await this.dogsService.findOne(userId, dogId);
    return this.prisma.$transaction(async (tx) => {
      const meal = await tx.meal.create({ data: { dogId, eatenAt: new Date(dto.eatenAt), note: dto.note } });
      await tx.mealEntry.createMany({ data: dto.entries.map((entry) => ({ mealId: meal.id, foodId: entry.foodId, grams: entry.grams, mealType: entry.mealType ?? 'DINNER' })) });
      return tx.meal.findUniqueOrThrow({ where: { id: meal.id }, include: { entries: { include: { food: true } } } });
    });
  }

  async findOne(userId: string, id: string) {
    const meal = await this.prisma.meal.findUnique({ where: { id }, include: { dog: true, entries: { include: { food: true } } } });
    if (!meal || meal.dog.userId !== userId) throw new NotFoundException('Meal not found');
    return meal;
  }

  async remove(userId: string, id: string) {
    await this.findOne(userId, id);
    await this.prisma.meal.delete({ where: { id } });
  }
}
