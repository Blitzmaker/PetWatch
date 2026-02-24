import { Body, Controller, Delete, Get, HttpCode, Param, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CreateWeightDto } from './dto/create-weight.dto';
import { WeightsService } from './weights.service';

@UseGuards(JwtAuthGuard)
@Controller()
export class WeightsController {
  constructor(private readonly weightsService: WeightsService) {}

  @Get('dogs/:dogId/weights')
  findAll(@CurrentUser('sub') userId: string, @Param('dogId') dogId: string) {
    return this.weightsService.findAll(userId, dogId);
  }

  @Post('dogs/:dogId/weights')
  create(@CurrentUser('sub') userId: string, @Param('dogId') dogId: string, @Body() dto: CreateWeightDto) {
    return this.weightsService.create(userId, dogId, dto);
  }

  @Delete('weights/:id')
  @HttpCode(204)
  async remove(@CurrentUser('sub') userId: string, @Param('id') id: string) {
    await this.weightsService.remove(userId, id);
  }
}
