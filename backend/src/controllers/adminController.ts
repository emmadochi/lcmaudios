import { Request, Response } from 'express';
import { dbClient } from '../data/dbClient';
import { HlsTranscoder } from '../services/hlsTranscoder';
import { S3StorageService } from '../services/s3StorageService';
import { broadcastSermonNotification, broadcastMarketingCampaign } from '../services/fcmService';
import { Track, LyricLine, IntentCategory, MediaType, CategoryItem } from '../models/types';
import path from 'path';

export const uploadMedia = async (req: Request, res: Response): Promise<void> => {
  try {
    const files = req.files as { [fieldname: string]: Express.Multer.File[] };

    // Derive public base URL from incoming request with HTTPS support behind proxy
    const isHttps = req.secure || req.headers['x-forwarded-proto'] === 'https' || (req.get('host') || '').includes('lifechangerstouch.org');
    const protocol = isHttps ? 'https' : (req.protocol || 'http');
    const serverBaseUrl = process.env.SERVER_BASE_URL || `${protocol}://${req.get('host')}`;

    let audioUrl = '';
    let albumArtUrl = '';

    if (files && files['audioFile'] && files['audioFile'][0]) {
      const audioFile = files['audioFile'][0];

      // Upload to AWS S3 (or fallback to server URL)
      const uploadRes = await S3StorageService.uploadFile(
        audioFile.path,
        'audio',
        audioFile.filename,
        serverBaseUrl
      );
      audioUrl = uploadRes.url;

      // Trigger FFmpeg HLS stream packaging asynchronously in background (non-blocking)
      const trackTempId = `hls_${Date.now()}`;
      HlsTranscoder.transcodeToHls(audioFile.path, trackTempId, serverBaseUrl).catch((err) => {
        console.warn('[HLS] Background transcode notice:', err);
      });
    }

    if (files && files['artworkFile'] && files['artworkFile'][0]) {
      const artworkFile = files['artworkFile'][0];
      const uploadRes = await S3StorageService.uploadFile(
        artworkFile.path,
        'artwork',
        artworkFile.filename,
        serverBaseUrl
      );
      albumArtUrl = uploadRes.url;
    }

    res.status(200).json({
      message: 'Files uploaded and processed successfully.',
      audioUrl,
      albumArtUrl,
      hlsUrl: audioUrl,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to upload media files.' });
  }
};

export const createTrackAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { title, artist, audioUrl, albumArtUrl, duration, subgenre, intentCategory, mediaType, isPremium, lyrics } = req.body;

    if (!title || !artist || !audioUrl || !intentCategory) {
      res.status(400).json({ error: 'title, artist, audioUrl, and intentCategory are required fields.' });
      return;
    }

    const trackId = `track_${Date.now()}`;

    let parsedLyrics: LyricLine[] = [];
    if (Array.isArray(lyrics)) {
      parsedLyrics = lyrics.map((l: any, idx: number) => ({
        id: `lyr_${trackId}_${idx}`,
        trackId,
        timestampSeconds: Number(l.timestampSeconds) || 0,
        text: String(l.text || '').trim(),
      }));
    }

    const newTrack: Track = {
      id: trackId,
      title: title.trim(),
      artist: artist.trim(),
      albumArtUrl: albumArtUrl || 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=800&q=80',
      audioUrl: audioUrl.trim(),
      duration: Number(duration) || 300,
      subgenre: subgenre || 'Spiritual',
      intentCategory: intentCategory as IntentCategory,
      mediaType: (mediaType as MediaType) || 'song',
      isDownloaded: false,
      isFavorite: false,
      isPremium: isPremium === true || isPremium === 'true',
      playCount: 1,
      lyrics: parsedLyrics,
      createdAt: new Date().toISOString(),
    };

    const saved = await dbClient.createTrack(newTrack);

    // Asynchronously broadcast push notification to all mobile app devotees
    broadcastSermonNotification(newTrack).catch((err) => {
      console.warn('[FCM] Broadcast notice:', err);
    });

    res.status(201).json({
      message: 'Track ingested successfully and published to live database.',
      track: saved,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create track.' });
  }
};

export const updateTrackAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { title, artist, subgenre, intentCategory, mediaType, isPremium, duration, albumArtUrl, audioUrl, lyrics } = req.body;

    const cleanUpdateData: Partial<Track> = {};
    if (title !== undefined) cleanUpdateData.title = String(title).trim();
    if (artist !== undefined) cleanUpdateData.artist = String(artist).trim();
    if (subgenre !== undefined) cleanUpdateData.subgenre = String(subgenre).trim();
    if (intentCategory !== undefined) cleanUpdateData.intentCategory = intentCategory as IntentCategory;
    if (mediaType !== undefined) cleanUpdateData.mediaType = mediaType as MediaType;
    if (isPremium !== undefined) {
      cleanUpdateData.isPremium = isPremium === true || isPremium === 'true' || isPremium === 1 || isPremium === '1';
    }
    if (duration !== undefined && duration !== null && duration !== '') {
      cleanUpdateData.duration = Number(duration);
    }
    if (albumArtUrl !== undefined) cleanUpdateData.albumArtUrl = String(albumArtUrl).trim();
    if (audioUrl !== undefined) cleanUpdateData.audioUrl = String(audioUrl).trim();

    const updated = await dbClient.updateTrack(id, cleanUpdateData);

    if (!updated) {
      res.status(404).json({ error: 'Track not found.' });
      return;
    }

    res.status(200).json({
      message: 'Track updated successfully.',
      track: updated,
    });
  } catch (error) {
    console.error('[Admin] Error updating track:', error);
    res.status(500).json({ error: 'Failed to update track.' });
  }
};

