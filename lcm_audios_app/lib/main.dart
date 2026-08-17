import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_colors.dart';
import 'services/audio_player_service.dart';
import 'services/notification_service.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/explore/screens/explore_screen.dart';
import 'features/library/screens/library_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/premium/screens/premium_screen.dart';
import 'features/player/widgets/mini_player_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const LcmAudiosApp());
}

class LcmAudiosApp extends StatelessWidget {
  const LcmAudiosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AudioPlayerService(),
      child: MaterialApp(
        title: 'LCM Audios — Faith in Motion',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.dark().textTheme,
          ),
        ),
        home: const AppEntryPoint(),
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

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    LibraryScreen(),
    ProfileScreen(),
    PremiumScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF141722).withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: showMiniPlayer
                        ? AppColors.primary.withValues(alpha: 0.45)
                        : AppColors.glassBorder.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: showMiniPlayer
                          ? AppColors.primaryGlow.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.5),
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
                          unselectedItemColor: Colors.white54,
                          selectedFontSize: 11,
                          unselectedFontSize: 11,
                          type: BottomNavigationBarType.fixed,
                          onTap: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
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
