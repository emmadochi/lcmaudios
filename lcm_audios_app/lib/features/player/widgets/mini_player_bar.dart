import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio_player_service.dart';
import '../screens/full_player_screen.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final track = playerService.currentTrack;
        if (track == null) return const SizedBox.shrink();

        double progress = 0.0;
        if (playerService.duration.inMilliseconds > 0) {
          progress = (playerService.position.inMilliseconds /
                  playerService.duration.inMilliseconds)
              .clamp(0.0, 1.0);
        }

        // Active lyric line preview
        String activeLyricText = 'Thy presence fills the temple, Holy, holy, holy Lord...';
        if (track.lyrics.isNotEmpty) {
          final currentSec = playerService.position.inSeconds.toDouble();
          final activeLine = track.lyrics.lastWhere(
            (l) => currentSec >= l.timestampSeconds,
            orElse: () => track.lyrics.first,
          );
          activeLyricText = activeLine.text;
        }

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF141722).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGlow.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle Bar Indicator at Top
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                    child: Column(
                      children: [
                        // Row 1: Album Art, Track Info, Controls
                        Row(
                          children: [
                            // Artwork Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: track.albumArtUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Track Title & Artist
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    track.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Checkmark Icon & Controls
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                            ),
                            const SizedBox(width: 8),

                            // Play/Pause Button
                            IconButton(
                              icon: Icon(
                                playerService.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () => playerService.togglePlayPause(),
                            ),
                            const Icon(Icons.volume_up_rounded, color: Colors.white60, size: 18),
                            const SizedBox(width: 8),
                            const Icon(Icons.closed_caption_rounded, color: Colors.white60, size: 18),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Row 2: Progress Slider Bar
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                        const SizedBox(height: 4),

                        // Row 3: Timestamps
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(playerService.position),
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                            Text(
                              _formatDuration(playerService.duration),
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Row 4: Synced Lyric Preview Text
                        Text(
                          activeLyricText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Row 5: Dynamic Audio Waveform Visualizer
                        _buildWaveformBars(playerService.isPlaying),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveformBars(bool isPlaying) {
    final heights = [12.0, 20.0, 15.0, 28.0, 18.0, 32.0, 22.0, 14.0, 26.0, 18.0, 30.0, 16.0, 24.0, 14.0, 20.0, 28.0, 15.0, 22.0];

    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: heights.map((h) {
          return Container(
            width: 3,
            height: isPlaying ? h : 6.0,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
