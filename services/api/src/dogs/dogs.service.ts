import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateDogDto } from './dto/create-dog.dto';
import { UpdateDogDto } from './dto/update-dog.dto';
import { calculateDogDailyKcal } from './dog-calorie.util';

@Injectable()
export class DogsService {
  constructor(private readonly prisma: PrismaService) {}

  findAll(userId: string) {
    return this.prisma.dog.findMany({ where: { userId }, include: { weights: true, meals: true } });
  }

  async create(userId: string, dto: CreateDogDto) {
    const dailyKcalTarget = dto.dailyKcalTarget ?? calculateDogDailyKcal(dto);

    return this.prisma.$transaction(async (tx) => {
      const dog = await tx.dog.create({
        data: {
          userId,
          name: dto.name,
          breed: dto.breed,
          birthdate: dto.birthdate ? new Date(dto.birthdate) : undefined,
          sex: dto.sex,
          targetWeightKg: dto.targetWeightKg,
          activityLevel: dto.activityLevel,
          isNeutered: dto.isNeutered ?? false,
          dailyKcalTarget,
        },
      });

      if (dto.currentWeightKg != null && dto.currentWeightKg > 0) {
        await tx.weightEntry.create({
          data: {
            dogId: dog.id,
            date: new Date(),
            weightKg: dto.currentWeightKg,
          },
        });
      }

      return dog;
    });
  }

  async findOne(userId: string, id: string) {
    const dog = await this.prisma.dog.findFirst({
      where: { id, userId },
      include: {
        weights: { orderBy: [{ date: 'desc' }, { createdAt: 'desc' }] },
        meals: { include: { entries: true } },
      },
    });
    if (!dog) throw new NotFoundException('Dog not found');
    return dog;
  }

  async update(userId: string, id: string, dto: UpdateDogDto) {
    const existingDog = await this.findOne(userId, id);

    const dailyKcalTarget = dto.dailyKcalTarget ?? existingDog.dailyKcalTarget ?? undefined;

    return this.prisma.dog.update({
      where: { id },
      data: {
        name: dto.name,
        breed: dto.breed,
        birthdate: dto.birthdate ? new Date(dto.birthdate) : undefined,
        sex: dto.sex,
        targetWeightKg: dto.targetWeightKg,
        activityLevel: dto.activityLevel,
        isNeutered: dto.isNeutered,
        dailyKcalTarget,
      },
    });
  }
}
