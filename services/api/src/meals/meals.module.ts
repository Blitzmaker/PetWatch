import { Module } from '@nestjs/common';
import { DogsModule } from '../dogs/dogs.module';
import { MealsController } from './meals.controller';
import { MealsService } from './meals.service';

@Module({ imports: [DogsModule], controllers: [MealsController], providers: [MealsService] })
export class MealsModule {}
