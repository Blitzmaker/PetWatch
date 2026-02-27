import { IsString } from 'class-validator';

export class CreateCommunityThreadDto {
  @IsString()
  topicId!: string;

  @IsString()
  title!: string;

  @IsString()
  content!: string;
}
