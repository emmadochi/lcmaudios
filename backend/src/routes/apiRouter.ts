import { Router } from 'express';
import { register, login, getMe } from '../controllers/authController';
import { getTracks, getTrackById, getLyrics } from '../controllers/trackController';
import { getNotes, createNote } from '../controllers/noteController';
import { logTelemetry } from '../controllers/telemetryController';
import {
  initializePayment,
  verifyPayment,
  handleWebhook,
  getPartnerLedgerAdmin,
} from '../controllers/paymentController';
import {
  uploadMedia,
  createTrackAdmin,
  updateTrackAdmin,
  deleteTrackAdmin,
  getAnalyticsAdmin,
  getCategoriesAdmin,
  createCategoryAdmin,
  updateCategoryAdmin,
  deleteCategoryAdmin,
} from '../controllers/adminController';
import { uploadMediaMiddleware } from '../middleware/upload';

const apiRouter = Router();

// Auth Routes
apiRouter.post('/auth/register', register);
apiRouter.post('/auth/login', login);
apiRouter.get('/auth/me', getMe);

// Paystack Covenant Partner Payments
apiRouter.post('/payments/initialize', initializePayment);
apiRouter.get('/payments/verify/:reference', verifyPayment);
apiRouter.post('/payments/webhook', handleWebhook);
apiRouter.get('/admin/partners/ledger', getPartnerLedgerAdmin);

// Tracks & Intent Discovery Routes
apiRouter.get('/tracks', getTracks);
apiRouter.get('/tracks/:id', getTrackById);
apiRouter.get('/tracks/:id/lyrics', getLyrics);
apiRouter.post(
  '/tracks/upload',
  uploadMediaMiddleware.fields([
    { name: 'audioFile', maxCount: 1 },
    { name: 'artworkFile', maxCount: 1 },
  ]),
  uploadMedia
);

// DRM Telemetry Stream Logging
apiRouter.post('/telemetry', logTelemetry);

// Sermon Notes Routes
apiRouter.get('/notes', getNotes);
apiRouter.post('/notes', createNote);

// Admin Media Upload & Tracks Management Routes
apiRouter.post(
  '/admin/upload',
  uploadMediaMiddleware.fields([
    { name: 'audioFile', maxCount: 1 },
    { name: 'artworkFile', maxCount: 1 },
  ]),
  uploadMedia
);
apiRouter.post('/admin/tracks', createTrackAdmin);
apiRouter.put('/admin/tracks/:id', updateTrackAdmin);
apiRouter.delete('/admin/tracks/:id', deleteTrackAdmin);

// Admin Analytics Dashboard Routes
apiRouter.get('/admin/analytics', getAnalyticsAdmin);

// Intent Categories Routes (Public & Admin)
apiRouter.get('/categories', getCategoriesAdmin);
apiRouter.get('/admin/categories', getCategoriesAdmin);
apiRouter.post('/admin/categories', createCategoryAdmin);
apiRouter.put('/admin/categories/:id', updateCategoryAdmin);
apiRouter.delete('/admin/categories/:id', deleteCategoryAdmin);

export default apiRouter;
