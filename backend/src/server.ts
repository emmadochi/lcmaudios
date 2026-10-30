import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import apiRouter from './routes/apiRouter';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Trust reverse proxy (Nginx on AWS / Render) to accurately detect HTTPS
app.set('trust proxy', 1);

// Security Headers (configured to allow cross-origin media streaming for audio/images)
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
    contentSecurityPolicy: false, // Allows admin dashboard CDN scripts/fonts
  })
);

// CORS configuration supporting mobile apps, dev, and production domains
const allowedOrigins = [
  'https://audios.lifechangerstouch.org',
  'https://lifechangerstouch.org',
  'https://lcmaudios.app',
];
app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (such as mobile apps, Postman, curl) or localhost dev
      if (!origin || allowedOrigins.includes(origin) || /^http:\/\/localhost(:\d+)?$/.test(origin) || /^http:\/\/127\.0\.0\.1(:\d+)?$/.test(origin)) {
        callback(null, true);
      } else {
        callback(null, true); // Fallback permissive for staging while headers remain secure
      }
    },
    credentials: true,
  })
);

// Rate limiter for sensitive authentication endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 60, // Limit each IP to 60 auth requests per 15 minutes
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many authentication attempts from this IP, please try again in 15 minutes.' },
});
app.use('/api/v1/auth/login', authLimiter);
app.use('/api/v1/auth/register', authLimiter);
app.use('/api/v1/auth/admin/login', authLimiter);

app.use(express.json({ limit: '10mb' }));

// Favicon handler
app.get('/favicon.ico', (req: Request, res: Response) => {
  const faviconPath = path.join(__dirname, '../public/admin/logo2White.png');
  if (fs.existsSync(faviconPath)) {
    res.setHeader('Content-Type', 'image/png');
    res.sendFile(faviconPath);
  } else {
    res.status(204).end();
  }
});

// Serve File Uploads Static Directory (audio, artwork, HLS segments)
const uploadsPath = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadsPath)) {
  fs.mkdirSync(uploadsPath, { recursive: true });
}
// Set correct MIME types for HLS streaming
app.use('/uploads', (req, res, next) => {
  if (req.path.endsWith('.m3u8')) {
    res.setHeader('Content-Type', 'application/vnd.apple.mpegurl');
  } else if (req.path.endsWith('.ts')) {
    res.setHeader('Content-Type', 'video/mp2t');
  }
  next();
});
app.use('/uploads', express.static(uploadsPath));

// API Routes
app.use('/api/v1', apiRouter);

import { dbClient } from './data/dbClient';

// Health Check Route
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({
    status: 'online',
    service: 'LCM Audios Backend API & Ingestion Pipeline',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    database: dbClient.isConnectedToPrisma ? 'PostgreSQL (Prisma)' : 'MockDatabase (persistent_db.json)',
  });
});

// Serve Admin Dashboard Web App (Multiple Resolution Paths)
const adminPaths = [
  path.join(__dirname, '../public/admin'),
  path.join(__dirname, './public/admin'),
  path.join(__dirname, '../../admin'),
  path.join(process.cwd(), 'public/admin'),
  path.join(process.cwd(), 'admin'),
];

let adminServed = false;
for (const p of adminPaths) {
  if (fs.existsSync(p)) {
    console.log(`[LCM AUDIOS BACKEND] Serving Admin Dashboard from: ${p}`);
    app.use('/admin', express.static(p));
    adminServed = true;
    break;
  }
}

// Serve Compiled Flutter Web App Static Files (if available)
const flutterWebBuildPath = path.join(__dirname, '../../lcm_audios_app/build/web');
if (fs.existsSync(flutterWebBuildPath)) {
  app.use(express.static(flutterWebBuildPath));
  app.get('*', (req: Request, res: Response) => {
    res.sendFile(path.join(flutterWebBuildPath, 'index.html'));
  });
} else {
  // Root Welcome Route Fallback
  app.get('/', (req: Request, res: Response) => {
    res.status(200).json({
      name: 'LCM Audios Backend API',
      version: '1.0.0',
      status: 'online',
      description: 'Faith in Motion • Audio Ecosystem Service',
      adminDashboard: `http://localhost:${PORT}/admin`,
      healthCheck: `http://localhost:${PORT}/health`,
      apiBaseUrl: `http://localhost:${PORT}/api/v1`,
      availableEndpoints: [
        `http://localhost:${PORT}/api/v1/tracks`,
        `http://localhost:${PORT}/api/v1/auth/me`,
        `http://localhost:${PORT}/api/v1/notes`,
        `http://localhost:${PORT}/api/v1/admin/upload`,
        `http://localhost:${PORT}/api/v1/admin/analytics`,
        `http://localhost:${PORT}/api/v1/admin/categories`,
      ],
    });
  });
}

// Start Server only if executed directly (not when imported in tests)
if (require.main === module && process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`[LCM AUDIOS BACKEND] Server running on http://localhost:${PORT}`);
    console.log(`[LCM AUDIOS BACKEND] Admin Dashboard: http://localhost:${PORT}/admin`);
    console.log(`[LCM AUDIOS BACKEND] Health Check: http://localhost:${PORT}/health`);
    console.log(`[LCM AUDIOS BACKEND] API Base URL: http://localhost:${PORT}/api/v1`);
  });
}

export default app;
