import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CreateDogDto } from './dto/create-dog.dto';
import { UpdateDogDto } from './dto/update-dog.dto';
import { DogsService } from './dogs.service';

@UseGuards(JwtAuthGuard)
@Controller('dogs')
export class DogsController {
  constructor(private readonly dogsService: DogsService) {}

  @Get()
  findAll(@CurrentUser('sub') userId: string) {
    return this.dogsService.findAll(userId);
  }

  @Post()
  create(@CurrentUser('sub') userId: string, @Body() dto: CreateDogDto) {
    return this.dogsService.create(userId, dto);
  }

  @Get(':id')
  findOne(@CurrentUser('sub') userId: string, @Param('id') id: string) {
    return this.dogsService.findOne(userId, id);
  }

  @Patch(':id')
  update(@CurrentUser('sub') userId: string, @Param('id') id: string, @Body() dto: UpdateDogDto) {
    return this.dogsService.update(userId, id, dto);
  }
}
