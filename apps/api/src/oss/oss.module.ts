import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OpensourceOpportunity } from '../database/entities/opensource-opportunity.entity';
import { OssController } from './oss.controller';
import { OssService } from './oss.service';

@Module({
  imports: [TypeOrmModule.forFeature([OpensourceOpportunity])],
  controllers: [OssController],
  providers: [OssService],
})
export class OssModule {}
