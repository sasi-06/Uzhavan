import { loadEnv } from '../config/load-env';
loadEnv();

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { SchemesService } from '../schemes/schemes.service';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const schemesService = app.get(SchemesService);
  const res = await schemesService.seedSchemes();
  console.log(res.message);
  await app.close();
}

bootstrap().catch((err) => {
  console.error('Failed to seed schemes:', err);
  process.exit(1);
});
