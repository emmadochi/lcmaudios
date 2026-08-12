import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Explore Spiritually',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trending Intent Categories',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildExploreCategoryCard('Morning Devotion', '24 Tracks', Icons.wb_sunny_rounded, AppColors.accentGold),
            _buildExploreCategoryCard('Sanctuary atmosphere', '18 Tracks', Icons.auto_awesome_rounded, AppColors.accentPurple),
            _buildExploreCategoryCard('Warfare Prayers', '30 Tracks', Icons.shield_rounded, AppColors.primary),
            _buildExploreCategoryCard('Bible Study', '15 Tracks', Icons.menu_book_rounded, AppColors.accentCyan),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreCategoryCard(String title, String tracks, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(tracks, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
        ],
      ),
    );
  }
}
