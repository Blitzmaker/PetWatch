import { FoodStatus } from '@prisma/client';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

export class ReviewFoodDto {
  @IsEnum(FoodStatus)
  status!: FoodStatus;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  reviewComment?: string;
}
