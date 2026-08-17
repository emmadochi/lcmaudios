import { Request, Response } from 'express';
import { dbClient } from '../data/dbClient';

export const getMinisters = async (req: Request, res: Response): Promise<void> => {
  try {
    const ministers = await dbClient.getMinisters();
    res.status(200).json({ count: ministers.length, ministers });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch ministers.' });
  }
};

export const getMinisterById = async (req: Request, res: Response): Promise<void> => {
  try {
    const minister = await dbClient.getMinisterById(req.params.id);
    if (!minister) {
      res.status(404).json({ error: 'Minister not found.' });
      return;
    }
    res.status(200).json({ minister });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch minister details.' });
  }
};

export const createMinisterAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { name, role, avatarUrl, bio } = req.body;
    if (!name || !role) {
      res.status(400).json({ error: 'Minister name and role are required.' });
      return;
    }

    const defaultAvatar = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80';
    const newMinister = await dbClient.createMinister({
      name,
      role,
      avatarUrl: avatarUrl || defaultAvatar,
      bio: bio || '',
    });

    res.status(201).json({
      message: 'Minister created successfully.',
      minister: newMinister,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create minister.' });
  }
};

export const updateMinisterAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const updated = await dbClient.updateMinister(req.params.id, req.body);
    if (!updated) {
      res.status(404).json({ error: 'Minister not found.' });
      return;
    }
    res.status(200).json({
      message: 'Minister updated successfully.',
      minister: updated,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update minister.' });
  }
};

export const deleteMinisterAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const deleted = await dbClient.deleteMinister(req.params.id);
    if (!deleted) {
      res.status(404).json({ error: 'Minister not found.' });
      return;
    }
    res.status(200).json({ message: 'Minister deleted successfully.' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete minister.' });
  }
};