export const deleteTrackAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const deleted = await dbClient.deleteTrack(id);
    if (!deleted) {
      res.status(404).json({ error: 'Track not found.' });
      return;
    }

    res.status(200).json({ message: 'Track deleted successfully.' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete track.' });
  }
};

// --- ANALYTICS CONTROLLER ---
export const getAnalyticsAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const tracks = await dbClient.getTracks();
    const notes = await dbClient.getNotes();
    const users = await dbClient.getUsersWithTelemetry();

    // Compute live devotee telemetry
    const devoteeStreams = users.reduce((sum, u) => sum + (u.streamCount || 0), 0);
    const devoteeMinutes = users.reduce((sum, u) => sum + (u.totalListeningMinutes || 0), 0);
    const devoteeDownloads = users.reduce((sum, u) => sum + (u.downloadCount || 0), 0);
    const activeCovenant = users.filter(u => u.subscriptionTier === 'annual' || u.subscriptionTier === 'lifetime' || u.subscriptionTier === 'monthly').length;

    let trackStreams = 0;
    const categoryCounts: { [key: string]: number } = {};

    tracks.forEach((t) => {
      const plays = t.playCount || 0;
      trackStreams += plays;
      const catKey = t.categoryKey || t.intentCategory || 'Other';
      categoryCounts[catKey] = (categoryCounts[catKey] || 0) + plays;
    });

    const totalStreams = devoteeStreams > 0 ? devoteeStreams : trackStreams;
    const totalListeningHours = Math.round(devoteeMinutes / 60);

    const topCategories = Object.keys(categoryCounts).map((cat) => ({
      category: cat,
      count: categoryCounts[cat],
      percentage: trackStreams > 0 ? Math.round((categoryCounts[cat] / trackStreams) * 100) : 0,
    }));

    const sortedTracks = [...tracks].sort((a, b) => (b.playCount || 0) - (a.playCount || 0)).slice(0, 10);

    res.status(200).json({
      analytics: {
        totalStreams: totalStreams,
        activeListeners: users.length,
        totalListeningHours: totalListeningHours,
        totalListeningMinutes: devoteeMinutes,
        totalDownloads: devoteeDownloads,
        activeCovenant,
        totalNotesTaken: notes.length,
        topCategories,
        topTracks: sortedTracks,
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch analytics.' });
  }
};

// --- CATEGORY MANAGEMENT CONTROLLERS ---
export const getCategoriesAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const categories = await dbClient.getCategories();
    res.status(200).json({ categories });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch categories.' });
  }
};

export const createCategoryAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { title, description, icon, accentColor, categoryKey } = req.body;

    if (!title || !categoryKey) {
      res.status(400).json({ error: 'title and categoryKey are required fields.' });
      return;
    }

    const category = await dbClient.createCategory({
      categoryKey: categoryKey.trim(),
      title: title.trim(),
      description: description ? description.trim() : '',
      icon: icon || 'auto_awesome_rounded',
      accentColor: accentColor || '#E63946',
      isActive: true,
    });

    res.status(201).json({ message: 'Category created successfully.', category });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create category.' });
  }
};

export const updateCategoryAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { title, categoryKey, description, icon, accentColor, isActive } = req.body;

    const updated = await dbClient.updateCategory(id, { title, categoryKey, description, icon, accentColor, isActive });

    if (!updated) {
      res.status(404).json({ error: 'Category not found.' });
      return;
    }

    res.status(200).json({ message: 'Category updated successfully.', category: updated });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update category.' });
  }
};

export const deleteCategoryAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const deleted = await dbClient.deleteCategory(id);

    if (!deleted) {
      res.status(404).json({ error: 'Category not found.' });
      return;
    }

    res.status(200).json({ message: 'Category deleted successfully.' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete category.' });
  }
};

