import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_links/app_links.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'services/audio_player_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/explore/screens/explore_screen.dart';
import 'features/library/screens/library_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/premium/screens/premium_screen.dart';
import 'features/player/widgets/mini_player_bar.dart';
import 'features/player/screens/full_player_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('[FCM] Handling background message: ${message.messageId}');
  } catch (e) {
    debugPrint('[FCM] Background handler error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[Firebase] Init error: $e');
  }
  await NotificationService().init();
  await ThemeService().init();
  runApp(const LcmAudiosApp());
}

class LcmAudiosApp extends StatelessWidget {
  const LcmAudiosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioPlayerService()),
        ChangeNotifierProvider.value(value: ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'LCM Audios — Faith in Motion',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            home: const AppEntryPoint(),
          );
        },
      ),
    );
  }
}

class AppEntryPoint extends StatelessWidget {
  const AppEntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        if (!playerService.isAuthInitialized) {
          return Scaffold(
            backgroundColor: AppColors.bg(context),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.headphones_rounded,
                      size: 38,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!playerService.hasCompletedOnboarding) {
          return const OnboardingScreen();
        }

        if (playerService.isAuthenticated) {
          return const MainNavigationShell();
        }
        return const AuthScreen();
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late final AppLinks _appLinks;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    LibraryScreen(),
    ProfileScreen(),
    PremiumScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinkHandler();
  }

  /// Handles incoming deep links — both cold start and while running.
  void _initDeepLinkHandler() {
    _appLinks = AppLinks();

    // Handle link that launched the app from a cold start
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });

    // Handle links while app is already running (foregrounded)
    _appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLink(uri),
      onError: (e) => debugPrint('[DeepLink] Stream error: $e'),
    );
  }

  /// Routes a parsed deep link URI to the correct track.
  ///
  /// Supported formats:
  ///   https://lcmaudios.app/track/{trackId}
  ///   lcmaudios://track/{trackId}
  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('[DeepLink] Received: $uri');

    String? trackId;

    // HTTPS scheme: /track/{trackId}
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host == 'lcmaudios.app' &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments[0] == 'track') {
      trackId = uri.pathSegments[1];
    }

    // Custom scheme: lcmaudios://track/{trackId}
    else if (uri.scheme == 'lcmaudios' && uri.host == 'track') {
      trackId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    }

    if (trackId == null || trackId.isEmpty) {
      debugPrint('[DeepLink] No valid trackId found in $uri');
      return;
    }

    debugPrint('[DeepLink] Opening track: $trackId');

    if (!mounted) return;
    final playerService = Provider.of<AudioPlayerService>(context, listen: false);

    // Try to find track in current catalog
    final tracks = playerService.allTracks;
    final target = tracks.where((t) => t.id == trackId).firstOrNull;

    if (target != null) {
      await playerService.playTrack(target);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
        );
      }
    } else {
      // Track not in local cache — force a catalog sync then try again
      await playerService.syncCatalogSilently(force: true);
      final refreshedTarget = playerService.allTracks.where((t) => t.id == trackId).firstOrNull;
      if (refreshedTarget != null && mounted) {
        await playerService.playTrack(refreshedTarget);
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
          );
        }
      } else {
        debugPrint('[DeepLink] Track $trackId not found even after catalog sync.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This sermon link could not be found. It may have been removed.'),
              backgroundColor: Color(0xFF1E2338),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Tier 1: Proactively sync catalog whenever user returns to the app
      Provider.of<AudioPlayerService>(context, listen: false).syncCatalogSilently();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Unified Integrated Player & Bottom Navigation Dock
          Consumer<AudioPlayerService>(
            builder: (context, playerService, child) {
              final track = playerService.currentTrack;
              final bool showMiniPlayer = track != null && !playerService.isMiniPlayerDismissed;

              final dockBackground = isDark
                  ? const Color(0xFF141722).withValues(alpha: 0.98)
                  : Colors.white.withValues(alpha: 0.96);

              final dockBorderColor = showMiniPlayer
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : (isDark
                      ? AppColors.glassBorder.withValues(alpha: 0.8)
                      : AppColors.lightGlassBorder.withValues(alpha: 0.9));

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: dockBackground,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: dockBorderColor,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: showMiniPlayer
                          ? AppColors.primaryGlow.withValues(alpha: isDark ? 0.3 : 0.15)
                          : (isDark ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.08)),
                      blurRadius: 20,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOutCubic,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Integrated Mini Player Bar (collapses smoothly when dismissed or stopped)
                        if (showMiniPlayer)
                          const MiniPlayerBar(),

                        // 5-Item Custom Bottom Navigation Bar
                        BottomNavigationBar(
                          currentIndex: _currentIndex,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          selectedItemColor: AppColors.primary,
                          unselectedItemColor: isDark ? Colors.white54 : const Color(0xFF64748B),
                          selectedFontSize: 11,
                          unselectedFontSize: 11,
                          type: BottomNavigationBarType.fixed,
                          onTap: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                            // Proactively sync catalog on tab navigation
                            playerService.syncCatalogSilently();
                          },
                          items: const [
                            BottomNavigationBarItem(
                              icon: Icon(Icons.home_filled),
                              label: 'Home',
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.explore_outlined),
                              label: 'Explore',
                            ),
                            BottomNavigationBarItem(
                              icon: Badge(
                                label: Text('↓', style: TextStyle(fontSize: 9, color: Colors.white)),
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.library_books_rounded),
                              ),
                              label: 'Library',
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.person_outline_rounded),
                              label: 'Profile',
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.diamond_outlined),
                              label: 'Premium',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
