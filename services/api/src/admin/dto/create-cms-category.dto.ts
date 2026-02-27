import { IsNotEmpty, IsString } from 'class-validator';

export class CreateCmsCategoryDto {
  @IsString()
  @IsNotEmpty()
  title!: string;

  @IsString()
  @IsNotEmpty()
  slug!: string;
}