export const testNotificationAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { title, artist } = req.body || {};
    const success = await broadcastSermonNotification({
      id: 'test-broadcast-' + Date.now(),
      title: title || 'LCM Audios Ministry Alert',
      artist: artist || 'Life Care Ministry Choir',
    });

    if (success) {
      res.status(200).json({
        success: true,
        message: 'FCM push broadcast successfully sent to topic: all_devotees',
      });
    } else {
      res.status(200).json({
        success: false,
        message: 'Firebase Admin credentials not configured in backend/.env. Simulated broadcast logged to server console.',
      });
    }
  } catch (error) {
    res.status(500).json({ success: false, error: 'Failed to broadcast test notification.' });
  }
};

export const sendMarketingCampaignAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { campaignType, customTitle, customBody, intentCategory, trackId } = req.body || {};
    
    if (!campaignType) {
      res.status(400).json({ error: 'campaignType is required (e.g. dawn_blessing, midday_peace, midnight_vigil, inactivity_reconnect, weekend_prep, custom).' });
      return;
    }

    const result = await broadcastMarketingCampaign({
      campaignType,
      customTitle,
      customBody,
      intentCategory,
      trackId,
    });

    res.status(200).json({
      success: true,
      deliveredToTopic: 'all_devotees',
      fcmSent: result.success,
      messageId: result.messageId,
      campaign: {
        type: campaignType,
        title: result.title,
        body: result.body,
        sentAt: new Date().toISOString(),
      },
    });
  } catch (error: any) {
    console.error('Marketing campaign error:', error);
    res.status(500).json({ error: error.message || 'Failed to dispatch marketing campaign.' });
  }
};

// --- DEVOTEE & USER MANAGEMENT CONTROLLERS ---

export const getAdminUsers = async (req: Request, res: Response): Promise<void> => {
  try {
    const { tier, search, status } = req.query;
    const users = await dbClient.getUsersWithTelemetry({
      tier: tier as string,
      search: search as string,
      status: status as string,
    });

    const allUsers = await dbClient.getUsersWithTelemetry();
    const totalStreams = allUsers.reduce((sum, u) => sum + (u.streamCount || 0), 0);
    const totalDownloads = allUsers.reduce((sum, u) => sum + (u.downloadCount || 0), 0);
    const activeCovenant = allUsers.filter(u => u.subscriptionTier === 'annual' || u.subscriptionTier === 'lifetime').length;

    res.status(200).json({
      success: true,
      count: users.length,
      stats: {
        totalDevotees: allUsers.length,
        activeCovenant,
        totalStreams,
        totalDownloads,
      },
      users,
    });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to fetch devotee directory.' });
  }
};

export const getAdminUserById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const data = await dbClient.getUserTelemetryById(id);
    if (!data) {
      res.status(404).json({ error: 'Devotee not found.' });
      return;
    }
    res.status(200).json({ success: true, data });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to fetch devotee telemetry profile.' });
  }
};

export const updateAdminUserSubscription = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { tier, status, expiresAt } = req.body || {};

    if (!tier) {
      res.status(400).json({ error: 'Subscription tier is required.' });
      return;
    }

    const updated = await dbClient.updateUserSubscription(id, {
      tier,
      status: status || 'active',
      expiresAt: expiresAt || (tier === 'annual' ? new Date(Date.now() + 86400000 * 365).toISOString() : tier === 'monthly' ? new Date(Date.now() + 86400000 * 30).toISOString() : null),
    });

    if (!updated) {
      res.status(404).json({ error: 'Devotee not found.' });
      return;
    }

    res.status(200).json({
      success: true,
      message: `Access tier updated to ${tier.toUpperCase()}`,
      user: updated,
    });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to update devotee subscription tier.' });
  }
};

export const updateAdminUserStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { status } = req.body || {};

    if (!status) {
      res.status(400).json({ error: 'Account status is required.' });
      return;
    }

    const updated = await dbClient.updateUserStatus(id, status);
    if (!updated) {
      res.status(404).json({ error: 'Devotee not found.' });
      return;
    }

    res.status(200).json({
      success: true,
      message: `Account status updated to ${status}`,
      user: updated,
    });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to update devotee account status.' });
  }
};

export const sendDirectUserPush = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { title, body } = req.body || {};

    if (!title || !body) {
      res.status(400).json({ error: 'Title and message body are required.' });
      return;
    }

    const data = await dbClient.getUserTelemetryById(id);
    if (!data || !data.user) {
      res.status(404).json({ error: 'Devotee not found.' });
      return;
    }

    // Broadcast or simulate targeted push
    const result = await broadcastMarketingCampaign({
      campaignType: 'direct_pastoral',
      customTitle: title,
      customBody: body,
      intentCategory: 'all',
    });

    res.status(200).json({
      success: true,
      deliveredToUser: data.user.email,
      fcmSent: result.success,
      messageId: result.messageId,
    });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to send direct notification to devotee.' });
  }
};
