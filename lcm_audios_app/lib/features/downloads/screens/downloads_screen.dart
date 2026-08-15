import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/audio_track.dart';
import '../../../services/audio_player_service.dart';
import '../../../services/offline_storage_service.dart';
import '../../partner/widgets/covenant_partner_paywall_sheet.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  bool _isSyncingTelemetry = false;
  bool _isBatchDownloading = false;
  int _actualCacheSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _refreshStorageSize();
  }

  Future<void> _refreshStorageSize() async {
    final size = await OfflineStorageService.getTotalCacheSizeBytes();
    if (mounted) {
      setState(() {
        _actualCacheSizeBytes = size;
      });
    }
  }

  Future<void> _syncOfflineTelemetry() async {
    setState(() => _isSyncingTelemetry = true);
    final flushedCount = await OfflineStorageService.flushPendingTelemetry();
    setState(() => _isSyncingTelemetry = false);

    if (!mounted) return;
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

  void _showClearCacheDialog(AudioPlayerService playerService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text(
              'Clear Offline Cache?',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'This will permanently delete all AES-256 encrypted sermons and songs from your device storage. You will need an internet connection to re-download them.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await playerService.clearAllOfflineCache();
              await _refreshStorageSize();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Offline storage cache cleared successfully.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: const Text('Purge Cache', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _batchDownload(AudioPlayerService playerService, List<AudioTrack> tracks, String label) async {
    final undownloaded = tracks.where((t) => !t.isDownloaded).toList();
    if (undownloaded.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All $label tracks are already downloaded!'),
          backgroundColor: AppColors.success,
        ),
      );
      return;
    }

    if (!playerService.isCovenantPartner && playerService.hasReachedDownloadLimit) {
      CovenantPartnerPaywallSheet.show(context, sourceFeature: 'Unlimited Batch Downloads');
      return;
    }

    setState(() {
      _isBatchDownloading = true;
    });

    final count = await playerService.batchDownloadTracks(undownloaded);
    await _refreshStorageSize();

    if (!mounted) return;
    setState(() {
      _isBatchDownloading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully downloaded $count $label tracks for offline DRM playback!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final downloadedTracks = playerService.allTracks.where((t) => t.isDownloaded).toList();
        final favoritesUndownloaded = playerService.allTracks.where((t) => t.isFavorite && !t.isDownloaded).toList();
        final double mbUsed = _actualCacheSizeBytes > 0
            ? (_actualCacheSizeBytes / (1024 * 1024))
            : (downloadedTracks.length * 18.5);
        final double percentUsed = (mbUsed / 1024.0).clamp(0.0, 1.0);

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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.glassBorder),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.offlineBadge.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.lock_outline_rounded, color: AppColors.offlineBadge, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AES-256 DRM Storage',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Encrypted offline vault',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: playerService.isOnline
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: playerService.isOnline
                                    ? AppColors.success.withValues(alpha: 0.4)
                                    : AppColors.primary.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  playerService.isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                                  color: playerService.isOnline ? AppColors.success : AppColors.primary,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  playerService.isOnline ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    color: playerService.isOnline ? AppColors.success : AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                            '${downloadedTracks.length} Offline Tracks',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${mbUsed.toStringAsFixed(1)} MB / 1.0 GB Vault Cap',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                      if (downloadedTracks.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _showClearCacheDialog(playerService),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.delete_sweep_rounded, color: AppColors.primary, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Clear All Offline Cache',
                                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Covenant Partner Tier Quota Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: playerService.isCovenantPartner
                        ? const Color(0xFFD4AF37).withValues(alpha: 0.12)
                        : const Color(0xFF1E1430),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: playerService.isCovenantPartner ? 0.6 : 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFDF79), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playerService.isCovenantPartner
                                  ? 'Covenant Partner Vault: Unlimited'
                                  : 'Free Tier Limit: 3 Encrypted Downloads',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              playerService.isCovenantPartner
                                  ? 'Enjoy unrestricted offline sermon series'
                                  : '${downloadedTracks.length} / 3 slots used on free tier',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!playerService.isCovenantPartner)
                        ElevatedButton(
                          onPressed: () => CovenantPartnerPaywallSheet.show(
                            context,
                            sourceFeature: 'Unlimited Downloads',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: const Color(0xFF140D1E),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                          child: const Text('👑 Unlock'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: playerService.isOfflineModeOnly
                        ? AppColors.offlineBadge.withValues(alpha: 0.12)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: playerService.isOfflineModeOnly
                          ? AppColors.offlineBadge.withValues(alpha: 0.6)
                          : AppColors.glassBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        playerService.isOfflineModeOnly ? Icons.airplanemode_active_rounded : Icons.wifi_rounded,
                        color: playerService.isOfflineModeOnly ? AppColors.offlineBadge : Colors.white70,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Offline Mode Only',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              playerService.isOfflineModeOnly
                                  ? 'App is filtered to downloaded files only'
                                  : 'Filter app browsing strictly to downloaded audio',
                              style: TextStyle(
                                color: playerService.isOfflineModeOnly ? AppColors.offlineBadge : AppColors.textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: playerService.isOfflineModeOnly,
                        activeColor: AppColors.offlineBadge,
                        onChanged: (_) => playerService.toggleOfflineModeOnly(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'BATCH DOWNLOAD ACTIONS',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _isBatchDownloading
                            ? null
                            : () => _batchDownload(
                                  playerService,
                                  playerService.allTracks.where((t) => t.isFavorite).toList(),
                                  'Favorites',
                                ),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 18),
                                  const SizedBox(width: 6),
                                  const Text('Favorites', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${favoritesUndownloaded.length} pending download',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _isBatchDownloading
                            ? null
                            : () => _batchDownload(
                                  playerService,
                                  playerService.allTracks,
                                  'Full Library',
                                ),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.download_for_offline_rounded, color: AppColors.offlineBadge, size: 18),
                                  SizedBox(width: 6),
                                  Text('Download All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${playerService.allTracks.where((t) => !t.isDownloaded).length} tracks remaining',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Downloaded Tracks (${downloadedTracks.length})',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (downloadedTracks.isNotEmpty)
                      const Text(
                        'AES-256 Vault',
                        style: TextStyle(
                          color: AppColors.offlineBadge,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                downloadedTracks.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          children: const [
                            Icon(Icons.file_download_off_rounded, color: Colors.white24, size: 48),
                            SizedBox(height: 10),
                            Text(
                              'No tracks stored offline',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tap the download icon on any sermon or playlist to save for offline DRM playback.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: downloadedTracks.length,
                        itemBuilder: (ctx, i) {
                          final track = downloadedTracks[i];
                          final isCurrentlyActive = playerService.currentTrack?.id == track.id;
                          final isPlaying = isCurrentlyActive && playerService.isPlaying;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isCurrentlyActive ? AppColors.surfaceLight : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isCurrentlyActive ? AppColors.primary : AppColors.glassBorder,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.offlineBadge.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.lock_rounded, color: AppColors.offlineBadge, size: 18),
                              ),
                              title: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrentlyActive ? AppColors.primary : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${track.artist} • Encrypted FLAC',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 20),
                                    onPressed: () async {
                                      await playerService.toggleDownload(track.id);
                                      await _refreshStorageSize();
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_fill_rounded,
                                      color: AppColors.primary,
                                      size: 30,
                                    ),
                                    onPressed: () {
                                      if (isCurrentlyActive) {
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
                      ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        );
      },
    );
  }
}
