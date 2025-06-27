// src/admin/admin.module.ts

import { Module } from '@nestjs/common';
import { AdminService } from './admin.service';
import { AdminController } from './admin.controller';
import { TypeOrmModule } from '@nestjs/typeorm';

import { CommandeStatutView } from '../entities/commande-statut-view.entity';
import { Roles } from '../entities/Roles'; 

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Roles,                // Nécessaire pour Repository<Roles>
      CommandeStatutView,   // Nécessaire pour Repository<CommandeStatutView>
    ]),
  ],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}