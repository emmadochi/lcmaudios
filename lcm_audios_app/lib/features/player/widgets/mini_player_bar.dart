import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio_player_service.dart';
import '../screens/full_player_screen.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final track = playerService.currentTrack;
        if (track == null || playerService.isMiniPlayerDismissed) {
          return const SizedBox.shrink();
        }

        double progress = 0.0;
        if (playerService.duration.inMilliseconds > 0) {
          progress = (playerService.position.inMilliseconds /
                  playerService.duration.inMilliseconds)
              .clamp(0.0, 1.0);
        }

        final bool isPausedWithProgress = !playerService.isPlaying && playerService.position.inSeconds > 0;

        return Dismissible(
          key: ValueKey('mini_player_${track.id}'),
          direction: DismissDirection.down,
          onDismissed: (_) {
            playerService.dismissMiniPlayer();
          },
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Edge Slim Scrub Progress Bar
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 2.5,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),

                // Player Row Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                  child: Row(
                    children: [
                      // Album Artwork Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: track.albumArtUrl,
                          width: 42,
                          height: 42,
                          memCacheWidth: 120,
                          memCacheHeight: 120,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 42,
                            height: 42,
                            color: AppColors.surfaceLight,
                            child: const Icon(Icons.music_note_rounded, color: Colors.white54, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Track Title & Artist / Resume Indicator
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    track.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                                if (isPausedWithProgress) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.5),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: const Text(
                                      'RESUME',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${track.artist} • ${track.subgenre}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isPausedWithProgress
                                    ? AppColors.primary.withValues(alpha: 0.9)
                                    : Colors.white60,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Play / Pause / Resume Button
                      IconButton(
                        icon: Icon(
                          playerService.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: AppColors.primary,
                          size: 34,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () => playerService.togglePlayPause(),
                      ),

                      // Close / Dismiss Button
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white60,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'Close player',
                        onPressed: () => playerService.dismissMiniPlayer(),
                      ),
                    ],
                  ),
                ),

                // Hairline Divider separating player from bottom navigation tabs
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
