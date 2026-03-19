import { IsDateString, IsInt, IsString, Min } from 'class-validator';

export class CreateActivityEntryDto {
  @IsString()
  activityId!: string;

  @IsInt()
  @Min(1)
  durationMinutes!: number;

  @IsDateString()
  performedAt!: string;
}
