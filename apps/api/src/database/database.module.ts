import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JobApplication } from './entities/job-application.entity';
import { FollowUp } from './entities/follow-up.entity';
import { RejectedJob } from './entities/rejected-job.entity';
import { OpensourceOpportunity } from './entities/opensource-opportunity.entity';
import { Draft } from './entities/draft.entity';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (cfg: ConfigService) => ({
        type: 'postgres',
        host: cfg.get<string>('POSTGRES_HOST', 'postgres'),
        port: Number(cfg.get('POSTGRES_PORT', 5432)),
        username: cfg.get<string>('POSTGRES_USER', 'jhound'),
        password: cfg.get<string>('POSTGRES_PASSWORD'),
        database: cfg.get<string>('POSTGRES_DB', 'jhound'),
        entities: [
          JobApplication,
          FollowUp,
          RejectedJob,
          OpensourceOpportunity,
          Draft,
        ],
        synchronize: false,
        migrationsRun: false,
        logging: cfg.get('NODE_ENV') === 'development' ? ['error', 'warn'] : ['error'],
      }),
    }),
  ],
})
export class DatabaseModule {}
