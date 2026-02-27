import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CreateFoodDto } from './dto/create-food.dto';
import { FoodsService } from './foods.service';

@UseGuards(JwtAuthGuard)
@Controller('foods')
export class FoodsController {
  constructor(private readonly foodsService: FoodsService) {}

  @Get('by-barcode/:barcode')
  findByBarcode(@Param('barcode') barcode: string, @CurrentUser('sub') userId: string) {
    return this.foodsService.findByBarcode(barcode, userId);
  }

  @Post()
  create(@CurrentUser('sub') userId: string, @Body() dto: CreateFoodDto) {
    return this.foodsService.create(userId, dto);
  }
}
