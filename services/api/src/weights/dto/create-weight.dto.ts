import { IsDateString, IsNumber, Min } from "class-validator";

export class CreateWeightDto {
  @IsDateString()
  date!: string;

  @IsNumber()
  @Min(0)
  weightKg!: number;
}
