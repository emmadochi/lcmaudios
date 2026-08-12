import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum IntentCategory {
  all,
  morningDevotion,
  deepWorship,
  warfarePrayers,
  studyFocus,
}

class SpiritualIntent {
  final IntentCategory category;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  const SpiritualIntent({
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  static const List<SpiritualIntent> categories = [
    SpiritualIntent(
      category: IntentCategory.all,
      title: 'All Content',
      description: 'Explore all music, sermons, and podcasts',
      icon: Icons.grid_view_rounded,
      accentColor: AppColors.primary,
    ),
    SpiritualIntent(
      category: IntentCategory.morningDevotion,
      title: 'Morning Devotion',
      description: 'Start your day with uplifting praise & scripture',
      icon: Icons.wb_sunny_rounded,
      accentColor: AppColors.accentGold,
    ),
    SpiritualIntent(
      category: IntentCategory.deepWorship,
      title: 'Deep Worship',
      description: 'Immersive intimate worship & quiet reflection',
      icon: Icons.auto_awesome_rounded,
      accentColor: AppColors.accentPurple,
    ),
    SpiritualIntent(
      category: IntentCategory.warfarePrayers,
      title: 'Warfare Prayers',
      description: 'High-energy spiritual declarations & prayers',
      icon: Icons.shield_rounded,
      accentColor: AppColors.primary,
    ),
    SpiritualIntent(
      category: IntentCategory.studyFocus,
      title: 'Study Focus',
      description: 'Calming instrumental devotionals for focus',
      icon: Icons.menu_book_rounded,
      accentColor: AppColors.accentCyan,
    ),
  ];
}
