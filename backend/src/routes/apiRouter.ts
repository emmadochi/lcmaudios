import { Router } from 'express';
import { register, login, getMe, googleAuth, forgotPassword, resetPassword, updateProfile, adminLogin, verifyAdminSession } from '../controllers/authController';
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
  testNotificationAdmin,
  sendMarketingCampaignAdmin,
  getAdminUsers,
  getAdminUserById,
  updateAdminUserSubscription,
  updateAdminUserStatus,
  sendDirectUserPush,
  syncPodcastAdmin,
} from '../controllers/adminController';
import { uploadMediaMiddleware } from '../middleware/upload';
import { verifyToken, requireAdmin } from '../middleware/authMiddleware';

const apiRouter = Router();

// Devotee & User Management Routes (Admin Protected)
apiRouter.get('/admin/users', requireAdmin, getAdminUsers);
apiRouter.get('/admin/users/:id', requireAdmin, getAdminUserById);
apiRouter.patch('/admin/users/:id/subscription', requireAdmin, updateAdminUserSubscription);
apiRouter.patch('/admin/users/:id/status', requireAdmin, updateAdminUserStatus);
apiRouter.post('/admin/users/:id/push', requireAdmin, sendDirectUserPush);

// Admin Authentication & Session Verification Routes
apiRouter.post('/auth/admin/login', adminLogin);
apiRouter.get('/auth/admin/verify', verifyAdminSession);

// Push Notifications & Growth Marketing Routes (Admin Protected)
apiRouter.post('/admin/notifications/test', requireAdmin, testNotificationAdmin);
apiRouter.get('/admin/notifications/test', requireAdmin, testNotificationAdmin);
apiRouter.post('/admin/marketing/broadcast', requireAdmin, sendMarketingCampaignAdmin);

// Auth Routes (User Mobile App)
apiRouter.post('/auth/register', register);
apiRouter.post('/auth/login', login);
apiRouter.post('/auth/google', googleAuth);
apiRouter.post('/auth/forgot-password', forgotPassword);
apiRouter.post('/auth/reset-password', resetPassword);
apiRouter.get('/auth/me', verifyToken, getMe);
apiRouter.patch('/auth/profile', verifyToken, updateProfile);
apiRouter.post('/auth/profile', verifyToken, updateProfile);

// Paystack Covenant Partner Payments
apiRouter.post('/payments/initialize', initializePayment);
apiRouter.get('/payments/verify/:reference', verifyPayment);
apiRouter.post('/payments/webhook', handleWebhook);
apiRouter.get('/admin/partners/ledger', requireAdmin, getPartnerLedgerAdmin);

// Tracks & Intent Discovery Routes
apiRouter.get('/tracks', getTracks);
apiRouter.get('/tracks/:id', getTrackById);
apiRouter.get('/tracks/:id/lyrics', getLyrics);
apiRouter.post(
  '/tracks/upload',
  requireAdmin,
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

// Admin Media Upload & Tracks Management Routes (Admin Protected)
apiRouter.post(
  '/admin/upload',
  requireAdmin,
  uploadMediaMiddleware.fields([
    { name: 'audioFile', maxCount: 1 },
    { name: 'artworkFile', maxCount: 1 },
  ]),
  uploadMedia
);
apiRouter.post('/admin/tracks', requireAdmin, createTrackAdmin);
apiRouter.put('/admin/tracks/:id', requireAdmin, updateTrackAdmin);
apiRouter.delete('/admin/tracks/:id', requireAdmin, deleteTrackAdmin);
apiRouter.post('/admin/podcast/sync', requireAdmin, syncPodcastAdmin);

// Admin Analytics Dashboard Routes (Admin Protected)
apiRouter.get('/admin/analytics', requireAdmin, getAnalyticsAdmin);

// Intent Categories Routes (Public & Admin Protected)
apiRouter.get('/categories', getCategoriesAdmin);
apiRouter.get('/admin/categories', requireAdmin, getCategoriesAdmin);
apiRouter.post('/admin/categories', requireAdmin, createCategoryAdmin);
apiRouter.put('/admin/categories/:id', requireAdmin, updateCategoryAdmin);
apiRouter.delete('/admin/categories/:id', requireAdmin, deleteCategoryAdmin);

// Ministers & Preachers Routes (Public & Admin Protected)
import {
  getMinisters,
  getMinisterById,
  createMinisterAdmin,
  updateMinisterAdmin,
  deleteMinisterAdmin,
} from '../controllers/ministerController';

apiRouter.get('/ministers', getMinisters);
apiRouter.get('/ministers/:id', getMinisterById);
apiRouter.get('/admin/ministers', requireAdmin, getMinisters);
apiRouter.post('/admin/ministers', requireAdmin, createMinisterAdmin);
apiRouter.put('/admin/ministers/:id', requireAdmin, updateMinisterAdmin);
apiRouter.delete('/admin/ministers/:id', requireAdmin, deleteMinisterAdmin);

export default apiRouter;
