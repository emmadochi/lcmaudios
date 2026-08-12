import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio_player_service.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final downloadedTracks = playerService.allTracks.where((t) => t.isDownloaded).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: const Text(
              'Offline Storage & DRM',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DRM Telemetry & Storage Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.offline_pin_rounded, color: AppColors.offlineBadge),
                          const SizedBox(width: 8),
                          const Text(
                            'DRM Protected Offline Storage',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Synced',
                              style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LinearPercentIndicator(
                        lineHeight: 8,
                        percent: 0.25,
                        backgroundColor: AppColors.surfaceLight,
                        progressColor: AppColors.offlineBadge,
                        barRadius: const Radius.circular(4),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${downloadedTracks.length} Tracks Downloaded',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const Text(
                            '245 MB / 1.0 GB Allocated',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Downloaded Tracks',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: downloadedTracks.isEmpty
                      ? const Center(
                          child: Text(
                            'No tracks downloaded yet for offline play.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.builder(
                          itemCount: downloadedTracks.length,
                          itemBuilder: (ctx, i) {
                            final track = downloadedTracks[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.glassBorder),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.music_note_rounded, color: AppColors.offlineBadge),
                                title: Text(
                                  track.title,
                                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text(
                                  '${track.artist} • Encrypted FLAC',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.play_circle_outline_rounded, color: AppColors.primary, size: 28),
                                  onPressed: () => playerService.playTrack(track),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
