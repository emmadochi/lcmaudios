import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
import apiRouter from './routes/apiRouter';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Serve File Uploads Static Directory
const uploadsPath = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadsPath)) {
  fs.mkdirSync(uploadsPath, { recursive: true });
}
app.use('/uploads', express.static(uploadsPath));

// API Routes
app.use('/api/v1', apiRouter);

// Health Check Route
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({
    status: 'online',
    service: 'LCM Audios Backend API & Ingestion Pipeline',
    timestamp: new Date().toISOString(),
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

// Start Server
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`[LCM AUDIOS BACKEND] Server running on http://localhost:${PORT}`);
    console.log(`[LCM AUDIOS BACKEND] Admin Dashboard: http://localhost:${PORT}/admin`);
    console.log(`[LCM AUDIOS BACKEND] Health Check: http://localhost:${PORT}/health`);
    console.log(`[LCM AUDIOS BACKEND] API Base URL: http://localhost:${PORT}/api/v1`);
  });
}

export default app;
