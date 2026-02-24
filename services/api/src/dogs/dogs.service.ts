import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateDogDto } from './dto/create-dog.dto';
import { UpdateDogDto } from './dto/update-dog.dto';

@Injectable()
export class DogsService {
  constructor(private readonly prisma: PrismaService) {}

  findAll(userId: string) {
    return this.prisma.dog.findMany({ where: { userId }, include: { weights: true, meals: true } });
  }

  create(userId: string, dto: CreateDogDto) {
    return this.prisma.dog.create({ data: { ...dto, birthdate: dto.birthdate ? new Date(dto.birthdate) : undefined, userId } });
  }

  async findOne(userId: string, id: string) {
    const dog = await this.prisma.dog.findFirst({ where: { id, userId }, include: { weights: true, meals: { include: { entries: true } } } });
    if (!dog) throw new NotFoundException('Dog not found');
    return dog;
  }

  async update(userId: string, id: string, dto: UpdateDogDto) {
    await this.findOne(userId, id);
    return this.prisma.dog.update({ where: { id }, data: { ...dto, birthdate: dto.birthdate ? new Date(dto.birthdate) : undefined } });
  }
}
