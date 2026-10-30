import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'lcm_audios_faith_secret_key_2026';

export interface AuthenticatedUser {
  id: string;
  email: string;
  role?: string;
}

export interface AuthenticatedRequest extends Request {
  user?: AuthenticatedUser;
}

/**
 * Middleware to verify a valid JWT Bearer token on incoming requests.
 */
export const verifyToken = (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Access denied. No authorization token provided.' });
      return;
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      res.status(401).json({ error: 'Access denied. Malformed authorization token.' });
      return;
    }

    const decoded = jwt.verify(token, JWT_SECRET) as AuthenticatedUser;
    req.user = decoded;
    next();
  } catch (err: any) {
    res.status(401).json({ error: 'Invalid or expired authorization token.' });
  }
};

/**
 * Middleware that strictly enforces the authenticated user has the 'admin' role.
 */
export const requireAdmin = (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
  verifyToken(req, res, () => {
    if (req.user?.role !== 'admin') {
      res.status(403).json({ error: 'Forbidden. Administrative privileges required.' });
      return;
    }
    next();
  });
};
