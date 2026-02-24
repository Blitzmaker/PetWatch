import { Module } from '@nestjs/common';
import { DogsModule } from '../dogs/dogs.module';
import { WeightsController } from './weights.controller';
import { WeightsService } from './weights.service';

@Module({ imports: [DogsModule], controllers: [WeightsController], providers: [WeightsService] })
export class WeightsModule {}
