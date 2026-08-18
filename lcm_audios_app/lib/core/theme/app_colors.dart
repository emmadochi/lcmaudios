import 'package:flutter/material.dart';

class AppColors {
  // --- Dark Mode Palette (Midnight Vigil) ---
  static const Color background = Color(0xFF0D0F17);
  static const Color surface = Color(0xFF161926);
  static const Color surfaceLight = Color(0xFF202436);
  static const Color glassBorder = Color(0xFF2A2E45);
  static const Color darkCardShadow = Color(0x80000000);

  // --- Light Mode Palette (Daylight Devotion) ---
  static const Color lightBackground = Color(0xFFF6F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFEEF2F8);
  static const Color lightGlassBorder = Color(0xFFE2E8F0);
  static const Color lightCardShadow = Color(0x12000000);

  // --- Accent & Brand Colors (Universal) ---
  static const Color primary = Color(0xFFE63946); // Crimson Red
  static const Color primaryGlow = Color(0x33E63946);
  static const Color primaryLight = Color(0xFFD90429);
  static const Color accentPurple = Color(0xFF8B5CF6); // Worship Purple
  static const Color accentGold = Color(0xFFF59E0B); // Devotional Gold
  static const Color accentCyan = Color(0xFF06B6D4); // Study Cyan
  static const Color secondary = Color(0xFFF59E0B); // Devotional Gold

  // --- Text & Icons (Dark Mode) ---
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // --- Text & Icons (Light Mode) ---
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // --- Status & Badges ---
  static const Color success = Color(0xFF10B981);
  static const Color offlineBadge = Color(0xFF3B82F6);
  static const Color cardShadow = Color(0x80000000);

  // =========================================================================
  // Context-Aware Helpers (Adapts automatically based on active ThemeMode)
  // =========================================================================

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color bg(BuildContext context) =>
      isDarkMode(context) ? background : lightBackground;

  static Color card(BuildContext context) =>
      isDarkMode(context) ? surface : lightSurface;

  static Color cardAlt(BuildContext context) =>
      isDarkMode(context) ? surfaceLight : lightSurfaceLight;

  static Color border(BuildContext context) =>
      isDarkMode(context) ? glassBorder : lightGlassBorder;

  static Color text(BuildContext context) =>
      isDarkMode(context) ? textPrimary : lightTextPrimary;

  static Color subtext(BuildContext context) =>
      isDarkMode(context) ? textSecondary : lightTextSecondary;

  static Color muted(BuildContext context) =>
      isDarkMode(context) ? textMuted : lightTextMuted;

  static Color shadow(BuildContext context) =>
      isDarkMode(context) ? darkCardShadow : lightCardShadow;
}
