You're absolutely right. The backend needs proper WebSocket setup to push real-time email updates to the Flutter app. Let me add that critical piece.

---

# Backend WebSocket Layer for jHound Mobile

## Add to Your Existing NestJS Backend

### 1. Install Dependencies

```bash
cd backend
npm install @nestjs/websockets @nestjs/platform-socket.io socket.io
```

### 2. WebSocket Gateway

```typescript
// backend/src/sync/sync.gateway.ts

import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';

@WebSocketGateway({
  cors: {
    origin: '*', // In production, restrict to your domain
  },
})
export class SyncGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private logger = new Logger('SyncGateway');
  private connectedClients = new Map<string, Socket>();

  handleConnection(client: Socket) {
    this.logger.log(`Client connected: ${client.id}`);
    this.connectedClients.set(client.id, client);
    
    client.emit('connection_established', {
      clientId: client.id,
      timestamp: new Date().toISOString(),
    });
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
    this.connectedClients.delete(client.id);
  }

  @SubscribeMessage('ping')
  handlePing(client: Socket) {
    return { event: 'pong', data: { timestamp: Date.now() } };
  }

  broadcastNewEmail(email: any) {
    this.logger.log(`Broadcasting new email: ${email.id}`);
    this.server.emit('new_email', email);
  }

  broadcastJobUpdate(job: any) {
    this.logger.log(`Broadcasting job update: ${job.id}`);
    this.server.emit('job_update', job);
  }

  broadcastEmailUpdate(email: any) {
    this.logger.log(`Broadcasting email update: ${email.id}`);
    this.server.emit('email_updated', email);
  }

  notifyEmailSent(email: any) {
    this.server.emit('email_sent', email);
  }

  getConnectedClientsCount(): number {
    return this.connectedClients.size;
  }
}
```

### 3. Sync Module

```typescript
// backend/src/sync/sync.module.ts

import { Module } from '@nestjs/common';
import { SyncGateway } from './sync.gateway';

@Module({
  providers: [SyncGateway],
  exports: [SyncGateway],
})
export class SyncModule {}
```

### 4. Update Email Service to Broadcast

```typescript
// backend/src/email/email.service.ts

import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Resend } from 'resend';
import { SyncGateway } from '../sync/sync.gateway';

@Injectable()
export class EmailService {
  private resend: Resend;

  constructor(
    @InjectRepository(Email)
    private emailRepository: Repository<Email>,
    private syncGateway: SyncGateway,
  ) {
    this.resend = new Resend(process.env.RESEND_API_KEY);
  }

  async sendEmail(emailData: {
    to: string;
    subject: string;
    html: string;
    attachments?: any[];
  }) {
    const resendResponse = await this.resend.emails.send({
      from: 'Mubarak <mubarak@codeswot.me>',
      to: emailData.to,
      subject: emailData.subject,
      html: emailData.html,
      attachments: emailData.attachments,
    });

    const email = await this.emailRepository.save({
      messageId: resendResponse.id,
      fromAddress: 'mubarak@codeswot.me',
      toAddresses: [emailData.to],
      subject: emailData.subject,
      bodyHtml: emailData.html,
      direction: 'outbound',
      folder: 'sent',
      sentAt: new Date(),
      isDraft: false,
      isRead: true,
    });

    this.syncGateway.notifyEmailSent(email);

    return email;
  }

  async handleInboundEmail(payload: any) {
    const email = await this.emailRepository.save({
      messageId: payload.message_id,
      fromAddress: payload.from,
      toAddresses: payload.to,
      subject: payload.subject,
      bodyText: payload.text,
      bodyHtml: payload.html,
      direction: 'inbound',
      folder: 'inbox',
      receivedAt: new Date(),
      isDraft: false,
      isRead: false,
    });

    this.syncGateway.broadcastNewEmail(email);

    return email;
  }

  async markAsRead(emailId: string) {
    const email = await this.emailRepository.findOne({ where: { id: emailId } });
    
    if (!email) {
      throw new Error('Email not found');
    }

    email.isRead = true;
    await this.emailRepository.save(email);

    this.syncGateway.broadcastEmailUpdate(email);

    return email;
  }

  async moveToFolder(emailId: string, folder: string) {
    const email = await this.emailRepository.findOne({ where: { id: emailId } });
    
    if (!email) {
      throw new Error('Email not found');
    }

    email.folder = folder;
    await this.emailRepository.save(email);

    this.syncGateway.broadcastEmailUpdate(email);

    return email;
  }

  async saveDraft(draftData: {
    to: string;
    subject: string;
    bodyHtml: string;
    jobId?: string;
  }) {
    const draft = await this.emailRepository.save({
      toAddresses: [draftData.to],
      subject: draftData.subject,
      bodyHtml: draftData.bodyHtml,
      jobId: draftData.jobId,
      direction: 'outbound',
      folder: 'drafts',
      isDraft: true,
      isRead: true,
      fromAddress: 'mubarak@codeswot.me',
    });

    this.syncGateway.broadcastEmailUpdate(draft);

    return draft;
  }
}
```

