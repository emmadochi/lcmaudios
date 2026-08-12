import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // User Avatar & Name
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryGlow,
                    child: Icon(Icons.person_rounded, size: 50, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sarah',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'User progress: 100%',
                    style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 1.0,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildProfileOption('Spiritual Intent Preferences', Icons.tune_rounded),
            _buildProfileOption('Saved Sermon Notes', Icons.note_alt_rounded),
            _buildProfileOption('Audio Streaming Quality (HLS/DASH)', Icons.high_quality_rounded),
            _buildProfileOption('Offline Storage & Downloads', Icons.offline_pin_rounded),
            _buildProfileOption('Sign Out', Icons.logout_rounded, isDanger: true),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(String title, IconData icon, {bool isDanger = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: isDanger ? Colors.redAccent : AppColors.primary),
        title: Text(
          title,
          style: TextStyle(
            color: isDanger ? Colors.redAccent : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
      ),
    );
  }
}
