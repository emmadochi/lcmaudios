import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/audio_track.dart';
import '../../../services/audio_player_service.dart';

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
              gradient: RadialGradient(
                center: Alignment(0, -0.6),
                radius: 1.2,
                colors: [
                  AppColors.primaryGlow,
                  AppColors.background,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top Navigation Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textPrimary, size: 32),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Column(
                          children: [
                            const Text(
                              'PLAYING FROM INTENT',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              track.subgenre,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                track.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: track.isFavorite ? AppColors.primary : AppColors.textSecondary,
                              ),
                              onPressed: () => playerService.toggleFavorite(track.id),
                            ),
                            IconButton(
                              icon: Icon(
                                track.isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                                color: track.isDownloaded ? AppColors.offlineBadge : AppColors.textSecondary,
                              ),
                              onPressed: () => playerService.toggleDownload(track.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Center Artwork Showcase
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: CachedNetworkImage(
                              imageUrl: track.albumArtUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorWidget: (ctx, url, err) => Container(
                                color: AppColors.surfaceLight,
                                child: const Icon(Icons.music_note, size: 80, color: AppColors.primary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Track Metadata & Intent Badge
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
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
                                      fontSize: 20,
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
                        const SizedBox(height: 16),

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

                  // Audio Control Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shuffle_rounded, color: AppColors.textMuted),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, color: AppColors.textPrimary, size: 36),
                          onPressed: () => playerService.skipPrevious(),
                        ),
                        GestureDetector(
                          onTap: () => playerService.togglePlayPause(),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGlow,
                                  blurRadius: 16,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              playerService.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, color: AppColors.textPrimary, size: 36),
                          onPressed: () => playerService.skipNext(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.repeat_rounded, color: AppColors.textMuted),
                          onPressed: () {},
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
                          child: ListView.builder(
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