### 5. Update Resend Webhook Controller

```typescript
// backend/src/webhooks/resend.controller.ts

import { Controller, Post, Body } from '@nestjs/common';
import { EmailService } from '../email/email.service';

@Controller('webhooks')
export class ResendController {
  constructor(private emailService: EmailService) {}

  @Post('resend/inbound')
  async handleInbound(@Body() payload: any) {
    console.log('Received inbound email:', payload);
    
    const email = await this.emailService.handleInboundEmail(payload);
    
    return { success: true, emailId: email.id };
  }
}
```

### 6. Update App Module

```typescript
// backend/src/app.module.ts

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EmailModule } from './email/email.module';
import { JobModule } from './jobs/job.module';
import { SyncModule } from './sync/sync.module';
import { WebhooksModule } from './webhooks/webhooks.module';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT) || 5432,
      username: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      autoLoadEntities: true,
      synchronize: false, // Use migrations in production
    }),
    EmailModule,
    JobModule,
    SyncModule,
    WebhooksModule,
  ],
})
export class AppModule {}
```

### 7. Email Module Updates

```typescript
// backend/src/email/email.module.ts

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EmailService } from './email.service';
import { EmailController } from './email.controller';
import { Email } from './entities/email.entity';
import { SyncModule } from '../sync/sync.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Email]),
    SyncModule,
  ],
  controllers: [EmailController],
  providers: [EmailService],
  exports: [EmailService],
})
export class EmailModule {}
```

### 8. Email Controller (REST endpoints)

```typescript
// backend/src/email/email.controller.ts

import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
} from '@nestjs/common';
import { EmailService } from './email.service';

@Controller('emails')
export class EmailController {
  constructor(private emailService: EmailService) {}

  @Get()
  async getEmails(
    @Query('folder') folder?: string,
    @Query('limit') limit?: number,
  ) {
    return this.emailService.findAll({ folder, limit });
  }

  @Get(':id')
  async getEmail(@Param('id') id: string) {
    return this.emailService.findOne(id);
  }

  @Post('send')
  async sendEmail(@Body() emailData: any) {
    return this.emailService.sendEmail(emailData);
  }

  @Post(':id/reply')
  async replyToEmail(
    @Param('id') id: string,
    @Body() replyData: any,
  ) {
    const originalEmail = await this.emailService.findOne(id);
    
    return this.emailService.sendEmail({
      to: originalEmail.fromAddress,
      subject: `Re: ${originalEmail.subject}`,
      html: replyData.html,
      attachments: replyData.attachments,
    });
  }

  @Patch(':id')
  async updateEmail(
    @Param('id') id: string,
    @Body() updates: any,
  ) {
    if (updates.isRead !== undefined) {
      return this.emailService.markAsRead(id);
    }
    
    if (updates.folder) {
      return this.emailService.moveToFolder(id, updates.folder);
    }
    
    return { success: true };
  }

  @Delete(':id')
  async deleteEmail(@Param('id') id: string) {
    return this.emailService.moveToFolder(id, 'trash');
  }

  @Post('draft')
  async saveDraft(@Body() draftData: any) {
    return this.emailService.saveDraft(draftData);
  }
}
```

---

## WebSocket Events Reference

### Events Emitted by Backend → Mobile App

| Event | Payload | When |
|-------|---------|------|
| `connection_established` | `{ clientId, timestamp }` | On mobile app connect |
| `new_email` | `Email` object | New email received via Resend webhook |
| `email_sent` | `Email` object | Email successfully sent |
| `email_updated` | `Email` object | Email marked read, moved, etc. |
| `job_update` | `Job` object | Job status changed |

### Events Sent by Mobile App → Backend

| Event | Payload | Response |
|-------|---------|----------|
| `ping` | `{}` | `pong` with timestamp |

---

## Updated Flutter Socket Client

