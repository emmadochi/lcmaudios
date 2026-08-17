import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/spiritual_intent.dart';
import '../../../core/models/audio_track.dart';
import '../../../services/audio_player_service.dart';
import 'intent_playlist_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filterChips = [
    'All',
    'Sermons',
    'Worship',
    'Warfare',
    'Downloaded',
    'With Notes',
  ];

  final List<Map<String, String>> _ministers = [
    {
      'name': 'Pastor Martins Omonua',
      'role': 'Lead Pastor, LCM',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    },
    {
      'name': 'Apostle Joshua Selman',
      'role': 'Koinonia Eternity',
      'avatar': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=400&q=80',
    },
    {
      'name': 'Pastor Enoch Adeboye',
      'role': 'RCCG General Overseer',
      'avatar': 'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?auto=format&fit=crop&w=400&q=80',
    },
    {
      'name': 'Nathaniel Bassey',
      'role': 'Gospel Psalmist',
      'avatar': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=400&q=80',
    },
    {
      'name': 'LCM Worship Sanctuary',
      'role': 'Resident Choir & Orchestra',
      'avatar': 'https://images.unsplash.com/photo-1520523839897-bd0b52f945a0?auto=format&fit=crop&w=400&q=80',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  List<AudioTrack> _filterTracks(List<AudioTrack> allTracks) {
    final query = _searchQuery.trim().toLowerCase();

    return allTracks.where((track) {
      // 1. Text Search Filter (Title, Artist, Subgenre, Lyrics)
      bool matchesText = true;
      if (query.isNotEmpty) {
        final matchesTitle = track.title.toLowerCase().contains(query);
        final matchesArtist = track.artist.toLowerCase().contains(query);
        final matchesSubgenre = track.subgenre.toLowerCase().contains(query);
        final matchesCategory = track.intentCategory.name.toLowerCase().contains(query);
        final matchesLyrics = track.lyrics.any((l) => l.text.toLowerCase().contains(query));

        matchesText = matchesTitle || matchesArtist || matchesSubgenre || matchesCategory || matchesLyrics;
      }

      // 2. Chip Filter
      bool matchesChip = true;
      switch (_selectedFilter) {
        case 'Sermons':
          matchesChip = track.subgenre.toLowerCase().contains('sermon') ||
              track.subgenre.toLowerCase().contains('apostle') ||
              track.subgenre.toLowerCase().contains('pastor') ||
              track.intentCategory == IntentCategory.morningDevotion;
          break;
        case 'Worship':
          matchesChip = track.intentCategory == IntentCategory.deepWorship ||
              track.subgenre.toLowerCase().contains('worship') ||
              track.subgenre.toLowerCase().contains('chant');
          break;
        case 'Warfare':
          matchesChip = track.intentCategory == IntentCategory.warfarePrayers ||
              track.subgenre.toLowerCase().contains('warfare') ||
              track.subgenre.toLowerCase().contains('prayer');
          break;
        case 'Downloaded':
          matchesChip = track.isDownloaded;
          break;
        case 'With Notes':
          matchesChip = track.notes.isNotEmpty;
          break;
        case 'All':
        default:
          matchesChip = true;
      }

      return matchesText && matchesChip;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AudioPlayerService>(
        builder: (context, playerService, child) {
          final isSearching = _searchQuery.trim().isNotEmpty || _selectedFilter != 'All';
          final searchResults = _filterTracks(playerService.allTracks);
          final intents = playerService.categories
              .where((i) => i.categoryKey.toLowerCase() != 'all')
              .toList();

          return SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () => playerService.refreshAll(),
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // App Bar / Title Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Explore & Search',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isSearching
                                    ? '${searchResults.length} audio streams found'
                                    : 'Find sermons, ministers & prayer atmospheres',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          if (isSearching)
                            TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedFilter = 'All';
                                });
                              },
                              icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
                              label: const Text(
                                'Clear',
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Search Bar (Sticky & Elevated)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSearching ? AppColors.primary.withValues(alpha: 0.6) : AppColors.glassBorder,
                            width: isSearching ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w500),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search sermons, preachers, scriptures...',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Multi-Facet Filter Chips Bar
                  SliverToBoxAdapter(
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filterChips.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final chip = _filterChips[idx];
                          final isSelected = _selectedFilter == chip;

                          return ChoiceChip(
                            label: Text(chip),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = selected ? chip : 'All';
                              });
                            },
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : AppColors.glassBorder,
                              ),
                            ),
                            showCheckmark: false,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          );
                        },
                      ),
                    ),
                  ),

                  // ─── CASE A: Active Search Results Mode ──────────────────────────
                  if (isSearching) ...[
                    if (searchResults.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.glassBorder),
                                  ),
                                  child: const Icon(Icons.search_off_rounded, color: AppColors.primary, size: 48),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Audio Streams Found',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'We couldn\'t find any match for "$_searchQuery". Try another keyword, preacher, or category filter.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                ),
                                const SizedBox(height: 20),
                                OutlinedButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _selectedFilter = 'All';
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('View All Categories'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final track = searchResults[index];
                              final isCurrent = playerService.currentTrack?.id == track.id;
                              final isPlaying = isCurrent && playerService.isPlaying;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isCurrent ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isCurrent ? AppColors.primary.withValues(alpha: 0.5) : AppColors.glassBorder,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  leading: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: CachedNetworkImage(
                                          imageUrl: track.albumArtUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => Container(
                                            width: 50,
                                            height: 50,
                                            color: AppColors.surfaceLight,
                                            child: const Icon(Icons.music_note_rounded, color: AppColors.textMuted),
                                          ),
                                        ),
                                      ),
                                      if (isPlaying)
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.graphic_eq_rounded, color: AppColors.primary, size: 24),
                                        ),
                                    ],
                                  ),
                                  title: Text(
                                    track.title,
                                    style: TextStyle(
                                      color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          track.artist,
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _formatDuration(track.duration),
                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                      color: AppColors.primary,
                                      size: 36,
                                    ),
                                    onPressed: () {
                                      if (isCurrent) {
                                        playerService.togglePlayPause();
                                      } else {
                                        playerService.playTrack(track);
                                      }
                                    },
                                  ),
                                  onTap: () {
                                    playerService.playTrack(track);
                                  },
                                ),
                              );
                            },
                            childCount: searchResults.length,
                          ),
                        ),
                      ),
                  ]

                  // ─── CASE B: Default Discovery Mode (2,000+ Audios Architecture) ───
                  else ...[
                    // 1. Featured Ministers Spotlight Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ministers & Preachers',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Tap any minister to filter their complete sermon catalog',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 110,
                              child: Builder(
                                builder: (context) {
                                  final displayMinisters = playerService.ministers.isNotEmpty
                                      ? playerService.ministers
                                      : _ministers;

                                  return ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: displayMinisters.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                                    itemBuilder: (context, idx) {
                                      final m = displayMinisters[idx];
                                      final name = m['name']?.toString() ?? 'Minister';
                                      final avatar = (m['avatarUrl'] ?? m['avatar'])?.toString() ??
                                          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80';

                                      return GestureDetector(
                                        onTap: () {
                                          _searchController.text = name;
                                          setState(() {
                                            _searchQuery = name;
                                          });
                                        },
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(2.5),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: const LinearGradient(
                                                  colors: [AppColors.primary, Color(0xFF991B1B)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary.withValues(alpha: 0.25),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: ClipOval(
                                                child: CachedNetworkImage(
                                                  imageUrl: avatar,
                                                  width: 56,
                                                  height: 56,
                                                  fit: BoxFit.cover,
                                                  errorWidget: (_, __, ___) => Container(
                                                    width: 56,
                                                    height: 56,
                                                    color: AppColors.surfaceLight,
                                                    child: const Icon(Icons.person, color: AppColors.textMuted),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            SizedBox(
                                              width: 78,
                                              child: Text(
                                                name.split(' ').take(2).join(' '),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. 🔥 Trending & Direct-Play Audios Shelf
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '🔥 Trending Faith Releases',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${playerService.allTracks.length} available',
                                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 180,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: playerService.allTracks.take(8).length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, idx) {
                                  final track = playerService.allTracks[idx];
                                  final isCurrent = playerService.currentTrack?.id == track.id;
                                  final isPlaying = isCurrent && playerService.isPlaying;

                                  return Container(
                                    width: 140,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isCurrent ? AppColors.primary : AppColors.glassBorder,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        if (isCurrent) {
                                          playerService.togglePlayPause();
                                        } else {
                                          playerService.playTrack(track);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: CachedNetworkImage(
                                                    imageUrl: track.albumArtUrl,
                                                    height: 95,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                    errorWidget: (_, __, ___) => Container(
                                                      height: 95,
                                                      color: AppColors.surfaceLight,
                                                      child: const Icon(Icons.music_note, color: Colors.white54),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 6,
                                                  right: 6,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withValues(alpha: 0.5),
                                                          blurRadius: 6,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Icon(
                                                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              track.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isCurrent ? AppColors.primary : Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              track.artist,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
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
                    ),

                    // 3. 📚 Sermon Series & Albums (Handles Multi-Part Sermons)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📚 Featured Sermon Series',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Complete multi-part spiritual revelation teachings',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 120,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _buildSeriesCard(
                                    title: 'Critical Mind Series',
                                    minister: 'Pastor Martins Omonua',
                                    partsCount: '3 Parts',
                                    accentColor: const Color(0xFF6366F1),
                                    onTap: () {
                                      _searchController.text = 'Critical Mind';
                                      setState(() => _searchQuery = 'Critical Mind');
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  _buildSeriesCard(
                                    title: 'Divine Direction & Wisdom',
                                    minister: 'Pastor Martins Omonua',
                                    partsCount: '4 Parts',
                                    accentColor: const Color(0xFFEC4899),
                                    onTap: () {
                                      _searchController.text = 'Divine Direction';
                                      setState(() => _searchQuery = 'Divine Direction');
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  _buildSeriesCard(
                                    title: 'Atmosphere of Glory & Deep Worship',
                                    minister: 'LCM Worship Sanctuary',
                                    partsCount: '6 Chants',
                                    accentColor: const Color(0xFFF59E0B),
                                    onTap: () {
                                      _searchController.text = 'Worship';
                                      setState(() => _searchQuery = 'Worship');
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 4. 🕊️ Browse by Life Need & Topic (Color Grid)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🕊️ Browse by Spiritual Need',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Curated themes tuned to your daily spiritual focus',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Grid of Intent Tiles
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.25,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final intent = intents[index];
                            final trackCount = playerService.allTracks
                                .where((t) => t.matchesCategoryKey(intent.categoryKey))
                                .length;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => IntentPlaylistScreen(intent: intent),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.glassBorder),
                                  gradient: LinearGradient(
                                    colors: [
                                      intent.accentColor.withValues(alpha: 0.22),
                                      AppColors.surface,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: intent.accentColor.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        intent.icon,
                                        color: intent.accentColor,
                                        size: 20,
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          intent.title,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$trackCount sermons & tracks',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: intents.length,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeriesCard({
    required String title,
    required String minister,
    required String partsCount,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.4)),
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.18),
              AppColors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    partsCount.toUpperCase(),
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white54, size: 16),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  minister,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
