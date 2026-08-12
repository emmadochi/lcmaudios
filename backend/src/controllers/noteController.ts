import { Request, Response } from 'express';
import { MockDatabase } from '../data/mockDatabase';
import { SermonNote } from '../models/types';

export const getNotes = async (req: Request, res: Response): Promise<void> => {
  try {
    const { trackId, userId } = req.query;
    const db = MockDatabase.getInstance();

    let result = db.notes;

    if (trackId && typeof trackId === 'string') {
      result = result.filter((n) => n.trackId === trackId);
    }

    if (userId && typeof userId === 'string') {
      result = result.filter((n) => n.userId === userId);
    }

    res.status(200).json({
      count: result.length,
      notes: result,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch sermon notes.' });
  }
};

export const createNote = async (req: Request, res: Response): Promise<void> => {
  try {
    const { trackId, userId, timestampSeconds, noteText } = req.body;

    if (!trackId || !userId || timestampSeconds === undefined || !noteText) {
      res.status(400).json({ error: 'trackId, userId, timestampSeconds, and noteText are required.' });
      return;
    }

    const newNote: SermonNote = {
      id: `note_${Date.now()}`,
      userId,
      trackId,
      timestampSeconds: Number(timestampSeconds),
      noteText: noteText.trim(),
      createdAt: new Date().toISOString(),
    };

    const db = MockDatabase.getInstance();
    db.notes.push(newNote);

    res.status(201).json({
      message: 'Sermon note anchored to timestamp successfully.',
      note: newNote,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create sermon note.' });
  }
};