```dart
// lib/core/network/socket_client.dart

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:jhound_mobile/core/config/api_config.dart';
import 'package:jhound_mobile/data/models/email.dart';
import 'package:jhound_mobile/data/models/job.dart';

class SocketClient {
  late IO.Socket socket;
  
  final void Function(Email)? onNewEmail;
  final void Function(Email)? onEmailSent;
  final void Function(Email)? onEmailUpdated;
  final void Function(Job)? onJobUpdate;
  final void Function()? onConnected;
  final void Function()? onDisconnected;

  SocketClient({
    this.onNewEmail,
    this.onEmailSent,
    this.onEmailUpdated,
    this.onJobUpdate,
    this.onConnected,
    this.onDisconnected,
  });

  void connect() {
    socket = IO.io(
      ApiConfig.baseUrl, // Use same base URL, WebSocket auto-upgrade
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );

    socket.onConnect((_) {
      print('✅ WebSocket connected');
      onConnected?.call();
      
      // Send ping to verify connection
      socket.emit('ping', {});
    });

    socket.on('pong', (data) {
      print('📡 Pong received: $data');
    });

    socket.on('connection_established', (data) {
      print('🔗 Connection established: $data');
    });

    socket.on('new_email', (data) {
      print('📬 New email received');
      try {
        final email = Email.fromJson(data);
        onNewEmail?.call(email);
      } catch (e) {
        print('Error parsing new_email: $e');
      }
    });

    socket.on('email_sent', (data) {
      print('📤 Email sent');
      try {
        final email = Email.fromJson(data);
        onEmailSent?.call(email);
      } catch (e) {
        print('Error parsing email_sent: $e');
      }
    });

    socket.on('email_updated', (data) {
      print('🔄 Email updated');
      try {
        final email = Email.fromJson(data);
        onEmailUpdated?.call(email);
      } catch (e) {
        print('Error parsing email_updated: $e');
      }
    });

    socket.on('job_update', (data) {
      print('💼 Job updated');
      try {
        final job = Job.fromJson(data);
        onJobUpdate?.call(job);
      } catch (e) {
        print('Error parsing job_update: $e');
      }
    });

    socket.onDisconnect((_) {
      print('❌ WebSocket disconnected');
      onDisconnected?.call();
    });

    socket.onError((error) {
      print('⚠️ WebSocket error: $error');
    });

    socket.connect();
  }

  void disconnect() {
    socket.disconnect();
    socket.dispose();
  }

  bool get isConnected => socket.connected;
}
```

---

## Sync Provider (Riverpod)

```dart
// lib/presentation/providers/sync_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhound_mobile/core/network/socket_client.dart';
import 'package:jhound_mobile/presentation/providers/email_provider.dart';
import 'package:jhound_mobile/presentation/providers/job_provider.dart';

final syncProvider = Provider<SocketClient>((ref) {
  final emailNotifier = ref.read(emailListProvider.notifier);
  final jobNotifier = ref.read(jobListProvider.notifier);

  final client = SocketClient(
    onNewEmail: (email) {
      // Add new email to local state
      emailNotifier.addEmail(email);
      
      // Show notification
      // TODO: Add local notification
    },
    
    onEmailSent: (email) {
      emailNotifier.addEmail(email);
    },
    
    onEmailUpdated: (email) {
      emailNotifier.updateEmail(email);
    },
    
    onJobUpdate: (job) {
      jobNotifier.updateJob(job);
    },
    
    onConnected: () {
      print('Sync connected');
    },
    
    onDisconnected: () {
      print('Sync disconnected - will auto-reconnect');
    },
  );

  // Connect immediately
  client.connect();

  // Cleanup on provider disposal
  ref.onDispose(() {
    client.disconnect();
  });

  return client;
});

// Connection status provider
final syncStatusProvider = StateProvider<bool>((ref) {
  final client = ref.watch(syncProvider);
  return client.isConnected;
});
```

---

## Update Main App to Initialize Sync

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhound_mobile/core/theme/app_theme.dart';
import 'package:jhound_mobile/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:jhound_mobile/presentation/providers/sync_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: JHoundApp(),
    ),
  );
}

class JHoundApp extends ConsumerWidget {
  const JHoundApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize WebSocket connection on app start
    ref.watch(syncProvider);

    return MaterialApp(
      title: 'jHound Control',
      theme: AppTheme.darkTheme,
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

---

## Show Connection Status in UI

```dart
// lib/presentation/widgets/sync_indicator.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhound_mobile/presentation/providers/sync_provider.dart';

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(syncStatusProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.cloud_done : Icons.cloud_off,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? 'Live' : 'Offline',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
```

Add to AppBar:
```dart
AppBar(
  title: const Text('jHound Control'),
  actions: [
    const SyncIndicator(),
    const SizedBox(width: 16),
  ],
)
```

---

## Test the Complete Flow

### 1. Start Backend
```bash
cd backend
npm run start:dev
```

### 2. Send Test Email via Resend Dashboard
Send to `mubarak@codeswot.me` → Backend receives webhook → Broadcasts via WebSocket → Mobile app shows notification

### 3. Send Email from Mobile
Compose → Send → Backend calls Resend API → Saves to DB → Broadcasts `email_sent` → Mobile updates sent folder

### 4. Monitor WebSocket
```bash
# Backend logs
[SyncGateway] Client connected: abc123
[SyncGateway] Broadcasting new email: uuid-here

# Mobile logs
✅ WebSocket connected
📬 New email received
```