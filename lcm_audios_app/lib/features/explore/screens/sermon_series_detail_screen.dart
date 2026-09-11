import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/sermon_series.dart';
import '../../../services/audio_player_service.dart';
import '../../partner/widgets/covenant_partner_paywall_sheet.dart';

class SermonSeriesDetailScreen extends StatelessWidget {
  final SermonSeries series;

  const SermonSeriesDetailScreen({
    super.key,
    required this.series,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Consumer<AudioPlayerService>(
        builder: (context, playerService, _) {
          // Find all tracks belonging to this series, sorted by part number
          final seriesTracks = playerService.allTracks
              .where((t) => t.seriesId == series.id || series.trackIds.contains(t.id))
              .toList()
            ..sort((a, b) => (a.seriesPart ?? 1).compareTo(b.seriesPart ?? 1));

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero AppBar with Series Artwork
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.bg(context),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: series.bannerArtUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 600,
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.card(context),
                          child: const Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 64),
                        ),
                      ),
                      // Gradient Vignette
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.3),
                              Colors.transparent,
                              AppColors.bg(context),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Series Metadata & Action Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag Badge & Year
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SERMON SERIES ALBUM',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${series.totalParts} Parts • ${series.year}',
                            style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Series Title
                      Text(
                        series.title,
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Minister Credit
                      Text(
                        'Ministered by ${series.ministerName}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Description
                      Text(
                        series.description,
                        style: TextStyle(
                          color: AppColors.subtext(context),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // "Play Series in Order" Primary Button (Hick's Law 1-Tap Solution)
                      ElevatedButton.icon(
                        onPressed: seriesTracks.isNotEmpty
                            ? () {
                                playerService.setQueue(seriesTracks, startIndex: 0);
                                playerService.playTrack(seriesTracks.first, updateQueue: false);
                              }
                            : null,
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: Text(
                          'Play Entire Series (${seriesTracks.length} Parts)',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'CHRONOLOGICAL TEACHINGS',
                    style: TextStyle(
                      color: AppColors.muted(context),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),

              // List of Parts in Chronological Order
              if (seriesTracks.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Episodes for this series are being archived and uploaded. Check back shortly!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  sliver: SliverList.builder(
                    itemCount: seriesTracks.length,
                    itemBuilder: (context, index) {
                      final track = seriesTracks[index];
                      final isCurrent = playerService.currentTrack?.id == track.id;
                      final isPlaying = isCurrent && playerService.isPlaying;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? (isDark ? AppColors.surfaceLight : const Color(0xFFFEE2E2).withValues(alpha: 0.7))
                              : AppColors.card(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent ? AppColors.primary : AppColors.border(context),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          leading: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCurrent ? AppColors.primary : AppColors.cardAlt(context),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${track.seriesPart ?? (index + 1)}',
                              style: TextStyle(
                                color: isCurrent ? Colors.white : AppColors.text(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrent ? AppColors.primary : AppColors.text(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: Text(
                            '${track.formattedDuration}${track.scriptureReference != null ? ' • ${track.scriptureReference}' : ''}',
                            style: TextStyle(color: AppColors.muted(context), fontSize: 11.5),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (track.isPremium)
                                InkWell(
                                  onTap: () => CovenantPartnerPaywallSheet.show(context, sourceFeature: track.title),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('👑 GOLD', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_fill_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                                onPressed: () {
                                  if (isCurrent) {
                                    playerService.togglePlayPause();
                                  } else {
                                    playerService.setQueue(seriesTracks, startIndex: index);
                                    playerService.playTrack(track, updateQueue: false);
                                  }
                                },
                              ),
                            ],
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
