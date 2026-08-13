import { Request, Response } from 'express';
import { dbClient } from '../data/dbClient';

export const getNotes = async (req: Request, res: Response): Promise<void> => {
  try {
    const { trackId, userId } = req.query;
    let notes = await dbClient.getNotes(userId as string);

    if (trackId && typeof trackId === 'string') {
      notes = notes.filter((n) => n.trackId === trackId);
    }

    res.status(200).json({
      count: notes.length,
      notes,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch sermon notes.' });
  }
};

export const createNote = async (req: Request, res: Response): Promise<void> => {
  try {
    const { trackId, userId, timestampSeconds, noteText } = req.body;

    if (!trackId || timestampSeconds === undefined || !noteText) {
      res.status(400).json({ error: 'trackId, timestampSeconds, and noteText are required.' });
      return;
    }

    const newNote = await dbClient.createNote({
      trackId,
      userId: userId || 'usr_demo_1',
      timestampSeconds: Number(timestampSeconds),
      noteText: noteText.trim(),
    });

    res.status(201).json({
      message: 'Sermon note anchored to timestamp successfully.',
      note: newNote,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create sermon note.' });
  }
};
