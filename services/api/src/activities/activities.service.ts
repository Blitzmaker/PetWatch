import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { DogsService } from '../dogs/dogs.service';
import { CreateActivityEntryDto } from './dto/create-activity-entry.dto';
import { calculateActivityKcalBurned } from './activity-calorie.util';

@Injectable()
export class ActivitiesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly dogsService: DogsService,
  ) {}

  async search(rawQuery?: string) {
    const query = rawQuery?.trim();

    return this.prisma.activity.findMany({
      where: query
        ? {
            name: { contains: query, mode: 'insensitive' },
          }
        : undefined,
      orderBy: [{ name: 'asc' }],
      take: 10,
    });
  }

  async findAll(userId: string, dogId: string) {
    await this.dogsService.findOne(userId, dogId);
    return this.prisma.activityEntry.findMany({
      where: { dogId },
      include: { activity: true },
      orderBy: { performedAt: 'desc' },
    });
  }

  async create(userId: string, dogId: string, dto: CreateActivityEntryDto) {
    const dog = await this.prisma.dog.findFirst({
      where: { id: dogId, userId },
      include: {
        weights: {
          orderBy: [{ date: 'desc' }, { createdAt: 'desc' }],
          take: 1,
        },
      },
    });
    if (!dog) throw new NotFoundException('Dog not found');

    const activity = await this.prisma.activity.findUnique({ where: { id: dto.activityId } });
    if (!activity) throw new NotFoundException('Activity not found');

    const latestWeight = dog.weights[0]?.weightKg ?? dog.targetWeightKg ?? 10;
    const calculation = calculateActivityKcalBurned(activity.kcalPerMinute, dto.durationMinutes, latestWeight);

    return this.prisma.activityEntry.create({
      data: {
        dogId,
        activityId: dto.activityId,
        durationMinutes: dto.durationMinutes,
        performedAt: new Date(dto.performedAt),
        kcalPerMinuteSnapshot: activity.kcalPerMinute,
        kcalMultiplier: calculation.multiplier,
        kcalBurned: calculation.kcalBurned,
      },
      include: { activity: true },
    });
  }

  async remove(userId: string, id: string) {
    const entry = await this.prisma.activityEntry.findUnique({ where: { id }, include: { dog: true } });
    if (!entry || entry.dog.userId !== userId) throw new NotFoundException('Activity entry not found');
    await this.prisma.activityEntry.delete({ where: { id } });
  }
}
