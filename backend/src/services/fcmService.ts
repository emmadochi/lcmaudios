import { initializeApp, cert, getApps, App } from 'firebase-admin/app';
import { getMessaging, Message } from 'firebase-admin/messaging';
import * as fs from 'fs';
import * as path from 'path';

let firebaseApp: App | null = null;

export const initFirebaseAdmin = (): boolean => {
  if (firebaseApp || getApps().length > 0) {
    firebaseApp = getApps()[0];
    return true;
  }

  try {
    // 1. Check for explicit JSON string or Base64 in environment
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      let rawJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON.trim();
      if (!rawJson.startsWith('{')) {
        // Try decoding Base64 if not starting with {
        try {
          rawJson = Buffer.from(rawJson, 'base64').toString('utf-8');
        } catch {
          // keep original
        }
      }
      const serviceAccount = JSON.parse(rawJson);
      firebaseApp = initializeApp({
        credential: cert(serviceAccount),
      });
      console.log('[FCM] ✅ Initialized Firebase Admin via FIREBASE_SERVICE_ACCOUNT_JSON.');
      return true;
    }

    // 2. Check for explicit File Path in environment or default file locations
    const possiblePaths = [
      process.env.FIREBASE_SERVICE_ACCOUNT_PATH,
      path.resolve(process.cwd(), 'serviceAccountKey.json'),
      path.resolve(process.cwd(), 'firebase-adminsdk.json'),
      path.resolve(process.cwd(), '../serviceAccountKey.json'),
      '/var/www/LCMAudios/backend/serviceAccountKey.json',
    ].filter(Boolean) as string[];

    for (const filePath of possiblePaths) {
      if (fs.existsSync(filePath)) {
        const fileContent = fs.readFileSync(filePath, 'utf-8');
        const serviceAccount = JSON.parse(fileContent);
        firebaseApp = initializeApp({
          credential: cert(serviceAccount),
        });
        console.log(`[FCM] ✅ Initialized Firebase Admin via credential file: ${filePath}`);
        return true;
      }
    }

    // 3. Check for granular environment variables
    if (
      process.env.FIREBASE_PROJECT_ID &&
      process.env.FIREBASE_CLIENT_EMAIL &&
      process.env.FIREBASE_PRIVATE_KEY
    ) {
      const privateKey = process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');
      firebaseApp = initializeApp({
        credential: cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey,
        }),
      });
      console.log('[FCM] ✅ Initialized Firebase Admin via granular environment credentials.');
      return true;
    }

    console.log('[FCM] ℹ️ Notice: Firebase Service Account credentials not provided yet in backend/.env. In-app smart release notification active.');
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
    console.log(`[FCM] ℹ️ Broadcast standby for new sermon: "${track.title}" by ${track.artist}. Devotees will receive instant in-app update upon sync.`);
    return false;
  }

  try {
    const messaging = getMessaging(firebaseApp);
    const payload: Message = {
      topic: 'all_devotees',
      notification: {
        title: 'New Faith Release 🎵',
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
          color: '#E63946',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: 'New Faith Release 🎵',
              body: `"${track.title}" by ${track.artist} is now streaming.`,
            },
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await messaging.send(payload);
    console.log(`[FCM] 🚀 Successfully broadcasted new sermon alert to 'all_devotees' topic. Message ID: ${response}`);
    return true;
  } catch (error) {
    console.error('[FCM] Failed to send broadcast notification:', error);
    return false;
  }
};

export interface MarketingCampaignOptions {
  campaignType: 'dawn_blessing' | 'midday_peace' | 'midnight_vigil' | 'inactivity_reconnect' | 'weekend_prep' | 'direct_pastoral' | 'custom';
  customTitle?: string;
  customBody?: string;
  intentCategory?: string;
  trackId?: string;
}

export const broadcastMarketingCampaign = async (options: MarketingCampaignOptions): Promise<{ success: boolean; messageId?: string; title: string; body: string }> => {
  const isReady = initFirebaseAdmin();

  let title = '';
  let body = '';

  switch (options.campaignType) {
    case 'dawn_blessing':
      title = options.customTitle || '🌅 First Fruit of the Morning';
      body = options.customBody || 'Command your morning! Start your day soaked in prophetic prayer and divine direction.';
      break;
    case 'midday_peace':
      title = options.customTitle || '⏳ Take a 2-Minute Peace Pause';
      body = options.customBody || 'Pause the busy day. Let sacred worship restore your focus and divine peace right now.';
      break;
    case 'midnight_vigil':
      title = options.customTitle || '🌙 Peace for Your Sleep & Night Vigil';
      body = options.customBody || 'Cast your cares upon Him. Fall asleep to anointed soaking worship and night prayer.';
      break;
    case 'inactivity_reconnect':
      title = options.customTitle || '✨ We\'re Holding You in Prayer Today';
      body = options.customBody || 'Life gets busy, but your spiritual peace matters. Tap to play today\'s Word of breakthrough.';
      break;
    case 'weekend_prep':
      title = options.customTitle || '📖 Prepare Your Heart for the Sabbath';
      body = options.customBody || 'Tune your spirit ahead of Sunday service with our anointed praise & worship collection.';
      break;
    case 'custom':
    default:
      title = options.customTitle || '🕊️ Special Message from LCM Audios';
      body = options.customBody || 'A sacred audio word is waiting to encourage your spirit today.';
      break;
  }

  if (!isReady || !firebaseApp) {
    console.log(`[FCM-Marketing] ℹ️ Simulated campaign send: [${title}] "${body}"`);
    return { success: false, title, body };
  }

  try {
    const messaging = getMessaging(firebaseApp);
    const payload: Message = {
      topic: 'all_devotees',
      notification: {
        title,
        body,
      },
      data: {
        type: 'marketing_campaign',
        campaignType: options.campaignType,
        intentCategory: options.intentCategory || 'all',
        trackId: options.trackId || '',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'lcm_broadcasts_channel',
          sound: 'default',
          color: '#E63946',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const messageId = await messaging.send(payload);
    console.log(`[FCM-Marketing] 🚀 Successfully sent campaign [${options.campaignType}] to 'all_devotees'. ID: ${messageId}`);
    return { success: true, messageId, title, body };
  } catch (error) {
    console.error('[FCM-Marketing] Failed to broadcast marketing campaign:', error);
    return { success: false, title, body };
  }
};
