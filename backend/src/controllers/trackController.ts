import { Request, Response } from 'express';
import { dbClient } from '../data/dbClient';

export const getTracks = async (req: Request, res: Response): Promise<void> => {
  try {
    const { intentCategory, mediaType, search, page, limit } = req.query;

    if (page !== undefined || limit !== undefined) {
      const pageNum = parseInt(page as string, 10) || 1;
      const limitNum = parseInt(limit as string, 10) || 50;

      const result = await dbClient.getPaginatedTracks({
        intentCategory: intentCategory as string,
        mediaType: mediaType as string,
        search: search as string,
        page: pageNum,
        limit: limitNum,
      });

      res.status(200).json({
        count: result.tracks.length,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        hasMore: result.hasMore,
        tracks: result.tracks,
      });
      return;
    }

    const tracks = await dbClient.getTracks({
      intentCategory: intentCategory as string,
      mediaType: mediaType as string,
      search: search as string,
    });

    res.status(200).json({
      count: tracks.length,
      tracks,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch tracks.' });
  }
};

export const getTrackById = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const track = await dbClient.getTrackById(id);
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
    const track = await dbClient.getTrackById(id);
    if (!track) {
      res.status(404).json({ error: 'Track not found.' });
      return;
    }

    res.status(200).json({
      trackId: id,
      lyrics: track.lyrics || [],
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch lyrics.' });
  }
};
