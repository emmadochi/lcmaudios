import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/audio_track.dart';
import '../../../services/audio_player_service.dart';

class SermonNotesScreen extends StatefulWidget {
  const SermonNotesScreen({super.key});

  @override
  State<SermonNotesScreen> createState() => _SermonNotesScreenState();
}

class _SermonNotesScreenState extends State<SermonNotesScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submitNote(AudioPlayerService playerService, AudioTrack track) {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;

    playerService.addSermonNote(track.id, text);
    _noteController.clear();
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Note pinned at ${track.notes.last.formattedTimestamp}'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final track = playerService.currentTrack;
        final currentSeconds = playerService.position.inSeconds.toDouble();

        if (track == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Sermon Notes'), backgroundColor: AppColors.background),
            body: const Center(child: Text('No media playing.', style: TextStyle(color: AppColors.textMuted))),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${track.artist} • Notes & Lyrics',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Synchronized Lyrics Panel
              Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.subtitles_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Synchronized Lyrics / Transcript',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          '${playerService.position.inMinutes}:${(playerService.position.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.glassBorder, height: 16),
                    Expanded(
                      child: track.lyrics.isEmpty
                          ? const Center(
                              child: Text('No transcript lyrics available for this track.',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            )
                          : ListView.builder(
                              itemCount: track.lyrics.length,
                              itemBuilder: (context, index) {
                                final line = track.lyrics[index];
                                final isCurrentLine = currentSeconds >= line.timestampSeconds &&
                                    (index == track.lyrics.length - 1 ||
                                        currentSeconds < track.lyrics[index + 1].timestampSeconds);

                                return GestureDetector(
                                  onTap: () => playerService.seekTo(Duration(seconds: line.timestampSeconds.toInt())),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      line.text,
                                      style: TextStyle(
                                        color: isCurrentLine ? AppColors.primary : Colors.white54,
                                        fontSize: isCurrentLine ? 14 : 12,
                                        fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),

              // Pinned Sermon Notes List Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Pinned Notes (${track.notes.length})',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Pinned Notes List
              Expanded(
                child: track.notes.isEmpty
                    ? const Center(
                        child: Text(
                          'No notes created yet. Pause or play audio and type a reflection below.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: track.notes.length,
                        itemBuilder: (context, index) {
                          final note = track.notes[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: ListTile(
                              leading: InkWell(
                                onTap: () => playerService.seekTo(Duration(seconds: note.timestampSeconds.toInt())),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    note.formattedTimestamp,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                note.noteText,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.play_circle_outline_rounded, color: Colors.white54, size: 20),
                                onPressed: () => playerService.seekTo(Duration(seconds: note.timestampSeconds.toInt())),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Add Note Input Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.glassBorder)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${playerService.position.inMinutes}:${(playerService.position.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _noteController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Add timestamped sermon note...',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _submitNote(playerService, track),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                        onPressed: () => _submitNote(playerService, track),
                      ),
                    ],
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
