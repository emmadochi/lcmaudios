import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum IntentCategory {
  all,
  morningDevotion,
  deepWorship,
  warfarePrayers,
  studyFocus,
  custom,
}

class SpiritualIntent {
  final String id;
  final String categoryKey;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final int trackCount;

  const SpiritualIntent({
    this.id = '',
    required this.categoryKey,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.trackCount = 0,
  });

  IntentCategory get category {
    switch (categoryKey.toLowerCase().replaceAll(' ', '')) {
      case 'all':
        return IntentCategory.all;
      case 'morningdevotion':
        return IntentCategory.morningDevotion;
      case 'deepworship':
        return IntentCategory.deepWorship;
      case 'warfareprayers':
        return IntentCategory.warfarePrayers;
      case 'studyfocus':
        return IntentCategory.studyFocus;
      default:
        return IntentCategory.custom;
    }
  }

  String get subtitle => description;

  static IconData _parseIcon(String? iconName) {
    if (iconName == null) return Icons.auto_awesome_rounded;
    switch (iconName.toLowerCase()) {
      case 'wb_sunny_rounded':
      case 'sunny':
      case 'sun':
        return Icons.wb_sunny_rounded;
      case 'auto_awesome_rounded':
      case 'sparkles':
      case 'worship':
        return Icons.auto_awesome_rounded;
      case 'shield_rounded':
      case 'shield':
      case 'prayer':
        return Icons.shield_rounded;
      case 'menu_book_rounded':
      case 'book':
      case 'bible':
        return Icons.menu_book_rounded;
      case 'health_and_safety_rounded':
      case 'healing':
      case 'deliverance':
        return Icons.health_and_safety_rounded;
      case 'favorite_rounded':
      case 'heart':
      case 'love':
      case 'relationship':
        return Icons.favorite_rounded;
      case 'payments_rounded':
      case 'tithe':
      case 'giving':
        return Icons.payments_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  static Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return AppColors.primary;
    try {
      String hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  factory SpiritualIntent.fromJson(Map<String, dynamic> json) {
    final key = json['categoryKey'] as String? ?? json['id'] as String? ?? 'general';
    return SpiritualIntent(
      id: json['id'] as String? ?? key,
      categoryKey: key,
      title: json['title'] as String? ?? 'Spiritual Category',
      description: json['description'] as String? ?? '',
      icon: _parseIcon(json['icon'] as String?),
      accentColor: _parseColor(json['accentColor'] as String?),
      trackCount: (json['trackCount'] as num?)?.toInt() ?? 0,
    );
  }

  static const List<SpiritualIntent> defaultCategories = [
    SpiritualIntent(
      id: 'cat_all',
      categoryKey: 'all',
      title: 'All Content',
      description: 'Explore all music, sermons, and podcasts',
      icon: Icons.grid_view_rounded,
      accentColor: AppColors.primary,
    ),
    SpiritualIntent(
      id: 'cat_1',
      categoryKey: 'morningDevotion',
      title: 'Morning Devotion',
      description: 'Start your day with uplifting praise & scripture',
      icon: Icons.wb_sunny_rounded,
      accentColor: AppColors.accentGold,
    ),
    SpiritualIntent(
      id: 'cat_2',
      categoryKey: 'deepWorship',
      title: 'Deep Worship',
      description: 'Immersive intimate worship & quiet reflection',
      icon: Icons.auto_awesome_rounded,
      accentColor: AppColors.accentPurple,
    ),
    SpiritualIntent(
      id: 'cat_3',
      categoryKey: 'warfarePrayers',
      title: 'Warfare Prayers',
      description: 'High-energy spiritual declarations & prayers',
      icon: Icons.shield_rounded,
      accentColor: AppColors.primary,
    ),
    SpiritualIntent(
      id: 'cat_4',
      categoryKey: 'studyFocus',
      title: 'Bible Study',
      description: 'Calming instrumental devotionals for focus',
      icon: Icons.menu_book_rounded,
      accentColor: AppColors.accentCyan,
    ),
    SpiritualIntent(
      id: 'cat_5',
      categoryKey: 'deliverance',
      title: 'Deliverance & Healing',
      description: 'Faith declarations for divine healing & freedom',
      icon: Icons.health_and_safety_rounded,
      accentColor: Color(0xFF10B981),
    ),
    SpiritualIntent(
      id: 'cat_6',
      categoryKey: 'Faith',
      title: 'Faith',
      description: 'Messages on Faith & Divine Possibilities',
      icon: Icons.auto_awesome_rounded,
      accentColor: Color(0xFF10B981),
    ),
    SpiritualIntent(
      id: 'cat_7',
      categoryKey: 'Relationship And Marriage',
      title: 'Relationship & Marriage',
      description: 'Kingdom principles for love, courtship & marriage',
      icon: Icons.favorite_rounded,
      accentColor: Color(0xFF3B82F6),
    ),
    SpiritualIntent(
      id: 'cat_8',
      categoryKey: 'Tithe',
      title: 'Tithe & Kingdom Wealth',
      description: 'Covenant financial prosperity & stewardship',
      icon: Icons.payments_rounded,
      accentColor: Color(0xFFF59E0B),
    ),
  ];

  static List<SpiritualIntent> get categories => defaultCategories;
}
