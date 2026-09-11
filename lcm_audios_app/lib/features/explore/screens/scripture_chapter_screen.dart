import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio_player_service.dart';

class ScriptureChapterScreen extends StatelessWidget {
  final String book;
  final int chapter;

  const ScriptureChapterScreen({
    super.key,
    required this.book,
    required this.chapter,
  });

  @override
  Widget build(BuildContext context) {
    final scriptureTitle = '$book $chapter';
    final isDark = AppColors.isDarkMode(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.text(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          scriptureTitle,
          style: TextStyle(
            color: AppColors.text(context),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Consumer<AudioPlayerService>(
        builder: (context, playerService, _) {
          // Find all tracks matching this book & chapter or with matching scripture reference
          final matchingTracks = playerService.allTracks.where((t) {
            if (t.scriptureBook != null && t.scriptureBook!.toLowerCase() == book.toLowerCase()) {
              if (t.scriptureChapter == null || t.scriptureChapter == chapter) return true;
            }
            if (t.scriptureReference != null &&
                t.scriptureReference!.toLowerCase().contains(scriptureTitle.toLowerCase())) {
              return true;
            }
            return false;
          }).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Scripture Anchor Card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E2130), Color(0xFF0F111A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_stories_rounded, color: Color(0xFFFFDF79), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'SCRIPTURE ARCHIVE • $scriptureTitle',
                            style: const TextStyle(
                              color: Color(0xFFFFDF79),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '“For the word of God is quick, and powerful, and sharper than any twoedged sword...”',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13.5,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hebrews 4:12',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                      ),
                      const Divider(color: Colors.white12, height: 24),
                      Row(
                        children: [
                          Icon(Icons.audiotrack_rounded, color: AppColors.primary.withValues(alpha: 0.8), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${matchingTracks.length} Anointed Sermons anchored on $scriptureTitle',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Sermons list
              if (matchingTracks.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No sermons archived for $scriptureTitle yet. Check back as new services are added!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(
                    itemCount: matchingTracks.length,
                    itemBuilder: (context, index) {
                      final track = matchingTracks[index];
                      final isCurrent = playerService.currentTrack?.id == track.id;
                      final isPlaying = isCurrent && playerService.isPlaying;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? (isDark ? AppColors.surfaceLight : const Color(0xFFFEE2E2).withValues(alpha: 0.7))
                              : AppColors.card(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent ? AppColors.primary : AppColors.border(context),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
                          ),
                          title: Text(
                            track.title,
                            style: TextStyle(
                              color: isCurrent ? AppColors.primary : AppColors.text(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${track.artist} • ${track.formattedDuration}',
                            style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_fill_rounded,
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
                        ),
                      );
                    },
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}
