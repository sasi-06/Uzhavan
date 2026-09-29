import { Global, Module } from '@nestjs/common';
import { initializeApp, getApps, getApp, cert } from 'firebase-admin/app';
import { NotificationsService } from './notifications.service';
import * as fs from 'fs';
import * as path from 'path';

function getServiceAccount() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    } catch (e) {
      console.warn('Could not parse FIREBASE_SERVICE_ACCOUNT environment variable');
    }
  }

  const potentialPaths = [
    process.env.GOOGLE_APPLICATION_CREDENTIALS,
    path.resolve(process.cwd(), 'service-account.json'),
    path.resolve(__dirname, '../../service-account.json'),
    path.resolve(process.cwd(), '../backend/service-account.json'),
  ].filter(Boolean) as string[];

  for (const filePath of potentialPaths) {
    if (fs.existsSync(filePath)) {
      try {
        const content = fs.readFileSync(filePath, 'utf8');
        return JSON.parse(content);
      } catch (e) {
        console.warn(`Could not read service account from ${filePath}`);
      }
    }
  }

  return null;
}

@Global()
@Module({
  providers: [
    {
      provide: 'FIREBASE_INITIALIZER',
      useFactory: () => {
        if (!getApps().length) {
          const serviceAccount = getServiceAccount();
          if (serviceAccount) {
            return initializeApp({
              credential: cert(serviceAccount),
              projectId: serviceAccount.project_id || process.env.FIREBASE_PROJECT_ID,
            });
          }

          return initializeApp({
            projectId: process.env.FIREBASE_PROJECT_ID || 'uzhavan-69849',
          });
        }
        return getApp();
      },
    },
    NotificationsService,
  ],
  exports: [NotificationsService],
})
export class FirebaseModule {}
