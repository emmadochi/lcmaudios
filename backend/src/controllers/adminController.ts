import { Request, Response } from 'express';
import { dbClient } from '../data/dbClient';
import { HlsTranscoder } from '../services/hlsTranscoder';
import { S3StorageService } from '../services/s3StorageService';
import { broadcastSermonNotification } from '../services/fcmService';
import { Track, LyricLine, IntentCategory, MediaType, CategoryItem } from '../models/types';
import path from 'path';

export const uploadMedia = async (req: Request, res: Response): Promise<void> => {
  try {
    const files = req.files as { [fieldname: string]: Express.Multer.File[] };

    // Derive public base URL from the incoming request so it works both locally and on Render
    const serverBaseUrl = process.env.SERVER_BASE_URL ||
      `${req.protocol}://${req.get('host')}`;

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
    const users = await dbClient.getUsers();

    let totalStreams = 0;
    let totalListeningSeconds = 0;
    const categoryCounts: { [key: string]: number } = {};

    tracks.forEach((t) => {
      const plays = t.playCount || 0;
      totalStreams += plays;
      totalListeningSeconds += plays * (t.duration || 300);
      const catKey = t.categoryKey || t.intentCategory || 'Other';
      categoryCounts[catKey] = (categoryCounts[catKey] || 0) + plays;
    });

    const topCategories = Object.keys(categoryCounts).map((cat) => ({
      category: cat,
      count: categoryCounts[cat],
      percentage: totalStreams > 0 ? Math.round((categoryCounts[cat] / totalStreams) * 100) : 0,
    }));

    const sortedTracks = [...tracks].sort((a, b) => (b.playCount || 0) - (a.playCount || 0)).slice(0, 10);
    const totalListeningHours = Math.round(totalListeningSeconds / 3600);

    res.status(200).json({
      analytics: {
        totalStreams: totalStreams,
        activeListeners: users.length,
        totalListeningHours: totalListeningHours > 0 ? totalListeningHours : Math.round(totalStreams * 0.2),
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
