import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio_player_service.dart';
import 'sermon_series_detail_screen.dart';

class MinisterProfileScreen extends StatefulWidget {
  final Map<String, dynamic> minister;

  const MinisterProfileScreen({
    super.key,
    required this.minister,
  });

  @override
  State<MinisterProfileScreen> createState() => _MinisterProfileScreenState();
}

class _MinisterProfileScreenState extends State<MinisterProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.minister['name']?.toString() ?? 'Pastor Martins Omonua';
    final role = widget.minister['role']?.toString() ?? 'Lead Pastor, LCM';
    final avatarUrl = widget.minister['avatarUrl'] ?? widget.minister['avatar'] ??
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80';
    final isDark = AppColors.isDarkMode(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Consumer<AudioPlayerService>(
        builder: (context, playerService, _) {
          // Filter tracks taught by this minister
          final ministerTracks = playerService.allTracks.where((t) {
            final tArtist = t.artist.toLowerCase();
            final query = name.toLowerCase();
            return tArtist.contains(query) || (t.ministerId != null && t.ministerId == widget.minister['id']);
          }).toList();

          // Get series associated with this minister
          final ministerSeries = playerService.allSeries.where((s) {
            return s.ministerName.toLowerCase().contains(name.toLowerCase()) ||
                s.ministerId == widget.minister['id'];
          }).toList();

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 240,
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
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary.withValues(alpha: 0.8), const Color(0xFF1E2130)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFFFFDF79), Color(0xFFD4AF37)],
                                  ),
                                ),
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: avatarUrl,
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, color: Color(0xFFFFDF79), size: 18),
                                ],
                              ),
                              Text(
                                role,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.muted(context),
                  tabs: [
                    Tab(text: 'Sermon Series (${ministerSeries.length})'),
                    Tab(text: 'All Messages (${ministerTracks.length})'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Series Albums
                ministerSeries.isEmpty
                    ? Center(
                        child: Text(
                          'No standalone series assigned to this minister yet.',
                          style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: ministerSeries.length,
                        itemBuilder: (context, index) {
                          final series = ministerSeries[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            color: AppColors.card(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: AppColors.border(context)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: series.bannerArtUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(
                                series.title,
                                style: TextStyle(
                                  color: AppColors.text(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${series.totalParts} Parts • ${series.year}\n${series.description}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppColors.muted(context), fontSize: 11.5),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SermonSeriesDetailScreen(series: series),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                // Tab 2: All Messages
                ministerTracks.isEmpty
                    ? Center(
                        child: Text(
                          'No messages found for this minister.',
                          style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: ministerTracks.length,
                        itemBuilder: (context, index) {
                          final track = ministerTracks[index];
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
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: track.albumArtUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrent ? AppColors.primary : AppColors.text(context),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                track.formattedDuration,
                                style: TextStyle(color: AppColors.muted(context), fontSize: 11),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_fill_rounded,
                                  color: AppColors.primary,
                                  size: 28,
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
              ],
            ),
          );
        },
      ),
    );
  }
}
