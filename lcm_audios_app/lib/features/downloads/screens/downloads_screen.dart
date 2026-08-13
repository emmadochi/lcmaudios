import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio_player_service.dart';
import '../../../services/offline_storage_service.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  bool _isSyncingTelemetry = false;

  Future<void> _syncOfflineTelemetry() async {
    setState(() {
      _isSyncingTelemetry = true;
    });

    final flushedCount = await OfflineStorageService.flushPendingTelemetry();
    if (!mounted) return;

    setState(() {
      _isSyncingTelemetry = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          flushedCount > 0
              ? 'Flushed $flushedCount stream telemetry events to creator royalty ledger.'
              : 'Offline telemetry fully synced with cloud backend.',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final downloadedTracks = playerService.allTracks.where((t) => t.isDownloaded).toList();
        final double estimatedMbUsed = downloadedTracks.length * 18.5; // ~18.5MB per lossless FLAC
        final double percentUsed = (estimatedMbUsed / 1000.0).clamp(0.0, 1.0);

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
            actions: [
              IconButton(
                icon: _isSyncingTelemetry
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.sync_rounded, color: AppColors.primary),
                tooltip: 'Sync Offline Stream Telemetry',
                onPressed: () => _syncOfflineTelemetry(),
              ),
            ],
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
                              color: playerService.isOnline
                                  ? AppColors.success.withValues(alpha: 0.2)
                                  : AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              playerService.isOnline ? 'Online / Synced' : 'Offline Mode',
                              style: TextStyle(
                                color: playerService.isOnline ? AppColors.success : AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LinearPercentIndicator(
                        lineHeight: 8,
                        percent: percentUsed > 0 ? percentUsed : 0.02,
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
                            '${downloadedTracks.length} Tracks Offline Available',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          Text(
                            '${estimatedMbUsed.toStringAsFixed(1)} MB / 1.0 GB Allocated',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Downloaded Tracks',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (downloadedTracks.isNotEmpty)
                      Text(
                        'AES-256 Encrypted',
                        style: TextStyle(
                          color: AppColors.offlineBadge.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 20),
                                      onPressed: () => playerService.toggleDownload(track.id),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.play_circle_outline_rounded, color: AppColors.primary, size: 28),
                                      onPressed: () => playerService.playTrack(track),
                                    ),
                                  ],
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
