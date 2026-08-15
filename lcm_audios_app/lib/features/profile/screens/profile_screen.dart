import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio_player_service.dart';
import '../../auth/screens/auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditNameDialog(BuildContext context, AudioPlayerService playerService) {
    final controller = TextEditingController(text: playerService.userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Profile Name', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              playerService.setUserName(controller.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile name updated!'), backgroundColor: AppColors.primary),
              );
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final favoritesCount = playerService.allTracks.where((t) => t.isFavorite).length;
        final downloadedCount = playerService.allTracks.where((t) => t.isDownloaded).length;
        final notesCount = playerService.allTracks.fold(0, (sum, t) => sum + t.notes.length);

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
                // User Avatar & Dynamic Name Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.primaryGlow,
                            child: Icon(Icons.person_rounded, size: 44, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            playerService.userName,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                            onPressed: () => _showEditNameDialog(context, playerService),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'User progress: ${playerService.userProgressPercentage}%',
                        style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: playerService.userProgress,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Dynamic Stats Row
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Favorites', '$favoritesCount', Icons.favorite_rounded, AppColors.primary)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatCard('Offline Tracks', '$downloadedCount', Icons.download_done_rounded, AppColors.offlineBadge)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatCard('Notes Pinned', '$notesCount', Icons.edit_note_rounded, AppColors.accentGold)),
                  ],
                ),
                const SizedBox(height: 20),

                _buildProfileOption('Spiritual Intent Preferences', Icons.tune_rounded, () {}),
                _buildProfileOption('Saved Sermon Notes ($notesCount)', Icons.note_alt_rounded, () {}),
                _buildProfileOption('Audio Streaming Quality (HLS/DASH)', Icons.high_quality_rounded, () {}),
                _buildProfileOption('Offline Storage & Downloads ($downloadedCount)', Icons.offline_pin_rounded, () {}),
                _buildProfileOption('Sign Out', Icons.logout_rounded, () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
                }, isDanger: true),
                const SizedBox(height: 24),
                // Brand Footer
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo2White.png',
                        height: 38,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Version 1.0.0 • Kingdom Audio Sanctuary',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildProfileOption(String title, IconData icon, VoidCallback onTap, {bool isDanger = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: ListTile(
        onTap: onTap,
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
