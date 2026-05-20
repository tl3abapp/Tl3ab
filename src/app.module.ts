import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { AppController } from './app.controller';
import { AppService } from './app.service';
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
        const synchronize = config.get<string>('DB_SYNC', 'true') === 'true';
        const useLocalPersistence =
          config.get<string>('DB_LOCAL_PERSIST', 'true') === 'true';

        if (dbDriver === 'sqljs' || !databaseUrl) {
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
    UsersModule,
    PostsModule,
    NotificationsModule,
    MatchesModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
