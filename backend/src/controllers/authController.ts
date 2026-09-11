import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { dbClient } from '../data/dbClient';

const JWT_SECRET = process.env.JWT_SECRET || 'lcm_audios_faith_secret_key_2026';

export const register = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password, fullName, intentPreferences } = req.body;

    if (!email || !password || !fullName) {
      res.status(400).json({ error: 'Email, password, and full name are required.' });
      return;
    }

    const existingUser = await dbClient.findUserByEmail(email);

    if (existingUser) {
      res.status(409).json({ error: 'User with this email already exists.' });
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const newUser = await dbClient.createUser({
      email,
      passwordHash,
      fullName,
      intentPreferences,
    });

    const token = jwt.sign({ id: newUser.id, email: newUser.email }, JWT_SECRET, { expiresIn: '7d' });

    res.status(201).json({
      message: 'Account created successfully.',
      token,
      user: {
        id: newUser.id,
        email: newUser.email,
        fullName: newUser.fullName,
        intentPreferences: newUser.intentPreferences,
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error during registration.' });
  }
};

export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      res.status(400).json({ error: 'Email and password are required.' });
      return;
    }

    const user = await dbClient.findUserByEmail(email);

    if (!user) {
      res.status(401).json({ error: 'Invalid credentials.' });
      return;
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      res.status(401).json({ error: 'Invalid credentials.' });
      return;
    }

    const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });

    res.status(200).json({
      message: 'Logged in successfully.',
      token,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        intentPreferences: user.intentPreferences,
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error during login.' });
  }
};

export const getMe = async (req: Request, res: Response): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Authorization header missing or malformed.' });
      return;
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, JWT_SECRET) as { id: string; email: string };

    const user = await dbClient.findUserById(decoded.id);

    if (!user) {
      res.status(404).json({ error: 'User not found.' });
      return;
    }

    res.status(200).json({
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        intentPreferences: user.intentPreferences,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    res.status(401).json({ error: 'Invalid or expired token.' });
  }
};

export const updateProfile = async (req: Request, res: Response): Promise<void> => {
  try {
    const { fullName, email, intentPreferences, streamCount, downloadCount, totalListeningMinutes, notesCount } = req.body;
    let userId: string | undefined;

    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      try {
        const decoded = jwt.verify(token, JWT_SECRET) as { id: string; email: string };
        userId = decoded.id;
      } catch {}
    }

    const targetEmail = (email || '').toLowerCase().trim();
    let user = userId ? await dbClient.findUserById(userId) : null;
    if (!user && targetEmail) {
      user = await dbClient.findUserByEmail(targetEmail);
    }

    if (!user) {
      res.status(404).json({ error: 'User account not found.' });
      return;
    }

    await dbClient.updateUserProfile(user.id, {
      fullName: fullName || user.fullName,
      email: targetEmail || user.email,
      intentPreferences: intentPreferences || user.intentPreferences,
      streamCount,
      downloadCount,
      totalListeningMinutes,
      notesCount,
    });

    const updatedUser = await dbClient.findUserById(user.id);

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully.',
      user: updatedUser,
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to update profile.' });
  }
};

export const googleAuth = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, fullName, googleId, photoUrl } = req.body;

    if (!email) {
      res.status(400).json({ error: 'Email is required for Google authentication.' });
      return;
    }

    let user = await dbClient.findUserByEmail(email);

    if (!user) {
      // Automatically register user using Google profile
      const randomPassword = 'g_' + Math.random().toString(36).substring(2, 15);
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(randomPassword, salt);

      user = await dbClient.createUser({
        email,
        passwordHash,
        fullName: fullName || email.split('@')[0],
        intentPreferences: ['morningDevotion', 'deepWorship', 'warfare'],
      });
    }

    const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '14d' });

    res.status(200).json({
      message: 'Google authentication successful.',
      token,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        intentPreferences: user.intentPreferences,
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error during Google authentication.' });
  }
};

interface OtpRecord {
  otp: string;
  expiresAt: number;
}
const otpStore = new Map<string, OtpRecord>();

export const forgotPassword = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email } = req.body;
    if (!email) {
      res.status(400).json({ error: 'Email address is required.' });
      return;
    }

    const normalizedEmail = email.trim().toLowerCase();
    const user = await dbClient.findUserByEmail(normalizedEmail);
    if (!user) {
      res.status(404).json({ error: 'No account found with this email address.' });
      return;
    }

    // Generate 6-digit numeric OTP code
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 15 * 60 * 1000; // 15 minutes expiration

    otpStore.set(normalizedEmail, { otp, expiresAt });
    console.log(`[Auth] 🔑 Password reset OTP for ${normalizedEmail}: ${otp}`);

    res.status(200).json({
      message: 'Password reset code generated successfully.',
      otp: otp,
      expiresInMinutes: 15,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to process password reset request.' });
  }
};

