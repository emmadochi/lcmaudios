import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio_player_service.dart';
import 'custom_playlist_detail_screen.dart';
import '../../partner/widgets/covenant_partner_paywall_sheet.dart';
import '../../../services/offline_storage_service.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  void _showCreatePlaylistDialog(BuildContext context, AudioPlayerService playerService) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.playlist_add_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Create Custom Playlist', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Playlist Title',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                hintText: 'e.g. Midnight Deliverance Chants',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                hintText: 'e.g. For personal devotion & vigil chants',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                Navigator.pop(ctx);
                final newPl = await playerService.createPlaylist(title, descController.text.trim());
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomPlaylistDetailScreen(playlistId: newPl.id),
                    ),
                  );
                }
              }
            },
            child: const Text('Create Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final favorites       = playerService.allTracks.where((t) => t.isFavorite).toList();
        final downloaded      = playerService.allTracks.where((t) => t.isDownloaded).toList();
        final tracksWithNotes = playerService.allTracks.where((t) => t.notes.isNotEmpty).toList();
        final dlProgress      = playerService.downloadProgress;
        final customPlaylists = playerService.customPlaylists;

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
              const SizedBox(height: 18),

              // ── Covenant Partner Vault Card ───────────────────────────
              InkWell(
                onTap: () => CovenantPartnerPaywallSheet.show(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: playerService.isCovenantPartner
                          ? [const Color(0xFF2A1C3D), const Color(0xFF191024)]
                          : [const Color(0xFF201335), const Color(0xFF120B1D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: playerService.isCovenantPartner ? 0.6 : 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: playerService.isCovenantPartner ? 0.2 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFDF79), Color(0xFFD4AF37)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Color(0xFF140D1E),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  playerService.isCovenantPartner
                                      ? 'COVENANT PARTNER (GOLD)'
                                      : 'BECOME A COVENANT PARTNER',
                                  style: const TextStyle(
                                    color: Color(0xFFFFDF79),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                if (playerService.isCovenantPartner) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, color: Color(0xFFFFDF79), size: 14),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              playerService.isCovenantPartner
                                  ? 'Unlimited Downloads • Full Sermon Vault • Lossless Spatial Audio'
                                  : 'Unlock exclusive teachings, unlimited downloads & support missions',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: const Color(0xFFFFDF79).withValues(alpha: 0.8),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Custom Playlists Carousel ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.queue_music_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'My Custom Playlists (${customPlaylists.length})',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _showCreatePlaylistDialog(context, playerService),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: const [
                          Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
                          SizedBox(width: 2),
                          Text(
                            'New Playlist',
                            style: TextStyle(color: AppColors.primary, fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: customPlaylists.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // "+ Create Playlist" Card
                      return InkWell(
                        onTap: () => _showCreatePlaylistDialog(context, playerService),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 130,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.8), style: BorderStyle.solid),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Create Playlist',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final playlist = customPlaylists[index - 1];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomPlaylistDetailScreen(playlistId: playlist.id),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.glassBorder),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.queue_music_rounded, color: AppColors.primary, size: 20),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 28),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => playerService.playCustomPlaylist(playlist),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playlist.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${playlist.trackIds.length} tracks',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
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
              const SizedBox(height: 120),
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
