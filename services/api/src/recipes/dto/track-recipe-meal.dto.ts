import { IsDateString, IsEnum, IsNumber, IsOptional, IsString, Min, ValidateIf } from 'class-validator';
import { MealType } from '../../meals/dto/create-meal.dto';

export enum RecipeTrackingMode {
  PORTIONS = 'PORTIONS',
  GRAMS = 'GRAMS',
}

export class TrackRecipeMealDto {
  @IsString()
  recipeId!: string;

  @IsDateString()
  eatenAt!: string;

  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  @IsEnum(MealType)
  mealType?: MealType;

  @IsEnum(RecipeTrackingMode)
  mode!: RecipeTrackingMode;

  @ValidateIf((dto) => dto.mode === RecipeTrackingMode.PORTIONS)
  @IsNumber()
  @Min(0.01)
  portions?: number;

  @ValidateIf((dto) => dto.mode === RecipeTrackingMode.GRAMS)
  @IsNumber()
  @Min(0.01)
  grams?: number;
}
