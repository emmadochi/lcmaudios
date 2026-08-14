import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/spiritual_intent.dart';
import '../../../core/models/audio_track.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio_player_service.dart';

class IntentPlaylistScreen extends StatelessWidget {
  final SpiritualIntent intent;

  const IntentPlaylistScreen({
    super.key,
    required this.intent,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final List<AudioTrack> tracks = playerService.allTracks
            .where((t) => t.matchesCategoryKey(intent.categoryKey))
            .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // Hero AppBar with Gradient & Intent Icon
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient Background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              intent.accentColor.withValues(alpha: 0.8),
                              AppColors.background,
                            ],
                          ),
                        ),
                      ),

                      // Content overlay
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white30),
                              ),
                              child: Icon(intent.icon, color: Colors.white, size: 36),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    intent.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    intent.subtitle,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${tracks.length} tracks curated for your spirit',
                                    style: TextStyle(
                                      color: intent.accentColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons Row (Play All, Download All)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 24),
                        label: const Text('Play Intent', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          if (tracks.isNotEmpty) {
                            playerService.playTrack(tracks.first);
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.glassBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: const Text('Download All'),
                        onPressed: () {
                          for (var t in tracks) {
                            if (!t.isDownloaded) {
                              playerService.toggleDownload(t.id);
                            }
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Downloading ${tracks.length} tracks for offline play'),
                              backgroundColor: AppColors.surface,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Track List
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: tracks.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'No tracks found in this category.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final track = tracks[index];
                            final isCurrent = playerService.currentTrack?.id == track.id;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isCurrent ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isCurrent ? AppColors.primary : AppColors.glassBorder,
                                ),
                              ),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    track.albumArtUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 48,
                                      height: 48,
                                      color: AppColors.surfaceLight,
                                      child: const Icon(Icons.music_note, color: Colors.white54),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${track.artist} • ${track.formattedDuration}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        track.isDownloaded ? Icons.download_done_rounded : Icons.download_outlined,
                                        color: track.isDownloaded ? AppColors.offlineBadge : Colors.white38,
                                        size: 20,
                                      ),
                                      onPressed: () => playerService.toggleDownload(track.id),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isCurrent && playerService.isPlaying
                                            ? Icons.pause_circle_filled_rounded
                                            : Icons.play_circle_fill_rounded,
                                        color: AppColors.primary,
                                        size: 32,
                                      ),
                                      onPressed: () {
                                        if (isCurrent) {
                                          playerService.togglePlayPause();
                                        } else {
                                          playerService.playTrack(track);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: tracks.length,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
