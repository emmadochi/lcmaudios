import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/spiritual_intent.dart';
import '../../../core/models/audio_track.dart';
import '../../../services/audio_player_service.dart';
import '../../../services/theme_service.dart';
import '../../partner/widgets/covenant_partner_paywall_sheet.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onExploreTap;
  const HomeScreen({super.key, this.onExploreTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning, $name 🙏';
    if (hour < 17) return 'Good Afternoon, $name 🙏';
    return 'Good Evening, $name 🙏';
  }

  void _showSearchDialog(BuildContext context, AudioPlayerService playerService) {
    String selectedFilter = 'All';
    bool showFilterRow = false;
    final filterChips = ['All', 'Sermons', 'Worship', 'Warfare', 'Prayer', 'Downloaded', 'With Notes'];
    final quickSuggestions = [
      'Pastor Martins Omonua',
      'Deep Worship',
      'Warfare & Deliverance',
      'Atmosphere of Grace',
    ];

    String formatDuration(Duration d) {
      final m = d.inMinutes.toString().padLeft(2, '0');
      final s = (d.inSeconds % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = AppColors.isDarkMode(context);
          final query = _searchQuery.trim().toLowerCase();

          // Filter tracks based on query and selected category chip
          final List<Map<String, dynamic>> searchResultsWithMetadata = [];

          for (final track in playerService.allTracks) {
            // Check chip filter
            bool passesChipFilter = true;
            switch (selectedFilter) {
              case 'Sermons':
                passesChipFilter = track.subgenre.toLowerCase().contains('sermon') ||
                    track.subgenre.toLowerCase().contains('apostle') ||
                    track.intentCategory == IntentCategory.studyFocus;
                break;
              case 'Worship':
                passesChipFilter = track.intentCategory == IntentCategory.deepWorship ||
                    track.subgenre.toLowerCase().contains('worship') ||
                    track.subgenre.toLowerCase().contains('chant');
                break;
              case 'Warfare':
                passesChipFilter = track.intentCategory == IntentCategory.warfarePrayers ||
                    track.subgenre.toLowerCase().contains('warfare') ||
                    track.subgenre.toLowerCase().contains('deliverance');
                break;
              case 'Prayer':
                passesChipFilter = track.intentCategory == IntentCategory.warfarePrayers ||
                    track.subgenre.toLowerCase().contains('prayer') ||
                    track.subgenre.toLowerCase().contains('intercession');
                break;
              case 'Downloaded':
                passesChipFilter = track.isDownloaded;
                break;
              case 'With Notes':
                passesChipFilter = track.notes.isNotEmpty;
                break;
              case 'All':
              default:
                passesChipFilter = true;
            }

            if (!passesChipFilter) continue;

            // If query is empty, add all tracks matching chip filter
            if (query.isEmpty) {
              searchResultsWithMetadata.add({
                'track': track,
                'matchedLyric': null,
              });
              continue;
            }

            // Deep text matching: Title, Artist, Subgenre, Intent
            final titleMatch = track.title.toLowerCase().contains(query);
            final artistMatch = track.artist.toLowerCase().contains(query);
            final subgenreMatch = track.subgenre.toLowerCase().contains(query);
            final categoryMatch = track.intentCategory.name.toLowerCase().contains(query);

            // Lyrics search
            String? matchedLyricText;
            for (final lyric in track.lyrics) {
              if (lyric.text.toLowerCase().contains(query)) {
                matchedLyricText = lyric.text;
                break;
              }
            }

            if (titleMatch || artistMatch || subgenreMatch || categoryMatch || matchedLyricText != null) {
              searchResultsWithMetadata.add({
                'track': track,
                'matchedLyric': matchedLyricText,
              });
            }
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Handle & Header
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Search & Discover',
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: AppColors.muted(context), size: 22),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Input Field with Progressive Filter Trigger
                TextField(
                  controller: _searchController,
                  autofocus: false,
                  style: TextStyle(color: AppColors.text(context), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search sermons, worship, ministers, lyrics...',
                    hintStyle: TextStyle(color: AppColors.muted(context), fontSize: 13),
                    filled: true,
                    fillColor: AppColors.cardAlt(context),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.cancel_rounded, color: AppColors.muted(context), size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setModalState(() {
                                _searchQuery = '';
                              });
                            },
                          ),
                        IconButton(
                          tooltip: showFilterRow ? 'Hide Categories' : 'Filter by Category',
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                showFilterRow ? Icons.tune_rounded : Icons.filter_list_rounded,
                                color: (selectedFilter != 'All' || showFilterRow)
                                    ? AppColors.primary
                                    : AppColors.muted(context),
                                size: 20,
                              ),
                              if (selectedFilter != 'All')
                                Positioned(
                                  right: -1,
                                  top: -1,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onPressed: () {
                            setModalState(() {
                              showFilterRow = !showFilterRow;
                            });
                          },
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (val) {
                    setModalState(() {
                      _searchQuery = val;
                    });
                  },
                ),

                // Progressive Disclosure: Filter Chips Row (expanded on demand or when filter active)
                if (showFilterRow || selectedFilter != 'All') ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filterChips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final chip = filterChips[index];
                        final isSelected = selectedFilter == chip;
                        return ChoiceChip(
                          label: Text(
                            chip,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.subtext(context),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.cardAlt(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border(context),
                            ),
                          ),
                          onSelected: (selected) {
                            setModalState(() {
                              selectedFilter = chip;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Quick Discovery Suggestion Tags (if search query is empty)
                if (_searchQuery.isEmpty) ...[
                  Text(
                    'POPULAR TOPICS',
                    style: TextStyle(
                      color: AppColors.muted(context),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: quickSuggestions.map((suggestion) {
                      return InkWell(
                        onTap: () {
                          _searchController.text = suggestion;
                          setModalState(() {
                            _searchQuery = suggestion;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.cardAlt(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border(context)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 12),
                              const SizedBox(width: 5),
                              Text(
                                suggestion,
                                style: TextStyle(color: AppColors.subtext(context), fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],

                // Results Counter Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${searchResultsWithMetadata.length} Tracks ${selectedFilter != 'All' ? '($selectedFilter)' : ''}',
                      style: TextStyle(
                        color: AppColors.subtext(context),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      InkWell(
                        onTap: () {
                          _searchController.clear();
                          setModalState(() {
                            _searchQuery = '';
                            selectedFilter = 'All';
                          });
                        },
                        child: const Text(
                          'Reset Filters',
                          style: TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Search Results List View
                Expanded(
                  child: searchResultsWithMetadata.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, color: AppColors.muted(context).withValues(alpha: 0.4), size: 48),
                              const SizedBox(height: 10),
                              Text(
                                'No matching tracks found',
                                style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try another keyword, preacher name or spiritual intent.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: searchResultsWithMetadata.length,
                          itemBuilder: (context, index) {
                            final item = searchResultsWithMetadata[index];
                            final AudioTrack track = item['track'];
                            final String? matchedLyric = item['matchedLyric'];
                            final isCurrentlyActive = playerService.currentTrack?.id == track.id;
                            final isPlaying = isCurrentlyActive && playerService.isPlaying;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isCurrentlyActive
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : (isDark ? AppColors.surfaceLight : AppColors.card(context)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isCurrentlyActive
                                      ? AppColors.primary.withValues(alpha: 0.6)
                                      : AppColors.border(context),
                                ),
                                boxShadow: isDark ? [] : [
                                  BoxShadow(
                                    color: AppColors.shadow(context),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: track.albumArtUrl,
                                    width: 48,
                                    height: 48,
                                    memCacheWidth: 150,
                                    memCacheHeight: 150,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      width: 48,
                                      height: 48,
                                      color: AppColors.cardAlt(context),
                                      child: Icon(Icons.music_note, color: AppColors.muted(context)),
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        track.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isCurrentlyActive ? AppColors.primary : AppColors.text(context),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ),
                                    if (track.isPremium) ...[
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () => CovenantPartnerPaywallSheet.show(
                                          context,
                                          sourceFeature: track.title,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFFFDF79), Color(0xFFD4AF37)],
                                            ),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            '👑 EXCLUSIVE',
                                            style: TextStyle(
                                              color: Color(0xFF140D1E),
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (track.isDownloaded) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.download_done_rounded, color: Color(0xFF10B981), size: 14),
                                    ],
                                    if (track.notes.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${track.notes.length} notes',
                                          style: const TextStyle(color: AppColors.secondary, fontSize: 9.5, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      '${track.artist} • ${track.subgenre} • ${formatDuration(track.duration)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: AppColors.subtext(context), fontSize: 11.5),
                                    ),
                                    if (matchedLyric != null) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 11),
                                          const SizedBox(width: 3),
                                          Expanded(
                                            child: Text(
                                              '"$matchedLyric"',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: AppColors.subtext(context).withValues(alpha: 0.9),
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    isPlaying
                                        ? Icons.pause_circle_filled_rounded
                                        : Icons.play_circle_fill_rounded,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                                  onPressed: () {
                                    if (isCurrentlyActive) {
                                      playerService.togglePlayPause();
                                    } else {
                                      playerService.playTrack(track);
                                    }
                                    Navigator.pop(ctx);
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final intents = playerService.categories
            .where((i) => i.categoryKey.toLowerCase() != 'all')
            .toList();
        final filteredTracks = playerService.filteredTracks;

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            elevation: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logoIcon.png',
                  height: 32,
                  width: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.headphones_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'LCM AUDIOS',
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              // Theme Mode Quick Toggle
              Consumer<ThemeService>(
                builder: (context, themeService, _) {
                  final isDark = AppColors.isDarkMode(context);
                  return IconButton(
                    tooltip: isDark ? 'Switch to Daylight Mode' : 'Switch to Midnight Mode',
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => RotationTransition(
                        turns: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Container(
                        key: ValueKey(isDark),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
                          ),
                        ),
                        child: Icon(
                          isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                          color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF8B5CF6),
                          size: 18,
                        ),
                      ),
                    ),
                    onPressed: () => themeService.toggleTheme(),
                  );
                },
              ),
              InkWell(
                onTap: () => CovenantPartnerPaywallSheet.show(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFDF79), Color(0xFFD4AF37)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: Color(0xFF140D1E), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        playerService.isCovenantPartner ? 'PARTNER' : 'GO GOLD',
                        style: const TextStyle(
                          color: Color(0xFF140D1E),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => playerService.refreshAll(),
            color: AppColors.primary,
            backgroundColor: AppColors.card(context),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sleek, Minimalist User Greeting & Spiritual Anchor
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(playerService.userName),
                          style: TextStyle(
                            color: AppColors.text(context),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '“Thy word is a lamp unto my feet, and a light unto my path.”',
                          style: TextStyle(
                            color: AppColors.muted(context),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── Prominent Quick Search Bar ───────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: InkWell(
                      onTap: () => _showSearchDialog(context, playerService),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border(context)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow(context),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Search sermons, ministers, worship, chants...',
                                style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.cardAlt(context),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.tune_rounded, color: AppColors.subtext(context), size: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const SizedBox(height: 10),

                  // ─── Hero Area: Continue Listening OR Daily Devotion ───────
                  if (playerService.lastPlayedTrack != null &&
                      playerService.lastPlayedPosition.inSeconds > 10) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildContinueListeningCard(context, playerService),
                    ),
                    const SizedBox(height: 14),
                  ] else if (playerService.allTracks.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildDailyDevotionHeroCard(context, playerService),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ─── Offline Sanctuary Vault Hero (Prioritized When Offline) ─
                  if (!playerService.isOnline || playerService.isOfflineModeOnly) ...[
                    _buildOfflineSanctuaryHero(context, playerService),
                    const SizedBox(height: 14),
                  ],

                  // ─── Fast Category Filter Chips (Spiritual Intent Selector) ─
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildCategoryPill(
                          label: '✨ All Fresh Manna',
                          isSelected: playerService.selectedCategoryKey == 'all',
                          onTap: () => playerService.setCategoryFilter('all'),
                        ),
                        ...intents.map((intent) {
                          final isSelected = playerService.selectedCategoryKey == intent.categoryKey;
                          return _buildCategoryPill(
                            label: intent.title,
                            isSelected: isSelected,
                            onTap: () => playerService.setCategoryFilter(intent.categoryKey),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Featured Media Streams Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            playerService.selectedCategoryKey == 'all'
                                ? 'Featured Faith Streams'
                                : '${playerService.selectedCategoryKey.toUpperCase()} STREAMS',
                            style: TextStyle(
                              color: AppColors.text(context),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${filteredTracks.length} Tracks',
                          style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  // Media Stream List
                  filteredTracks.isEmpty
                      ? Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border(context)),
                          ),
                          child: Center(
                            child: Text(
                              'No tracks found in this category yet. Pull down to refresh or upload new sermons in the Admin Portal!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          itemCount: filteredTracks.length,
                          itemBuilder: (ctx, index) {
                            final isDark = AppColors.isDarkMode(context);
                            final track = filteredTracks[index];
                            final isCurrentPlaying = (playerService.currentTrack?.id == track.id);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isCurrentPlaying
                                    ? (isDark ? AppColors.surfaceLight : const Color(0xFFFEE2E2).withValues(alpha: 0.7))
                                    : AppColors.card(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isCurrentPlaying ? AppColors.primary : AppColors.border(context),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: track.albumArtUrl,
                                    width: 50,
                                    height: 50,
                                    memCacheWidth: 150,
                                    memCacheHeight: 150,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      width: 50,
                                      height: 50,
                                      color: AppColors.cardAlt(context),
                                      child: Icon(Icons.music_note, color: AppColors.muted(context)),
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        track.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isCurrentPlaying ? AppColors.primary : AppColors.text(context),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (track.isPremium) ...[
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => CovenantPartnerPaywallSheet.show(
                                          context,
                                          sourceFeature: track.title,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFFFDF79), Color(0xFFD4AF37)],
                                            ),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            '👑 EXCLUSIVE',
                                            style: TextStyle(
                                              color: Color(0xFF140D1E),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  '${track.artist} • ${track.subgenre}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.subtext(context),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    isCurrentPlaying && playerService.isPlaying
                                        ? Icons.pause_circle_rounded
                                        : Icons.play_circle_fill_rounded,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                                  onPressed: () {
                                    if (isCurrentPlaying) {
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

                  // ─── Discovery Bridge to Explore Tab ──────────────────────
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border(context)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow(context),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.explore_outlined, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Looking for more ministers & archives?',
                                style: TextStyle(
                                  color: AppColors.text(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Explore Apostle sermons, choir recordings & topic archives.',
                                style: TextStyle(
                                  color: AppColors.muted(context),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => widget.onExploreTap?.call(),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Explore', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 120), // Bottom padding for floating player bar
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyDevotionHeroCard(BuildContext context, AudioPlayerService playerService) {
    final track = playerService.allTracks.first;
    final isCurrentlyActive = playerService.currentTrack?.id == track.id;
    final isPlaying = isCurrentlyActive && playerService.isPlaying;
    final isDark = AppColors.isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.surfaceLight, AppColors.surface]
              : [Colors.white, const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: track.albumArtUrl,
              width: 58,
              height: 58,
              memCacheWidth: 180,
              memCacheHeight: 180,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 58,
                height: 58,
                color: AppColors.cardAlt(context),
                child: const Icon(Icons.wb_sunny_rounded, color: AppColors.primary, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'DAILY BREAD & DEVOTION',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.text(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${track.artist} • ${track.subgenre}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.subtext(context),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              if (isCurrentlyActive) {
                playerService.togglePlayPause();
              } else {
                playerService.playTrack(track);
              }
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFFF5722)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueListeningCard(BuildContext context, AudioPlayerService playerService) {
    final track = playerService.lastPlayedTrack!;
    final pos = playerService.lastPlayedPosition;
    final totalDuration = track.duration > Duration.zero ? track.duration : const Duration(minutes: 5);
    final progress = (pos.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0);
    final isCurrentlyActive = playerService.currentTrack?.id == track.id;
    final isPlaying = isCurrentlyActive && playerService.isPlaying;
    final isDark = AppColors.isDarkMode(context);

    String formatTime(Duration d) {
      final m = d.inMinutes.toString().padLeft(2, '0');
      final s = (d.inSeconds % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.surfaceLight,
                  AppColors.surface,
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8FAFC),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.border(context),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.shadow(context),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.history_rounded, color: AppColors.primary, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'CONTINUE LISTENING',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${formatTime(pos)} / ${formatTime(totalDuration)}',
                  style: TextStyle(color: AppColors.muted(context), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: track.albumArtUrl,
                    width: 52,
                    height: 52,
                    memCacheWidth: 150,
                    memCacheHeight: 150,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 52,
                      height: 52,
                      color: AppColors.cardAlt(context),
                      child: Icon(Icons.music_note, color: AppColors.muted(context)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${track.artist} • ${track.subgenre}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.subtext(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    if (isCurrentlyActive) {
                      playerService.togglePlayPause();
                    } else {
                      playerService.resumeTrack(track, startAt: pos);
                    }
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFFFF5722)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGlow,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final isDark = AppColors.isDarkMode(context);

        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.surface : AppColors.card(context)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border(context),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : (isDark
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.shadow(context),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.subtext(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOfflineSanctuaryHero(BuildContext context, AudioPlayerService playerService) {
    final isDark = AppColors.isDarkMode(context);
    final downloaded = playerService.downloadedTracks;

    if (downloaded.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1430) : const Color(0xFFF5EEFD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, color: Color(0xFFFFDF79), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Offline Sanctuary Mode',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFFFDF79),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'You are offline. Connect to the internet or download sermons to listen anywhere.',
                    style: TextStyle(fontSize: 11.5, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181326) : const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_rounded, color: Color(0xFFFFDF79), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Offline Vault',
                          style: TextStyle(
                            color: Color(0xFFFFDF79),
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${downloaded.length} READY',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'AES-256 Encrypted • Instant Playback',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: downloaded.length,
              itemBuilder: (context, idx) {
                final track = downloaded[idx];
                final isCurrent = playerService.currentTrack?.id == track.id;
                final isPlaying = isCurrent && playerService.isPlaying;

                return Container(
                  width: 240,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary.withValues(alpha: 0.25)
                        : (isDark ? const Color(0xFF221A38) : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.primary
                          : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
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
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: track.albumArtUrl,
                            width: 50,
                            height: 50,
                            memCacheWidth: 150,
                            memCacheHeight: 150,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 50,
                              height: 50,
                              color: const Color(0xFF2E2248),
                              child: const Icon(Icons.music_note, color: Color(0xFFFFDF79), size: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrent ? const Color(0xFFFFDF79) : (isDark ? Colors.white : Colors.black87),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                          color: const Color(0xFFFFDF79),
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
