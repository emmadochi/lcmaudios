import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/spiritual_intent.dart';
import '../../../services/audio_player_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final filteredTracks = playerService.filteredTracks;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.church_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 8),
                const Text(
                  'LCM AUDIOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white70, size: 24),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.account_circle_outlined, color: Colors.white70, size: 24),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Greeting & Progress Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Good Morning, Sarah 🙏',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text(
                            'User progress: ',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const Text(
                            '100%',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: const LinearProgressIndicator(
                                value: 1.0,
                                minHeight: 5,
                                backgroundColor: AppColors.surfaceLight,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Explore Spiritually Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Explore Spiritually',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Intent-Driven Spiritual Playlists',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 16),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4 Large Horizontal Intent Playlists Cards
                SizedBox(
                  height: 210,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildIntentCard(
                        context,
                        title: 'MORNING\nDEVOTION',
                        subtitle: 'MORNING\nDEVOTION',
                        tracksCount: '24 Tracks',
                        icon: Icons.bookmark_add_rounded,
                        imageUrl: 'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?auto=format&fit=crop&w=800&q=80',
                        category: IntentCategory.morningDevotion,
                        playerService: playerService,
                      ),
                      _buildIntentCard(
                        context,
                        title: 'DEEP\nWORSHIP',
                        subtitle: 'Sanctuary\natmosphere',
                        tracksCount: '18 Tracks',
                        icon: Icons.back_hand_rounded,
                        imageUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=800&q=80',
                        category: IntentCategory.deepWorship,
                        playerService: playerService,
                      ),
                      _buildIntentCard(
                        context,
                        title: 'WARFARE\nPRAYERS',
                        subtitle: 'WARFARE\nPRAYERS',
                        tracksCount: '30 Tracks',
                        icon: Icons.shield_rounded,
                        imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=800&q=80',
                        category: IntentCategory.warfarePrayers,
                        playerService: playerService,
                      ),
                      _buildIntentCard(
                        context,
                        title: 'BIBLE\nSTUDY',
                        subtitle: 'BIBLE\nSTUDY',
                        tracksCount: '15 Tracks',
                        icon: Icons.menu_book_rounded,
                        imageUrl: 'https://images.unsplash.com/photo-1520523839897-bd0b52f945a0?auto=format&fit=crop&w=800&q=80',
                        category: IntentCategory.studyFocus,
                        playerService: playerService,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Featured Media Streams Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        playerService.selectedIntent == IntentCategory.all
                            ? 'Featured Faith Streams'
                            : '${playerService.selectedIntent.name.toUpperCase()} STREAMS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${filteredTracks.length} Tracks',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Media Stream List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: filteredTracks.length,
                  itemBuilder: (ctx, index) {
                    final track = filteredTracks[index];
                    final isCurrentPlaying = (playerService.currentTrack?.id == track.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isCurrentPlaying ? AppColors.surfaceLight : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrentPlaying ? AppColors.primary : AppColors.glassBorder,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: track.albumArtUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrentPlaying ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${track.artist} • ${track.subgenre}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            isCurrentPlaying && playerService.isPlaying
                                ? Icons.pause_circle_rounded
                                : Icons.play_circle_fill_rounded,
                            color: AppColors.primary,
                            size: 32,
                          ),
                          onPressed: () {
                            if (isCurrentPlaying) {
                              playerService.togglePlayPause();
                            } else {
                              playerService.playTrack(track);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 120), // Bottom padding for floating player card
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntentCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String tracksCount,
    required IconData icon,
    required String imageUrl,
    required IntentCategory category,
    required AudioPlayerService playerService,
  }) {
    final isSelected = (playerService.selectedIntent == category);

    return GestureDetector(
      onTap: () => playerService.setIntentFilter(category),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isSelected
                ? [AppColors.primary, const Color(0xFF6B0F1A)]
                : [AppColors.surface, const Color(0xFF1E2130)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.glassBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGlow.withValues(alpha: 0.6),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Artwork Image Container with badge icon
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tracksCount,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
