import { Request, Response } from 'express';
import { dbClient } from '../data/dbClient';

export const logTelemetry = async (req: Request, res: Response): Promise<void> => {
  try {
    const { events } = req.body;

    if (!Array.isArray(events)) {
      res.status(400).json({ error: 'Body parameter "events" must be an array.' });
      return;
    }

    const count = await dbClient.logTelemetry(events);

    res.status(200).json({
      message: `Successfully processed ${count} telemetry stream events.`,
      processedCount: count,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to process DRM telemetry events.' });
  }
};
