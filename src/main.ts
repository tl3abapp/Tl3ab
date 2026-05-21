import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import type { NextFunction, Request, Response } from 'express';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  app.enableCors();
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: true,
    }),
  );

  const apiPrefix = process.env.API_PREFIX?.replace(/^\/+|\/+$/g, '');
  if (apiPrefix) {
    app.setGlobalPrefix(apiPrefix);
  }

  const publicPath = join(__dirname, '..', 'public');
  const indexPath = join(publicPath, 'index.html');
  if (existsSync(indexPath)) {
    app.useStaticAssets(publicPath, { index: false });

    const server = app.getHttpAdapter().getInstance();
    server.get(/.*/, (req: Request, res: Response, next: NextFunction) => {
      if (
        apiPrefix &&
        (req.path === `/${apiPrefix}` || req.path.startsWith(`/${apiPrefix}/`))
      ) {
        return next();
      }

      return res.sendFile(indexPath);
    });
  }

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port, '0.0.0.0');
  console.log(`padel-api running on http://localhost:${port}`);
}
bootstrap();
