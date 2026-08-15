import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/audio_track.dart';
import '../../../services/audio_player_service.dart';

import 'sermon_notes_screen.dart';

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
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
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
                        IconButton(
                          icon: Icon(
                            track.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: track.isFavorite ? AppColors.primary : AppColors.textPrimary,
                          ),
                          onPressed: () => playerService.toggleFavorite(track.id),
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

                  // Player Utility Controls (Speed, Sleep Timer, 10s Rewind, 30s Forward)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Playback Speed Pill
                        InkWell(
                          onTap: () => _showPlaybackSpeedSheet(context, playerService),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: playerService.playbackSpeed != 1.0 ? AppColors.primary : Colors.white10,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.speed_rounded, size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  '${playerService.playbackSpeed}x',
                                  style: TextStyle(
                                    color: playerService.playbackSpeed != 1.0 ? AppColors.primary : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Sleep Timer Pill
                        InkWell(
                          onTap: () => _showSleepTimerSheet(context, playerService),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: playerService.isSleepTimerActive ? AppColors.accentGold : Colors.white10,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bedtime_rounded,
                                  size: 14,
                                  color: playerService.isSleepTimerActive ? AppColors.accentGold : Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  playerService.isSleepTimerActive
                                      ? playerService.formattedSleepTimerRemaining
                                      : 'Sleep Timer',
                                  style: TextStyle(
                                    color: playerService.isSleepTimerActive ? AppColors.accentGold : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Download Action Pill
                        InkWell(
                          onTap: () => playerService.toggleDownload(track.id),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: track.isDownloaded ? const Color(0xFF10B981) : Colors.white10,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  track.isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                                  size: 14,
                                  color: track.isDownloaded ? const Color(0xFF10B981) : Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  track.isDownloaded ? 'Downloaded' : 'Download',
                                  style: TextStyle(
                                    color: track.isDownloaded ? const Color(0xFF10B981) : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Audio Control Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 10s Rewind
                        IconButton(
                          icon: const Icon(Icons.replay_10_rounded, color: Colors.white70, size: 28),
                          onPressed: () => playerService.seekRelative(-10),
                          tooltip: 'Rewind 10s',
                        ),

                        // Skip Previous
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, color: AppColors.textPrimary, size: 34),
                          onPressed: () => playerService.skipPrevious(),
                        ),

                        // Play/Pause Main Button
                        GestureDetector(
                          onTap: () => playerService.togglePlayPause(),
                          child: Container(
                            width: 62,
                            height: 62,
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
                              size: 36,
                            ),
                          ),
                        ),

                        // Skip Next
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, color: AppColors.textPrimary, size: 34),
                          onPressed: () => playerService.skipNext(),
                        ),

                        // 30s Fast-Forward
                        IconButton(
                          icon: const Icon(Icons.forward_30_rounded, color: Colors.white70, size: 28),
                          onPressed: () => playerService.seekRelative(30),
                          tooltip: 'Fast forward 30s',
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
