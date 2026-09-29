import { Injectable } from '@nestjs/common';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getMessaging, MulticastMessage } from 'firebase-admin/messaging';

@Injectable()
export class NotificationsService {
  async sendNotification(
    userId: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ) {
    const db = getFirestore();

    // 1. Log notification in Firestore for in-app history/sync
    const notificationRef = db.collection('notifications').doc();
    await notificationRef.set({
      id: notificationRef.id,
      userId,
      title,
      body,
      data: data || {},
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    });

    // 2. Fetch User FCM tokens from users collection
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();
    const tokens: string[] = userData?.fcmTokens || [];

    if (tokens.length === 0) return;

    // 3. Dispatch Push Notification via FCM
    const message: MulticastMessage = {
      tokens,
      notification: { title, body },
      data: data || {},
    };

    try {
      const messaging = getMessaging();
      const response = await messaging.sendEachForMulticast(message);
      
      // Clean up invalid or unregistered tokens if they failed
      if (response.failureCount > 0) {
        const badTokens: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const code = resp.error?.code;
            if (
              code === 'messaging/invalid-registration-token' ||
              code === 'messaging/registration-token-not-registered'
            ) {
              badTokens.push(tokens[idx]);
            }
          }
        });
        if (badTokens.length > 0) {
          await db.collection('users').doc(userId).update({
            fcmTokens: FieldValue.arrayRemove(...badTokens),
          });
        }
      }
    } catch (err) {
      console.error('Failed to send push notifications', err);
    }
  }
}
