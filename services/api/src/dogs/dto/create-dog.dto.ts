import { IsBoolean, IsDateString, IsEnum, IsNumber, IsOptional, IsString, Min } from "class-validator";

export enum Sex {
  MALE = "MALE",
  FEMALE = "FEMALE",
  UNKNOWN = "UNKNOWN",
}

export enum ActivityLevel {
  LOW = "LOW",
  MEDIUM = "MEDIUM",
  HIGH = "HIGH",
}

export class CreateDogDto {
  @IsString()
  name!: string;


  @IsOptional()
  @IsString()
  breed?: string;

  @IsOptional()
  @IsDateString()
  birthdate?: string; // ISO date string

  @IsOptional()
  @IsEnum(Sex)
  sex?: Sex;

  @IsOptional()
  @IsNumber()
  @Min(0)
  targetWeightKg?: number;

  @IsOptional()
  @IsEnum(ActivityLevel)
  activityLevel?: ActivityLevel;

  @IsOptional()
  @IsBoolean()
  isNeutered?: boolean;

  @IsOptional()
  @IsNumber()
  @Min(0)
  dailyKcalTarget?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  currentWeightKg?: number;
}
