import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { DogsService } from '../dogs/dogs.service';
import { CreateWeightDto } from './dto/create-weight.dto';

@Injectable()
export class WeightsService {
  constructor(private readonly prisma: PrismaService, private readonly dogsService: DogsService) {}

  async findAll(userId: string, dogId: string) {
    await this.dogsService.findOne(userId, dogId);
    return this.prisma.weightEntry.findMany({ where: { dogId }, orderBy: { date: 'desc' } });
  }

  async create(userId: string, dogId: string, dto: CreateWeightDto) {
    await this.dogsService.findOne(userId, dogId);
    return this.prisma.weightEntry.create({ data: { dogId, date: new Date(dto.date), weightKg: dto.weightKg } });
  }

  async remove(userId: string, id: string) {
    const entry = await this.prisma.weightEntry.findUnique({ where: { id }, include: { dog: true } });
    if (!entry || entry.dog.userId !== userId) throw new NotFoundException('Weight entry not found');
    await this.prisma.weightEntry.delete({ where: { id } });
  }
}
