import { IsString } from 'class-validator';

export class CreateCommunityPostDto {
  @IsString()
  threadId!: string;

  @IsString()
  content!: string;
}
