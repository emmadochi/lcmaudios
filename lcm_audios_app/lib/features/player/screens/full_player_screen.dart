import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/audio_track.dart';
import '../../../services/audio_player_service.dart';
import '../../../services/share_service.dart';
import '../../partner/widgets/covenant_partner_paywall_sheet.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _noteInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteInputController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _showAddNoteDialog(BuildContext context, AudioPlayerService playerService, AudioTrack track) {
    _noteInputController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Add Sermon Note @ ${_formatDuration(playerService.position)}',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
          ],
        ),
        content: TextField(
          controller: _noteInputController,
          maxLines: 4,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Type your insights, scripture references or prayer points...',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (_noteInputController.text.trim().isNotEmpty) {
                playerService.addSermonNote(track.id, _noteInputController.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note anchored to timestamp!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: const Text('Save Note', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPlaybackSpeedSheet(BuildContext context, AudioPlayerService playerService) {
    const speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.speed_rounded, color: AppColors.primary),
                SizedBox(width: 10),
                Text(
                  'Playback Speed',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: speeds.map((spd) {
                final isSelected = playerService.playbackSpeed == spd;
                return ChoiceChip(
                  label: Text('${spd}x${spd == 1.0 ? ' (Normal)' : ''}'),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceLight,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      playerService.setPlaybackSpeed(spd);
                      Navigator.pop(ctx);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showSleepTimerSheet(BuildContext context, AudioPlayerService playerService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bedtime_rounded, color: AppColors.accentGold),
                const SizedBox(width: 10),
                const Text(
                  'Sleep Timer',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (playerService.isSleepTimerActive)
                  Text(
                    'Active: ${playerService.formattedSleepTimerRemaining}',
                    style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.timer_off_rounded, color: AppColors.textMuted),
              title: const Text('Turn Off Timer', style: TextStyle(color: Colors.white)),
              onTap: () {
                playerService.cancelSleepTimer();
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_rounded, color: AppColors.accentGold),
              title: const Text('15 Minutes', style: TextStyle(color: Colors.white)),
              onTap: () {
                playerService.setSleepTimer(const Duration(minutes: 15));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_rounded, color: AppColors.accentGold),
              title: const Text('30 Minutes', style: TextStyle(color: Colors.white)),
              onTap: () {
                playerService.setSleepTimer(const Duration(minutes: 30));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_rounded, color: AppColors.accentGold),
              title: const Text('45 Minutes', style: TextStyle(color: Colors.white)),
              onTap: () {
                playerService.setSleepTimer(const Duration(minutes: 45));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_rounded, color: AppColors.accentGold),
              title: const Text('60 Minutes (1 Hour)', style: TextStyle(color: Colors.white)),
              onTap: () {
                playerService.setSleepTimer(const Duration(minutes: 60));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.music_off_rounded, color: AppColors.primary),
              title: const Text('End of this Track / Sermon', style: TextStyle(color: Colors.white)),
              onTap: () {
                playerService.setSleepTimerEndAtTrack();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQueueBottomSheet(BuildContext context, AudioPlayerService playerService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final queue = playerService.queue;
          final currentTrack = playerService.currentTrack;

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
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.queue_music_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Playback Queue (${queue.length})',
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    // Shuffle in queue
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: playerService.isShuffle ? AppColors.accentGold : Colors.white54,
                        size: 20,
                      ),
                      tooltip: 'Toggle Shuffle',
                      onPressed: () {
                        playerService.toggleShuffle();
                        setModalState(() {});
                      },
                    ),
                    // Repeat in queue
                    IconButton(
                      icon: Icon(
                        playerService.repeatMode == RepeatMode.one
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        color: playerService.repeatMode != RepeatMode.off ? AppColors.primary : Colors.white54,
                        size: 20,
                      ),
                      tooltip: 'Repeat Mode',
                      onPressed: () {
                        playerService.cycleRepeatMode();
                        setModalState(() {});
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (currentTrack != null) ...[
                  const Text(
                    'NOW PLAYING',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: currentTrack.albumArtUrl,
                            width: 44,
                            height: 44,
                            memCacheWidth: 120,
                            memCacheHeight: 120,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 44,
                              height: 44,
                              color: AppColors.surfaceLight,
                              child: const Icon(Icons.music_note, color: Colors.white54),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentTrack.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              Text(
                                currentTrack.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.graphic_eq_rounded, color: AppColors.primary, size: 22),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'UP NEXT (Drag to Reorder)',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                    if (queue.length > 1)
                      InkWell(
                        onTap: () {
                          playerService.clearQueue();
                          setModalState(() {});
                        },
                        child: const Text('Clear Queue', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: queue.isEmpty
                      ? const Center(child: Text('Queue is empty.', style: TextStyle(color: AppColors.textMuted)))
                      : ReorderableListView.builder(
                          itemCount: queue.length,
                          onReorder: (oldIndex, newIndex) {
                            playerService.reorderQueue(oldIndex, newIndex);
                            setModalState(() {});
                          },
                          itemBuilder: (context, index) {
                            final trackItem = queue[index];
                            final isCurrent = currentTrack?.id == trackItem.id;

                            return Container(
                              key: ValueKey('${trackItem.id}_$index'),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: isCurrent ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCurrent ? AppColors.primary.withValues(alpha: 0.3) : AppColors.glassBorder.withValues(alpha: 0.5),
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkImage(
                                    imageUrl: trackItem.albumArtUrl,
                                    width: 36,
                                    height: 36,
                                    memCacheWidth: 100,
                                    memCacheHeight: 100,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      width: 36,
                                      height: 36,
                                      color: AppColors.surface,
                                      child: const Icon(Icons.music_note, size: 18, color: Colors.white54),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  trackItem.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isCurrent ? AppColors.primary : Colors.white,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  trackItem.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: Colors.white38),
                                      onPressed: () {
                                        playerService.removeFromQueue(index);
                                        setModalState(() {});
                                      },
                                    ),
                                    const Icon(Icons.drag_handle_rounded, color: Colors.white38, size: 20),
                                  ],
                                ),
                                onTap: () {
                                  playerService.playFromQueue(index);
                                  setModalState(() {});
                                },
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

  void _showAddToPlaylistSheet(BuildContext context, AudioPlayerService playerService, AudioTrack track) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final playlists = playerService.customPlaylists;

          return Container(
            height: MediaQuery.of(context).size.height * 0.65,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.playlist_add_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Add Track to Playlist',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: playlists.isEmpty
                      ? const Center(
                          child: Text('No playlists created yet. Create one from Library screen.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted)),
                        )
                      : ListView.builder(
                          itemCount: playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = playlists[index];
                            final isInPlaylist = playlist.trackIds.contains(track.id);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isInPlaylist
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isInPlaylist
                                      ? AppColors.primary.withValues(alpha: 0.4)
                                      : AppColors.glassBorder.withValues(alpha: 0.4),
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.queue_music_rounded, color: AppColors.primary, size: 20),
                                ),
                                title: Text(
                                  playlist.title,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text(
                                  '${playlist.trackIds.length} tracks',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                                trailing: Icon(
                                  isInPlaylist ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                  color: isInPlaylist ? const Color(0xFF10B981) : AppColors.primary,
                                  size: 26,
                                ),
                                onTap: () async {
                                  if (isInPlaylist) {
                                    await playerService.removeTrackFromPlaylist(playlist.id, track.id);
                                  } else {
                                    await playerService.addTrackToPlaylist(playlist.id, track.id);
                                  }
                                  setModalState(() {});
                                },
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final track = playerService.currentTrack;

        if (track == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text('No track selected', style: TextStyle(color: AppColors.textSecondary))),
          );
        }

        final double currentSeconds = playerService.position.inSeconds.toDouble();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E2130), AppColors.background],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // App Bar Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textPrimary, size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Column(
                          children: [
                            const Text(
                              'PLAYING FROM SERMON STREAM',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              track.subgenre,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.queue_music_rounded, color: Colors.white, size: 22),
                              tooltip: 'Up Next Queue',
                              onPressed: () => _showQueueBottomSheet(context, playerService),
                            ),
                            IconButton(
                              icon: Icon(
                                track.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: track.isFavorite ? AppColors.primary : AppColors.textPrimary,
                              ),
                              onPressed: () => playerService.toggleFavorite(track.id),
                            ),
                            // Share Track Deep Link Button
                            IconButton(
                              icon: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 22),
                              tooltip: 'Share Sermon',
                              onPressed: () => ShareService.instance.shareTrack(
                                context: context,
                                trackId: track.id,
                                title: track.title,
                                artist: track.artist,
                                subgenre: track.subgenre,
                                isPremium: track.isPremium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Album Artwork & Center Visualizer
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGlow.withValues(alpha: 0.35),
                              blurRadius: 30,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: CachedNetworkImage(
                            imageUrl: track.albumArtUrl,
                            memCacheWidth: 600,
                            memCacheHeight: 600,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.surface,
                              child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.surface,
                              child: const Icon(Icons.music_note, size: 80, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Track Info, Category & Slider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (track.isPremium) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFDF79), Color(0xFFD4AF37)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '👑 COVENANT PARTNER EXCLUSIVE',
                                  style: TextStyle(
                                    color: Color(0xFF140D1E),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    track.artist,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Intent Pill Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.glassBorder),
                              ),
                              child: Text(
                                track.intentCategory.name.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.accentGold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (track.isPremium && !playerService.isCovenantPartner) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A1C3D),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined, color: Color(0xFFFFDF79), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    playerService.previewLimitReached
                                        ? '45s Preview Ended. Partner to stream full sermon.'
                                        : 'Playing 45-Sec Anointed Preview',
                                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => CovenantPartnerPaywallSheet.show(
                                    context,
                                    sourceFeature: track.title,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4AF37),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '👑 Unlock Full',
                                      style: TextStyle(
                                        color: Color(0xFF140D1E),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Seek Slider & Time Labels
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.surfaceLight,
                            thumbColor: AppColors.textPrimary,
                          ),
                          child: Slider(
                            value: playerService.position.inSeconds
                                .toDouble()
                                .clamp(0.0, playerService.duration.inSeconds.toDouble().clamp(1.0, 999999.0)),
                            min: 0.0,
                            max: playerService.duration.inSeconds.toDouble() > 0
                                ? playerService.duration.inSeconds.toDouble()
                                : 1.0,
                            onChanged: (val) {
                              playerService.seekTo(Duration(seconds: val.toInt()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(playerService.position),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                              ),
                              Text(
                                _formatDuration(playerService.duration),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Player Utility Controls (Speed, Sleep Timer, Playlist, Animated Download)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 1. Playback Speed Button (Clean badge)
                        InkWell(
                          onTap: () => _showPlaybackSpeedSheet(context, playerService),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: playerService.playbackSpeed != 1.0
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: playerService.playbackSpeed != 1.0 ? AppColors.primary : Colors.white12,
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${playerService.playbackSpeed}x',
                                style: TextStyle(
                                  color: playerService.playbackSpeed != 1.0 ? AppColors.primary : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 2. Sleep Timer Button (Icon-only with active Gold glow + mini badge)
                        InkWell(
                          onTap: () => _showSleepTimerSheet(context, playerService),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 38,
                            width: playerService.isSleepTimerActive ? null : 38,
                            padding: playerService.isSleepTimerActive ? const EdgeInsets.symmetric(horizontal: 10) : EdgeInsets.zero,
                            decoration: BoxDecoration(
                              color: playerService.isSleepTimerActive
                                  ? AppColors.accentGold.withValues(alpha: 0.15)
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: playerService.isSleepTimerActive ? AppColors.accentGold : Colors.white12,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bedtime_rounded,
                                  size: 18,
                                  color: playerService.isSleepTimerActive ? AppColors.accentGold : Colors.white70,
                                ),
                                if (playerService.isSleepTimerActive) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    playerService.formattedSleepTimerRemaining,
                                    style: const TextStyle(
                                      color: AppColors.accentGold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // 3. Add to Playlist Button (Icon-only)
                        InkWell(
                          onTap: () => _showAddToPlaylistSheet(context, playerService, track),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white12, width: 1.2),
                            ),
                            child: const Center(
                              child: Icon(Icons.playlist_add_rounded, size: 20, color: Colors.white70),
                            ),
                          ),
                        ),

                        // 3b. Copy Link Button (Icon-only)
                        InkWell(
                          onTap: () => ShareService.instance.copyLinkToClipboard(
                            context: context,
                            trackId: track.id,
                            title: track.title,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Tooltip(
                            message: 'Copy Link',
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white12, width: 1.2),
                              ),
                              child: const Center(
                                child: Icon(Icons.link_rounded, size: 20, color: Colors.white70),
                              ),
                            ),
                          ),
                        ),

                        // 4. Download Button (Icon with rotating ring + live percentage counter)
                        Builder(
                          builder: (context) {
                            final progress = playerService.getDownloadProgressFor(track.id);
                            final isDownloading = progress != null;
                            final isDownloaded = track.isDownloaded;

                            return InkWell(
                              onTap: isDownloading ? null : () => playerService.toggleDownload(track.id),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: isDownloading ? 52 : 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isDownloaded
                                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                      : (isDownloading ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDownloaded
                                        ? const Color(0xFF10B981)
                                        : (isDownloading ? AppColors.primary : Colors.white12),
                                    width: 1.2,
                                  ),
                                ),
                                child: Center(
                                  child: isDownloading
                                      ? Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              width: 30,
                                              height: 30,
                                              child: CircularProgressIndicator(
                                                value: progress > 0 ? progress : null,
                                                strokeWidth: 2.2,
                                                color: AppColors.primary,
                                                backgroundColor: Colors.white10,
                                              ),
                                            ),
                                            Text(
                                              '${(progress * 100).toInt()}%',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Icon(
                                          isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                                          size: 19,
                                          color: isDownloaded ? const Color(0xFF10B981) : Colors.white70,
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Main Audio Control Buttons (Shuffle, 10s, Prev, Play, Next, 30s, Repeat)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Shuffle Mode Button
                        IconButton(
                          icon: Icon(
                            Icons.shuffle_rounded,
                            color: playerService.isShuffle ? AppColors.accentGold : Colors.white54,
                            size: 22,
                          ),
                          tooltip: 'Shuffle',
                          onPressed: () => playerService.toggleShuffle(),
                        ),

                        // 10s Rewind
                        IconButton(
                          icon: const Icon(Icons.replay_10_rounded, color: Colors.white70, size: 24),
                          onPressed: () => playerService.seekRelative(-10),
                          tooltip: 'Rewind 10s',
                        ),

                        // Skip Previous
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, color: AppColors.textPrimary, size: 32),
                          onPressed: () => playerService.skipPrevious(),
                        ),

                        // Play/Pause Main Button
                        GestureDetector(
                          onTap: () {
                            if (track.isPremium && !playerService.isCovenantPartner && playerService.previewLimitReached) {
                              CovenantPartnerPaywallSheet.show(context, sourceFeature: track.title);
                            } else {
                              playerService.togglePlayPause();
                            }
                          },
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGlow,
                                  blurRadius: 16,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: Icon(
                              playerService.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),

                        // Skip Next
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, color: AppColors.textPrimary, size: 32),
                          onPressed: () => playerService.skipNext(userInitiated: true),
                        ),

                        // 30s Fast-Forward
                        IconButton(
                          icon: const Icon(Icons.forward_30_rounded, color: Colors.white70, size: 24),
                          onPressed: () => playerService.seekRelative(30),
                          tooltip: 'Fast forward 30s',
                        ),

                        // Repeat Mode Button
                        IconButton(
                          icon: Icon(
                            playerService.repeatMode == RepeatMode.one
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                            color: playerService.repeatMode != RepeatMode.off ? AppColors.primary : Colors.white54,
                            size: 22,
                          ),
                          tooltip: playerService.repeatMode == RepeatMode.one
                              ? 'Repeat: One'
                              : playerService.repeatMode == RepeatMode.all
                                  ? 'Repeat: All'
                                  : 'Repeat: Off',
                          onPressed: () {
                            playerService.cycleRepeatMode();
                            final modeName = playerService.repeatMode == RepeatMode.one
                                ? 'Repeating Current Track 🔂'
                                : playerService.repeatMode == RepeatMode.all
                                    ? 'Repeating All Tracks 🔁'
                                    : 'Repeat Off (Play Once) ➡️';
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(modeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                backgroundColor: AppColors.surfaceLight,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Bottom Tabs: Synchronized Lyrics & Sermon Notes
                  Container(
                    height: 38,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.textPrimary,
                      unselectedLabelColor: AppColors.textMuted,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Synced Lyrics'),
                        Tab(text: 'Sermon Notes'),
                      ],
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Synchronized Lyrics
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: track.lyrics.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No synchronized lyrics available for this stream.',
                                    style: TextStyle(color: AppColors.textMuted),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: track.lyrics.length,
                                  itemBuilder: (ctx, i) {
                                    final line = track.lyrics[i];
                                    final isCurrent = (currentSeconds >= line.timestampSeconds &&
                                        (i == track.lyrics.length - 1 || currentSeconds < track.lyrics[i + 1].timestampSeconds));

                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isCurrent ? AppColors.primaryGlow : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        line.text,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                          fontSize: isCurrent ? 16 : 14,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),

                        // Tab 2: Sermon Notes
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surfaceLight,
                                  foregroundColor: AppColors.textPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.add_comment_rounded, color: AppColors.primary),
                                label: const Text('Take Note at Current Time'),
                                onPressed: () => _showAddNoteDialog(context, playerService, track),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: track.notes.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No notes added yet for this sermon.',
                                          style: TextStyle(color: AppColors.textMuted),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: track.notes.length,
                                        itemBuilder: (ctx, i) {
                                          final note = track.notes[i];
                                          return Card(
                                            color: AppColors.surface,
                                            margin: const EdgeInsets.symmetric(vertical: 4),
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor: AppColors.primaryGlow,
                                                child: Text(
                                                  _formatDuration(Duration(seconds: note.timestampSeconds.toInt())),
                                                  style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              title: Text(
                                                note.noteText,
                                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                              ),
                                            ),
                                          );
                                        },
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
        );
      },
    );
  }
}
