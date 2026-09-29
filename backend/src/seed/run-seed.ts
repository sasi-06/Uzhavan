import { loadEnv } from '../config/load-env';
loadEnv();

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { SeedService } from './seed.service';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const seed = app.get(SeedService);
  await seed.run();
  await app.close();
  console.log('Seed complete');
}

bootstrap();
