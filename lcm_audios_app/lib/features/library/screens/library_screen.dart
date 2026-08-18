import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/audio_track.dart';
import '../../../services/audio_player_service.dart';
import 'custom_playlist_detail_screen.dart';
import '../../partner/widgets/covenant_partner_paywall_sheet.dart';
import '../../../services/offline_storage_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedTabIndex = 0; // 0: Playlists, 1: Downloads, 2: Favourites, 3: Notes

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showCreatePlaylistDialog(BuildContext context, AudioPlayerService playerService) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final isDark = AppColors.isDarkMode(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.playlist_add_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Create Custom Playlist',
              style: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              style: TextStyle(color: AppColors.text(context)),
              decoration: InputDecoration(
                labelText: 'Playlist Title',
                labelStyle: TextStyle(color: AppColors.muted(context)),
                hintText: 'e.g. Midnight Deliverance Chants',
                hintStyle: TextStyle(color: AppColors.muted(context).withValues(alpha: 0.6), fontSize: 13),
                filled: true,
                fillColor: isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: TextStyle(color: AppColors.text(context)),
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: TextStyle(color: AppColors.muted(context)),
                hintText: 'e.g. For personal devotion & prayer vigil',
                hintStyle: TextStyle(color: AppColors.muted(context).withValues(alpha: 0.6), fontSize: 13),
                filled: true,
                fillColor: isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.muted(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
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
            child: const Text('Create Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showClearAllDownloadsDialog(BuildContext context, AudioPlayerService playerService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Clear All Downloads?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'This will purge all encrypted offline tracks from your device to free up storage space. You can re-download them anytime.',
          style: TextStyle(color: AppColors.subtext(context), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.muted(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await playerService.clearAllDownloads();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Offline cache cleared successfully'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.card(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text('Clear Storage', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final favorites       = playerService.allTracks.where((t) => t.isFavorite).toList();
        final downloaded      = playerService.allTracks.where((t) => t.isDownloaded).toList();
        final tracksWithNotes = playerService.allTracks.where((t) => t.notes.isNotEmpty).toList();
        final dlProgress      = playerService.downloadProgress;
        final customPlaylists = playerService.customPlaylists;

        final tabs = [
          {'icon': Icons.queue_music_rounded, 'label': 'Playlists', 'count': customPlaylists.length},
          {'icon': Icons.download_done_rounded, 'label': 'Downloads', 'count': downloaded.length},
          {'icon': Icons.favorite_rounded, 'label': 'Favourites', 'count': favorites.length},
          {'icon': Icons.edit_note_rounded, 'label': 'Notes', 'count': tracksWithNotes.length},
        ];

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Top Header ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Library',
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: playerService.isOnline
                              ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.12)
                              : (isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: playerService.isOnline
                                ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.5 : 0.3)
                                : (isDark ? AppColors.glassBorder : AppColors.lightGlassBorder),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              playerService.isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                              color: playerService.isOnline ? const Color(0xFF10B981) : AppColors.muted(context),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              playerService.isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                color: playerService.isOnline ? const Color(0xFF10B981) : AppColors.muted(context),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Covenant Partner Vault Card ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: InkWell(
                    onTap: () => CovenantPartnerPaywallSheet.show(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? (playerService.isCovenantPartner
                                  ? [const Color(0xFF2A1C3D), const Color(0xFF191024)]
                                  : [const Color(0xFF201335), const Color(0xFF120B1D)])
                              : (playerService.isCovenantPartner
                                  ? [const Color(0xFFFFF8E7), const Color(0xFFFDF1D0)]
                                  : [const Color(0xFFFBF4FF), const Color(0xFFF4EAFF)]),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: playerService.isCovenantPartner ? 0.6 : 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: playerService.isCovenantPartner ? (isDark ? 0.15 : 0.12) : 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFDF79), Color(0xFFD4AF37)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Color(0xFF140D1E),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playerService.isCovenantPartner
                                      ? 'COVENANT PARTNER (GOLD)'
                                      : 'BECOME A COVENANT PARTNER',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFFFFDF79) : const Color(0xFF946200),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  playerService.isCovenantPartner
                                      ? 'Unlimited Downloads • Full Sermon Vault'
                                      : 'Unlock unlimited downloads & exclusive vault',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : const Color(0xFF4A3E59),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: isDark ? const Color(0xFFFFDF79) : const Color(0xFF946200),
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Interactive Segmented Tab Bar ──────────────────────────
                Container(
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
                    ),
                  ),
                  child: Row(
                    children: List.generate(tabs.length, (idx) {
                      final isSelected = _selectedTabIndex == idx;
                      final tab = tabs[idx];

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTabIndex = idx;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  tab['icon'] as IconData,
                                  color: isSelected ? Colors.white : AppColors.muted(context),
                                  size: 15,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${tab['label']}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.subtext(context),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 11.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Tab View Content Area ─────────────────────────────────
                Expanded(
                  child: IndexedStack(
                    index: _selectedTabIndex,
                    children: [
                      // TAB 0: Custom Playlists
                      _buildPlaylistsTab(context, playerService, customPlaylists),

                      // TAB 1: Offline Downloads
                      _buildDownloadsTab(context, playerService, downloaded, dlProgress),

                      // TAB 2: Favourites
                      _buildFavoritesTab(context, playerService, favorites),

                      // TAB 3: Sermon Notes & Transcripts
                      _buildNotesTab(context, playerService, tracksWithNotes),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── TAB 0: PLAYLISTS ────────────────────────────────────────────────────────
  Widget _buildPlaylistsTab(BuildContext context, AudioPlayerService playerService, List customPlaylists) {
    final isDark = AppColors.isDarkMode(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        // "Create New Playlist" Action Banner
        InkWell(
          onTap: () => _showCreatePlaylistDialog(context, playerService),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.primary.withValues(alpha: 0.4) : AppColors.primary.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow(context),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  AppColors.card(context),
                  AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.playlist_add_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New Custom Playlist',
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Group your personal prayer & soaking tracks',
                        style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 26),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (customPlaylists.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.queue_music_rounded, color: AppColors.muted(context).withValues(alpha: 0.5), size: 48),
                const SizedBox(height: 12),
                Text(
                  'No Custom Playlists Yet',
                  style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap the button above to create your first prayer playlist.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                ),
              ],
            ),
          )
        else
          ...customPlaylists.map((playlist) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow(context),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.queue_music_rounded, color: AppColors.primary, size: 22),
                ),
                title: Text(
                  playlist.title,
                  style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  '${playlist.trackIds.length} tracks ${playlist.description.isNotEmpty ? '• ${playlist.description}' : ''}',
                  style: TextStyle(color: AppColors.subtext(context), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 32),
                      onPressed: () => playerService.playCustomPlaylist(playlist),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: AppColors.muted(context), size: 20),
                      onPressed: () => playerService.deletePlaylist(playlist.id),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomPlaylistDetailScreen(playlistId: playlist.id),
                    ),
                  );
                },
              ),
            );
          }),
      ],
    );
  }

  // ─── TAB 1: DOWNLOADS ────────────────────────────────────────────────────────
  Widget _buildDownloadsTab(BuildContext context, AudioPlayerService playerService, List<AudioTrack> downloaded, Map<String, double> dlProgress) {
    final isDark = AppColors.isDarkMode(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        // Storage Usage & Clear Cache Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow(context),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_rounded, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${downloaded.length} Offline Tracks (AES-256)',
                    style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              if (downloaded.isNotEmpty)
                InkWell(
                  onTap: () => _showClearAllDownloadsDialog(context, playerService),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Active Downloading Progress Bars
        ...playerService.allTracks
            .where((t) => dlProgress.containsKey(t.id))
            .map((track) {
          final progress = dlProgress[track.id] ?? 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.downloading_rounded, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        track.title,
                        style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }),

        if (downloaded.isEmpty && dlProgress.isEmpty)
          Container(
            padding: const EdgeInsets.all(36),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.download_done_rounded, color: AppColors.muted(context).withValues(alpha: 0.5), size: 48),
                const SizedBox(height: 12),
                Text(
                  'No Offline Downloads Yet',
                  style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap the download icon (↓) on any track to save encrypted audio for offline devotionals.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                ),
              ],
            ),
          )
        else
          ...downloaded.map((track) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow(context),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: track.albumArtUrl,
                    width: 44,
                    height: 44,
                    memCacheWidth: 120,
                    memCacheHeight: 120,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      color: isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight,
                      child: Icon(Icons.music_note_rounded, color: AppColors.muted(context)),
                    ),
                  ),
                ),
                title: Text(
                  track.title,
                  style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 13.5),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: FutureBuilder<int?>(
                  future: OfflineStorageService.getDownloadedFileSizeBytes(track.id),
                  builder: (context, snap) {
                    final size = snap.data;
                    final sizeStr = size != null ? '${(size / 1024 / 1024).toStringAsFixed(1)} MB' : '···';
                    return Text(
                      '${track.artist} • $sizeStr',
                      style: TextStyle(color: AppColors.subtext(context), fontSize: 11.5),
                    );
                  },
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF10B981), size: 30),
                      onPressed: () => playerService.playTrack(track),
                      tooltip: 'Play offline',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: AppColors.muted(context), size: 20),
                      onPressed: () => playerService.toggleDownload(track.id),
                      tooltip: 'Remove download',
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ─── TAB 2: FAVOURITES ───────────────────────────────────────────────────────
  Widget _buildFavoritesTab(BuildContext context, AudioPlayerService playerService, List<AudioTrack> favorites) {
    final isDark = AppColors.isDarkMode(context);

    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border_rounded, color: AppColors.muted(context).withValues(alpha: 0.5), size: 48),
              const SizedBox(height: 12),
              Text(
                'No Favourites Saved',
                style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap the heart icon (❤️) on any sermon or worship track to save it here for quick prayer access.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted(context), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final track = favorites[index];
        final isCurrent = playerService.currentTrack?.id == track.id;
        final isPlaying = isCurrent && playerService.isPlaying;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.10)
                : AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrent
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : (isDark ? AppColors.glassBorder : AppColors.lightGlassBorder),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow(context),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: track.albumArtUrl,
                width: 46,
                height: 46,
                memCacheWidth: 120,
                memCacheHeight: 120,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 46,
                  height: 46,
                  color: isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight,
                  child: Icon(Icons.music_note_rounded, color: AppColors.muted(context)),
                ),
              ),
            ),
            title: Text(
              track.title,
              style: TextStyle(
                color: isCurrent ? AppColors.primary : AppColors.text(context),
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${track.artist} • ${track.subgenre} • ${_formatDuration(track.duration)}',
              style: TextStyle(color: AppColors.subtext(context), fontSize: 11.5),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
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
                IconButton(
                  icon: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 20),
                  onPressed: () => playerService.toggleFavorite(track.id),
                  tooltip: 'Remove from favourites',
                ),
              ],
            ),
            onTap: () => playerService.playTrack(track),
          ),
        );
      },
    );
  }

  // ─── TAB 3: SERMON NOTES ────────────────────────────────────────────────────
  Widget _buildNotesTab(BuildContext context, AudioPlayerService playerService, List<AudioTrack> tracksWithNotes) {
    final isDark = AppColors.isDarkMode(context);

    if (tracksWithNotes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_note_rounded, color: AppColors.muted(context).withValues(alpha: 0.5), size: 48),
              const SizedBox(height: 12),
              Text(
                'No Sermon Insights Saved',
                style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                'While listening to any sermon, tap the Sermon Notes tab to anchor personal insights at exact timestamps.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted(context), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final allNotes = tracksWithNotes.expand((t) {
      return t.notes.map((n) => {'track': t, 'note': n});
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      itemCount: allNotes.length,
      itemBuilder: (context, index) {
        final item = allNotes[index];
        final AudioTrack track = item['track'] as AudioTrack;
        final note = item['note'] as dynamic;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow(context),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Timestamp Jump Pill
                  InkWell(
                    onTap: () {
                      playerService.playTrack(track);
                      playerService.seekTo(Duration(seconds: note.timestampSeconds.toInt()));
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: AppColors.secondary, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            note.formattedTimestamp,
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      track.title,
                      style: TextStyle(color: AppColors.subtext(context), fontSize: 11, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '“${note.noteText}”',
                style: TextStyle(
                  color: AppColors.text(context),
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sermon by ${track.artist}',
                style: TextStyle(color: AppColors.muted(context), fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}
