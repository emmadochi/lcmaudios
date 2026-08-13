import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio_player_service.dart';
import '../../../services/offline_storage_service.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final favorites       = playerService.allTracks.where((t) => t.isFavorite).toList();
        final downloaded      = playerService.allTracks.where((t) => t.isDownloaded).toList();
        final tracksWithNotes = playerService.allTracks.where((t) => t.notes.isNotEmpty).toList();
        final dlProgress      = playerService.downloadProgress;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: const Text(
              'My Library',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Icon(
                      playerService.isOnline
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_rounded,
                      color: playerService.isOnline
                          ? const Color(0xFF10B981)
                          : AppColors.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      playerService.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: playerService.isOnline
                            ? const Color(0xFF10B981)
                            : AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Stats row ──────────────────────────────────────────────
              Row(
                children: [
                  _StatCard(
                    icon: Icons.favorite_rounded,
                    label: 'Favourites',
                    value: '${favorites.length}',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.download_done_rounded,
                    label: 'Offline',
                    value: '${downloaded.length}',
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.edit_note_rounded,
                    label: 'Notes',
                    value: '${tracksWithNotes.length}',
                    color: AppColors.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Offline Downloads heading ───────────────────────────────
              Row(
                children: const [
                  Icon(Icons.lock_rounded, color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Offline Downloads (AES-256)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Active download progress cards
              ...playerService.allTracks
                  .where((t) => dlProgress.containsKey(t.id))
                  .map((track) {
                final progress = dlProgress[track.id] ?? 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.downloading_rounded,
                              color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              track.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                color: Color(0xFF10B981), fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.glassBorder,
                          valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF10B981)),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Downloaded tracks list
              if (downloaded.isEmpty && dlProgress.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: const Text(
                    'No tracks downloaded yet. Tap ↓ on any track to save it for encrypted offline playback.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                )
              else
                ...downloaded.map((track) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_rounded,
                            color: Color(0xFF10B981), size: 18),
                      ),
                      title: Text(
                        track.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: FutureBuilder<int?>(
                        future: OfflineStorageService.getDownloadedFileSizeBytes(
                            track.id),
                        builder: (context, snap) {
                          final size = snap.data;
                          final sizeStr = size != null
                              ? '${(size / 1024 / 1024).toStringAsFixed(1)} MB'
                              : '···';
                          return Text(
                            '${track.artist} • $sizeStr • AES-256',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11),
                          );
                        },
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_circle_fill_rounded,
                                color: Color(0xFF10B981), size: 28),
                            onPressed: () => playerService.playTrack(track),
                            tooltip: 'Play offline',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.textMuted, size: 22),
                            onPressed: () => playerService.toggleDownload(track.id),
                            tooltip: 'Remove download',
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // ── Favourites ─────────────────────────────────────────────
              if (favorites.isNotEmpty) ...[
                const Text(
                  'Favourite Audio Streams',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...favorites.map((track) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.music_note_rounded,
                          color: AppColors.primary),
                      title: Text(track.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      subtitle: Text('${track.artist} • ${track.subgenre}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_circle_fill_rounded,
                            color: AppColors.primary, size: 30),
                        onPressed: () => playerService.playTrack(track),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],

              // ── Sermon Notes ────────────────────────────────────────────
              const Text(
                'Pinned Sermon Notes & Transcripts',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              tracksWithNotes.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: const Text(
                        'No sermon notes saved yet. Use the note button while playing any sermon to pin your insights.',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                      ),
                    )
                  : Column(
                      children: tracksWithNotes.expand((t) {
                        return t.notes.map((note) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: AppColors.glassBorder),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    note.formattedTimestamp,
                                    style: const TextStyle(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11),
                                  ),
                                ),
                                title: Text(note.noteText,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13)),
                                subtitle: Text(t.title,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.play_arrow_rounded,
                                      color: AppColors.primary),
                                  onPressed: () {
                                    playerService.playTrack(t);
                                    playerService.seekTo(Duration(
                                        seconds:
                                            note.timestampSeconds.toInt()));
                                  },
                                ),
                              ),
                            ));
                      }).toList(),
                    ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Stat card widget ──────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
