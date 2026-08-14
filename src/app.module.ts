import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { TypeOrmModule } from '@nestjs/typeorm';
import { mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { AuthGuard } from './auth/auth.guard';
import { ChatsModule } from './chats/chats.module';
import { databaseEntities } from './database/entities';
import { MatchesModule } from './matches/matches.module';
import { NotificationsModule } from './notifications/notifications.module';
import { PostsModule } from './posts/posts.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const databaseUrl = config.get<string>('DATABASE_URL');
        const dbDriver = config.get<string>('DB_DRIVER', '').toLowerCase();
        const isProduction =
          config.get<string>('NODE_ENV', 'development').toLowerCase() ===
          'production';
        const allowSqljsInProduction =
          config.get<string>('ALLOW_SQLJS_IN_PROD', 'false') === 'true';
        const synchronize =
          config.get<string>('DB_SYNC', databaseUrl ? 'false' : 'true') ===
          'true';
        const useLocalPersistence =
          config.get<string>('DB_LOCAL_PERSIST', 'true') === 'true';

        if (dbDriver === 'sqljs' || !databaseUrl) {
          if (isProduction && !allowSqljsInProduction) {
            throw new Error(
              'DATABASE_URL is required in production. Refusing to start with local SQL.js storage.',
            );
          }

          if (useLocalPersistence) {
            const configuredPath = config.get<string>(
              'DB_LOCAL_PATH',
              'data/padel-local.sqlite',
            );
            const localDbPath = resolve(process.cwd(), configuredPath);
            mkdirSync(dirname(localDbPath), { recursive: true });

            return {
              type: 'sqljs',
              autoLoadEntities: true,
              synchronize,
              location: localDbPath,
              autoSave: true,
            };
          }

          return {
            type: 'sqljs',
            autoLoadEntities: true,
            synchronize,
          };
        }

        return {
          type: 'postgres',
          url: databaseUrl,
          autoLoadEntities: true,
          synchronize,
          ssl:
            config.get<string>('DB_SSL', 'false') === 'true'
              ? { rejectUnauthorized: false }
              : false,
        };
      },
    }),
    TypeOrmModule.forFeature([...databaseEntities]),
    AuthModule,
    UsersModule,
    PostsModule,
    NotificationsModule,
    MatchesModule,
    ChatsModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_GUARD,
      useClass: AuthGuard,
    },
  ],
})
export class AppModule {}
