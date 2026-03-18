import { IsInt, IsNumber, IsOptional, IsString, Max, Min } from "class-validator";

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
  @Max(100)
  proteinPercent?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  fatPercent?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  crudeAshPercent?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  crudeFiberPercent?: number;
}
