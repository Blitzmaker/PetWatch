import { IsInt, IsNumber, IsOptional, IsString, Min } from "class-validator";

export class CreateFoodDto {
  @IsString()
  barcode!: string;

  @IsString()
  name!: string;

  @IsOptional()
  @IsString()
  brand?: string;

  @IsInt()
  @Min(1)
  kcalPer100g!: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  proteinPer100g?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  fatPer100g?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  carbsPer100g?: number;
}