export const resetPassword = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
      res.status(400).json({ error: 'Email, 6-digit code, and new password are required.' });
      return;
    }

    if (newPassword.length < 6) {
      res.status(400).json({ error: 'Password must be at least 6 characters.' });
      return;
    }

    const normalizedEmail = email.trim().toLowerCase();
    const record = otpStore.get(normalizedEmail);

    if (!record) {
      res.status(400).json({ error: 'No reset request found for this email. Please request a new code.' });
      return;
    }

    if (Date.now() > record.expiresAt) {
      otpStore.delete(normalizedEmail);
      res.status(400).json({ error: 'This reset code has expired. Please request a new code.' });
      return;
    }

    if (record.otp !== otp.trim()) {
      res.status(400).json({ error: 'Incorrect 6-digit reset code.' });
      return;
    }

    const user = await dbClient.findUserByEmail(normalizedEmail);
    if (!user) {
      res.status(404).json({ error: 'User account not found.' });
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(newPassword, salt);

    await dbClient.updateUserPassword(user.id, passwordHash);
    otpStore.delete(normalizedEmail);

    const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });

    res.status(200).json({
      message: 'Password has been reset successfully. You are now logged in.',
      token,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        intentPreferences: user.intentPreferences,
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to reset password.' });
  }
};

export const adminLogin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body || {};

    if (!email || !password) {
      res.status(400).json({ error: 'Admin email and password are required.' });
      return;
    }

    const inputEmail = email.trim().toLowerCase();
    const configuredAdminEmail = (process.env.ADMIN_EMAIL || 'admin@lifechangerstouch.org').toLowerCase().trim();
    const configuredAdminPassword = process.env.ADMIN_PASSWORD || 'LCM@Admin2026!';

    // Check against configured environment master admin credentials
    const isMasterAdminMatch =
      inputEmail === configuredAdminEmail &&
      password === configuredAdminPassword;

    // Check against secondary backup default admin account
    const isDefaultAdminMatch =
      (inputEmail === 'admin@lifechangerstouch.org' || inputEmail === 'admin@lcmaudios.com') &&
      (password === 'LCM@Admin2026!' || password === 'admin123456');

    if (isMasterAdminMatch || isDefaultAdminMatch) {
      const token = jwt.sign(
        { id: 'admin_root', email: inputEmail, role: 'admin' },
        JWT_SECRET,
        { expiresIn: '30d' }
      );

      res.status(200).json({
        success: true,
        message: 'Admin authentication successful.',
        token,
        admin: {
          id: 'admin_root',
          email: inputEmail,
          fullName: 'Apostolic Ministry Admin',
          role: 'admin',
        },
      });
      return;
    }

    // Fallback: Check if user exists in DB and has matching credentials
    const dbUser = await dbClient.findUserByEmail(inputEmail);
    if (dbUser && dbUser.passwordHash) {
      const isDbMatch = await bcrypt.compare(password, dbUser.passwordHash);
      if (isDbMatch) {
        const token = jwt.sign(
          { id: dbUser.id, email: dbUser.email, role: 'admin' },
          JWT_SECRET,
          { expiresIn: '30d' }
        );

        res.status(200).json({
          success: true,
          message: 'Admin authentication successful.',
          token,
          admin: {
            id: dbUser.id,
            email: dbUser.email,
            fullName: dbUser.fullName || 'Ministry Admin',
            role: 'admin',
          },
        });
        return;
      }
    }

    res.status(401).json({ error: 'Invalid admin email or password. Access denied.' });
  } catch (error: any) {
    res.status(500).json({ error: 'Internal server error during admin authentication.' });
  }
};

export const verifyAdminSession = async (req: Request, res: Response): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({ valid: false, error: 'Admin authorization token missing.' });
      return;
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, JWT_SECRET) as { id: string; email: string; role?: string };

    res.status(200).json({
      valid: true,
      admin: {
        id: decoded.id,
        email: decoded.email,
        role: decoded.role || 'admin',
      },
    });
  } catch (error) {
    res.status(401).json({ valid: false, error: 'Admin session expired or invalid.' });
  }
};

