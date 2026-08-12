import { Request, Response } from 'express';
import { MockDatabase } from '../data/mockDatabase';
import { Track, LyricLine, IntentCategory, MediaType, CategoryItem } from '../models/types';

export const uploadMedia = (req: Request, res: Response): void => {
  try {
    const files = req.files as { [fieldname: string]: Express.Multer.File[] };

    let audioUrl = '';
    let albumArtUrl = '';

    if (files && files['audioFile'] && files['audioFile'][0]) {
      audioUrl = `http://localhost:5000/uploads/audio/${files['audioFile'][0].filename}`;
    }

    if (files && files['artworkFile'] && files['artworkFile'][0]) {
      albumArtUrl = `http://localhost:5000/uploads/artwork/${files['artworkFile'][0].filename}`;
    }

    res.status(200).json({
      message: 'Files uploaded successfully.',
      audioUrl,
      albumArtUrl,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to upload media files.' });
  }
};

export const createTrackAdmin = (req: Request, res: Response): void => {
  try {
    const { title, artist, audioUrl, albumArtUrl, duration, subgenre, intentCategory, mediaType, lyrics } = req.body;

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
      playCount: 1,
      lyrics: parsedLyrics,
      createdAt: new Date().toISOString(),
    };

    const db = MockDatabase.getInstance();
    db.tracks.unshift(newTrack);

    res.status(201).json({
      message: 'Track ingested successfully and published to live endpoints.',
      track: newTrack,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create track.' });
  }
};

export const deleteTrackAdmin = (req: Request, res: Response): void => {
  try {
    const { id } = req.params;
    const db = MockDatabase.getInstance();

    const idx = db.tracks.findIndex((t) => t.id === id);
    if (idx === -1) {
      res.status(404).json({ error: 'Track not found.' });
      return;
    }

    const deleted = db.tracks.splice(idx, 1);
    res.status(200).json({ message: 'Track deleted successfully.', deletedTrack: deleted[0] });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete track.' });
  }
};

// --- ANALYTICS CONTROLLER ---
export const getAnalyticsAdmin = (req: Request, res: Response): void => {
  try {
    const db = MockDatabase.getInstance();
    const tracks = db.tracks;

    let totalStreams = 0;
    const categoryCounts: { [key: string]: number } = {};

    tracks.forEach((t) => {
      const plays = t.playCount || 100;
      totalStreams += plays;
      categoryCounts[t.intentCategory] = (categoryCounts[t.intentCategory] || 0) + plays;
    });

    const topCategories = Object.keys(categoryCounts).map((cat) => ({
      category: cat,
      count: categoryCounts[cat],
      percentage: totalStreams > 0 ? Math.round((categoryCounts[cat] / totalStreams) * 100) : 0,
    }));

    const sortedTracks = [...tracks].sort((a, b) => (b.playCount || 0) - (a.playCount || 0)).slice(0, 5);

    res.status(200).json({
      analytics: {
        totalStreams: totalStreams + 4890, // Include baseline streams
        activeListeners: 1240,
        totalListeningHours: 854,
        totalNotesTaken: db.notes.length + 320,
        topCategories,
        topTracks: sortedTracks,
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch analytics.' });
  }
};

// --- CATEGORY MANAGEMENT CONTROLLERS ---
export const getCategoriesAdmin = (req: Request, res: Response): void => {
  try {
    const db = MockDatabase.getInstance();
    res.status(200).json({ categories: db.categories });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch categories.' });
  }
};

export const createCategoryAdmin = (req: Request, res: Response): void => {
  try {
    const { title, description, icon, accentColor, categoryKey } = req.body;

    if (!title || !categoryKey) {
      res.status(400).json({ error: 'title and categoryKey are required fields.' });
      return;
    }

    const db = MockDatabase.getInstance();
    const newCategory: CategoryItem = {
      id: `cat_${Date.now()}`,
      categoryKey: categoryKey.trim(),
      title: title.trim(),
      description: description ? description.trim() : '',
      icon: icon || 'auto_awesome_rounded',
      accentColor: accentColor || '#E63946',
      trackCount: 0,
      isActive: true,
      createdAt: new Date().toISOString(),
    };

    db.categories.push(newCategory);
    res.status(201).json({ message: 'Category created successfully.', category: newCategory });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create category.' });
  }
};

export const updateCategoryAdmin = (req: Request, res: Response): void => {
  try {
    const { id } = req.params;
    const { title, description, icon, accentColor, isActive } = req.body;

    const db = MockDatabase.getInstance();
    const cat = db.categories.find((c) => c.id === id);

    if (!cat) {
      res.status(404).json({ error: 'Category not found.' });
      return;
    }

    if (title !== undefined) cat.title = title.trim();
    if (description !== undefined) cat.description = description.trim();
    if (icon !== undefined) cat.icon = icon;
    if (accentColor !== undefined) cat.accentColor = accentColor;
    if (isActive !== undefined) cat.isActive = Boolean(isActive);

    res.status(200).json({ message: 'Category updated successfully.', category: cat });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update category.' });
  }
};

export const deleteCategoryAdmin = (req: Request, res: Response): void => {
  try {
    const { id } = req.params;
    const db = MockDatabase.getInstance();

    const idx = db.categories.findIndex((c) => c.id === id);
    if (idx === -1) {
      res.status(404).json({ error: 'Category not found.' });
      return;
    }

    const deleted = db.categories.splice(idx, 1);
    res.status(200).json({ message: 'Category deleted successfully.', category: deleted[0] });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete category.' });
  }
};
