import { Request, Response } from 'express';
import { MockDatabase } from '../data/mockDatabase';
import { IntentCategory, MediaType } from '../models/types';

export const getTracks = async (req: Request, res: Response): Promise<void> => {
  try {
    const { intentCategory, mediaType, search } = req.query;
    const db = MockDatabase.getInstance();

    let result = db.tracks;

    if (intentCategory && intentCategory !== 'all') {
      result = result.filter((t) => t.intentCategory === (intentCategory as IntentCategory));
    }

    if (mediaType) {
      result = result.filter((t) => t.mediaType === (mediaType as MediaType));
    }

    if (search && typeof search === 'string') {
      const q = search.toLowerCase();
      result = result.filter(
        (t) => t.title.toLowerCase().includes(q) || t.artist.toLowerCase().includes(q) || t.subgenre.toLowerCase().includes(q)
      );
    }

    res.status(200).json({
      count: result.length,
      tracks: result,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch tracks.' });
  }
};

export const getTrackById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const db = MockDatabase.getInstance();

    const track = db.tracks.find((t) => t.id === id);
    if (!track) {
      res.status(404).json({ error: 'Track not found.' });
      return;
    }

    res.status(200).json({ track });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch track.' });
  }
};

export const getLyrics = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const db = MockDatabase.getInstance();

    const track = db.tracks.find((t) => t.id === id);
    if (!track) {
      res.status(404).json({ error: 'Track not found.' });
      return;
    }

    res.status(200).json({
      trackId: id,
      lyrics: track.lyrics,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch lyrics.' });
  }
};
