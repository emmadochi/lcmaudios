import { initializeApp, cert, getApps, App } from 'firebase-admin/app';
import { getMessaging, Message } from 'firebase-admin/messaging';

let firebaseApp: App | null = null;

export const initFirebaseAdmin = (): boolean => {
  if (firebaseApp || getApps().length > 0) {
    firebaseApp = getApps()[0];
    return true;
  }

  try {
    // 1. Check for raw Service Account JSON in environment
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      firebaseApp = initializeApp({
        credential: cert(serviceAccount),
      });
      console.log('[FCM] Initialized Firebase Admin via FIREBASE_SERVICE_ACCOUNT_JSON.');
      return true;
    }

    // 2. Check for granular environment variables
    if (
      process.env.FIREBASE_PROJECT_ID &&
      process.env.FIREBASE_CLIENT_EMAIL &&
      process.env.FIREBASE_PRIVATE_KEY
    ) {
      firebaseApp = initializeApp({
        credential: cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
      console.log('[FCM] Initialized Firebase Admin via environment credentials.');
      return true;
    }

    console.log('[FCM] Notice: Firebase credentials not supplied yet. FCM push broadcasting is standing by.');
    return false;
  } catch (error) {
    console.error('[FCM] Initialization error:', error);
    return false;
  }
};

export const broadcastSermonNotification = async (track: {
  id: string;
  title: string;
  artist: string;
  subgenre?: string;
  albumArtUrl?: string;
}): Promise<boolean> => {
  const isReady = initFirebaseAdmin();

  if (!isReady || !firebaseApp) {
    console.log(`[FCM] Simulated push broadcast for new sermon: "${track.title}" by ${track.artist}`);
    return false;
  }

  try {
    const messaging = getMessaging(firebaseApp);
    const payload: Message = {
      topic: 'all_devotees',
      notification: {
        title: '🕊️ New Faith Release',
        body: `"${track.title}" by ${track.artist} is now streaming.`,
      },
      data: {
        trackId: track.id,
        title: track.title,
        artist: track.artist,
        type: 'new_sermon_release',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'lcm_broadcasts_channel',
          sound: 'default',
          color: '#E53935',
        },
      },
    };

    const response = await messaging.send(payload);
    console.log(`[FCM] ✅ Successfully broadcasted new sermon alert to 'all_devotees' topic. Message ID: ${response}`);
    return true;
  } catch (error) {
    console.error('[FCM] Failed to send broadcast notification:', error);
    return false;
  }
};
