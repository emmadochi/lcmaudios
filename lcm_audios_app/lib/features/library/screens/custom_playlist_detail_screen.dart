import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/custom_playlist.dart';
import '../../../core/models/audio_track.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio_player_service.dart';

class CustomPlaylistDetailScreen extends StatefulWidget {
  final String playlistId;

  const CustomPlaylistDetailScreen({
    super.key,
    required this.playlistId,
  });

  @override
  State<CustomPlaylistDetailScreen> createState() => _CustomPlaylistDetailScreenState();
}

class _CustomPlaylistDetailScreenState extends State<CustomPlaylistDetailScreen> {
  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showAddTracksSheet(BuildContext context, AudioPlayerService playerService, CustomPlaylist playlist) {
    String query = '';
    final isDark = AppColors.isDarkMode(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final availableTracks = playerService.allTracks.where((t) {
            final q = query.trim().toLowerCase();
            final matchesQuery = q.isEmpty ||
                t.title.toLowerCase().contains(q) ||
                t.artist.toLowerCase().contains(q) ||
                t.subgenre.toLowerCase().contains(q);
            return matchesQuery;
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.playlist_add_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Add Tracks to Playlist',
                      style: TextStyle(color: AppColors.text(context), fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: AppColors.muted(context)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  style: TextStyle(color: AppColors.text(context), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search songs or sermons to add...',
                    hintStyle: TextStyle(color: AppColors.muted(context), fontSize: 13),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight,
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.muted(context), size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (val) {
                    setModalState(() {
                      query = val;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: availableTracks.length,
                    itemBuilder: (context, index) {
                      final track = availableTracks[index];
                      final isInPlaylist = playlist.trackIds.contains(track.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isInPlaylist
                              ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08)
                              : (isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isInPlaylist
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : (isDark ? AppColors.glassBorder : AppColors.lightGlassBorder).withValues(alpha: 0.4),
                          ),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
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
                                color: isDark ? AppColors.surface : AppColors.lightSurface,
                                child: Icon(Icons.music_note, color: AppColors.muted(context)),
                              ),
                            ),
                          ),
                          title: Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          subtitle: Text(
                            '${track.artist} • ${_formatDuration(track.duration)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.subtext(context), fontSize: 11.5),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isInPlaylist ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                              color: isInPlaylist ? const Color(0xFF10B981) : AppColors.primary,
                              size: 26,
                            ),
                            onPressed: () async {
                              if (isInPlaylist) {
                                await playerService.removeTrackFromPlaylist(playlist.id, track.id);
                              } else {
                                await playerService.addTrackToPlaylist(playlist.id, track.id);
                              }
                              setModalState(() {});
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeletePlaylistDialog(BuildContext context, AudioPlayerService playerService, CustomPlaylist playlist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Playlist?', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${playlist.title}"? This cannot be undone.',
            style: TextStyle(color: AppColors.subtext(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.muted(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await playerService.deletePlaylist(playlist.id);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
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
        final playlist = playerService.customPlaylists.firstWhere(
          (p) => p.id == widget.playlistId,
          orElse: () => CustomPlaylist(
            id: widget.playlistId,
            title: 'Playlist',
            description: '',
            trackIds: [],
            createdAt: DateTime.now(),
          ),
        );

        final List<AudioTrack> tracks = playerService.allTracks
            .where((t) => playlist.trackIds.contains(t.id))
            .toList();

        final totalSeconds = tracks.fold<int>(0, (sum, t) => sum + t.duration.inSeconds);
        final totalDuration = Duration(seconds: totalSeconds);

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          body: CustomScrollView(
            slivers: [
              // Hero App Bar with Gradient
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text(context)),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.playlist_add_rounded, color: AppColors.text(context)),
                    tooltip: 'Add Tracks',
                    onPressed: () => _showAddTracksSheet(context, playerService, playlist),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: AppColors.muted(context)),
                    tooltip: 'Delete Playlist',
                    onPressed: () => _showDeletePlaylistDialog(context, playerService, playlist),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: isDark ? 0.7 : 0.4),
                          AppColors.bg(context),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
                            ),
                            boxShadow: [
                              BoxShadow(color: AppColors.shadow(context), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.queue_music_rounded, color: AppColors.primary, size: 38),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                playlist.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.text(context),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (playlist.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  playlist.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: AppColors.subtext(context), fontSize: 12),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                '${tracks.length} tracks • ${_formatDuration(totalDuration)} total',
                                style: TextStyle(
                                  color: isDark ? AppColors.accentGold : const Color(0xFF946200),
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
                ),
              ),

              // Action Buttons Row (Play All, Shuffle All, Add Tracks)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text('Play All', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: tracks.isEmpty
                            ? null
                            : () => playerService.playCustomPlaylist(playlist, startIndex: 0),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.text(context),
                          side: BorderSide(
                            color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        icon: Icon(Icons.shuffle_rounded, size: 18, color: isDark ? AppColors.accentGold : const Color(0xFF946200)),
                        label: const Text('Shuffle'),
                        onPressed: tracks.isEmpty
                            ? null
                            : () {
                                playerService.toggleShuffle();
                                playerService.playCustomPlaylist(playlist, startIndex: 0);
                              },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 28),
                        tooltip: 'Add Tracks',
                        onPressed: () => _showAddTracksSheet(context, playerService, playlist),
                      ),
                    ],
                  ),
                ),
              ),

              // Track List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                sliver: tracks.isEmpty
                    ? SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(Icons.library_music_rounded, color: AppColors.muted(context).withValues(alpha: 0.5), size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'No tracks in this playlist yet',
                                style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap the "+ Add Tracks" button above to curate sermons and worship for your prayer time.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Add Songs & Sermons'),
                                onPressed: () => _showAddTracksSheet(context, playerService, playlist),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final track = tracks[index];
                            final isCurrentlyActive = playerService.currentTrack?.id == track.id;
                            final isPlaying = isCurrentlyActive && playerService.isPlaying;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isCurrentlyActive
                                    ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08)
                                    : AppColors.card(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isCurrentlyActive
                                      ? AppColors.primary.withValues(alpha: 0.6)
                                      : (isDark ? AppColors.glassBorder : AppColors.lightGlassBorder).withValues(alpha: 0.5),
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
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: track.albumArtUrl,
                                    width: 48,
                                    height: 48,
                                    memCacheWidth: 120,
                                    memCacheHeight: 120,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      width: 48,
                                      height: 48,
                                      color: isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight,
                                      child: Icon(Icons.music_note, color: AppColors.muted(context)),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isCurrentlyActive ? AppColors.primary : AppColors.text(context),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${track.artist} • ${_formatDuration(track.duration)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: AppColors.subtext(context), fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove_circle_outline_rounded, color: AppColors.muted(context), size: 20),
                                      tooltip: 'Remove from Playlist',
                                      onPressed: () => playerService.removeTrackFromPlaylist(playlist.id, track.id),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                        color: AppColors.primary,
                                        size: 30,
                                      ),
                                      onPressed: () {
                                        if (isCurrentlyActive) {
                                          playerService.togglePlayPause();
                                        } else {
                                          playerService.playCustomPlaylist(playlist, startIndex: index);
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
