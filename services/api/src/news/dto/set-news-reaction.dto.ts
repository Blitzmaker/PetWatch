import { NewsReactionType } from '@prisma/client';
import { IsEnum } from 'class-validator';

export class SetNewsReactionDto {
  @IsEnum(NewsReactionType)
  reaction!: NewsReactionType;
}
