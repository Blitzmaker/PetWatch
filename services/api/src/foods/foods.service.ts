import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { FoodStatus } from '@prisma/client';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateFoodDto } from './dto/create-food.dto';

@Injectable()
export class FoodsService {
  constructor(private readonly prisma: PrismaService) {}

  async findByBarcode(barcode: string, userId: string) {
    const food = await this.prisma.food.findFirst({
      where: {
        barcode,
        OR: [
          { status: FoodStatus.APPROVED_PUBLIC },
          {
            createdByUserId: userId,
            status: { in: [FoodStatus.DRAFT_LOCAL, FoodStatus.PENDING_REVIEW] },
          },
        ],
      },
    });

    if (!food) throw new NotFoundException('Food not found');
    return food;
  }

  async search(rawQuery: string, userId: string) {
    const query = rawQuery.trim();
    if (!query) return [];

    return this.prisma.food.findMany({
      where: {
        OR: [
          { status: FoodStatus.APPROVED_PUBLIC },
          {
            createdByUserId: userId,
            status: { in: [FoodStatus.DRAFT_LOCAL, FoodStatus.PENDING_REVIEW] },
          },
        ],
        AND: [
          {
            OR: [
              { barcode: { contains: query, mode: 'insensitive' } },
              { name: { contains: query, mode: 'insensitive' } },
            ],
          },
        ],
      },
      orderBy: [{ name: 'asc' }],
      take: 6,
    });
  }

  async create(userId: string, dto: CreateFoodDto) {
    try {
      return await this.prisma.food.create({
        data: { ...dto, createdByUserId: userId, status: FoodStatus.PENDING_REVIEW },
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        throw new ConflictException('Barcode already exists');
      }
      throw error;
    }
  }
}
