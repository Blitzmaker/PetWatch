import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateFoodDto } from './dto/create-food.dto';

@Injectable()
export class FoodsService {
  constructor(private readonly prisma: PrismaService) {}

  async findByBarcode(barcode: string) {
    const food = await this.prisma.food.findUnique({ where: { barcode } });
    if (!food) throw new NotFoundException('Food not found');
    return food;
  }

  async create(userId: string, dto: CreateFoodDto) {
    try {
      return await this.prisma.food.create({ data: { ...dto, createdByUserId: userId } });
    } catch {
      throw new ConflictException('Barcode already exists');
    }
  }
}
