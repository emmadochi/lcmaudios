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

