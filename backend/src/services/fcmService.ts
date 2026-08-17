import admin from 'firebase-admin';

let isInitialized = false;

export const initFirebaseAdmin = () => {
  if (isInitialized) return;

  try {
    // 1. Check for raw Service Account JSON in environment
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      isInitialized = true;
      console.log('[FCM] Initialized Firebase Admin via FIREBASE_SERVICE_ACCOUNT_JSON.');
      return;
    }

    // 2. Check for granular environment variables
    if (
      process.env.FIREBASE_PROJECT_ID &&
      process.env.FIREBASE_CLIENT_EMAIL &&
      process.env.FIREBASE_PRIVATE_KEY
    ) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
      isInitialized = true;
      console.log('[FCM] Initialized Firebase Admin via environment credentials.');
      return;
    }

    console.log('[FCM] Notice: Firebase credentials not supplied yet. FCM push broadcasting is standing by.');
  } catch (error) {
    console.error('[FCM] Initialization error:', error);
  }
};

export const broadcastSermonNotification = async (track: {
  id: string;
  title: string;
  artist: string;
  subgenre?: string;
  albumArtUrl?: string;
}): Promise<boolean> => {
  initFirebaseAdmin();

  if (!isInitialized) {
    console.log(`[FCM] Simulated push broadcast for new sermon: "${track.title}" by ${track.artist}`);
    return false;
  }

  try {
    const payload: admin.messaging.Message = {
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

    const response = await admin.messaging().send(payload);
    console.log(`[FCM] ✅ Successfully broadcasted new sermon alert to 'all_devotees' topic. Message ID: ${response}`);
    return true;
  } catch (error) {
    console.error('[FCM] Failed to send broadcast notification:', error);
    return false;
  }
};
