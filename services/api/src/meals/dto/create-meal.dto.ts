import { Type } from "class-transformer";
import { ArrayMinSize, IsArray, IsDateString, IsEnum, IsNumber, IsOptional, IsString, Min, ValidateNested } from "class-validator";

export enum MealType {
  BREAKFAST = "BREAKFAST",
  LUNCH = "LUNCH",
  DINNER = "DINNER",
  SNACK = "SNACK",
}

export class CreateMealEntryDto {
  @IsString()
  foodId!: string;

  @IsNumber()
  @Min(0)
  grams!: number;

  @IsOptional()
  @IsEnum(MealType)
  mealType?: MealType;
}

export class CreateMealDto {
  @IsDateString()
  eatenAt!: string;

  @IsOptional()
  @IsString()
  note?: string;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CreateMealEntryDto)
  entries!: CreateMealEntryDto[];
}
