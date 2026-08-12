import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_colors.dart';
import 'services/audio_player_service.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/explore/screens/explore_screen.dart';
import 'features/library/screens/library_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/premium/screens/premium_screen.dart';
import 'features/player/widgets/mini_player_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        home: const AuthScreen(),
      ),
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

          // Floating Player + Bottom Navigation Bar Container
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Floating Audio Player Card
              const MiniPlayerBar(),

              // 5-Item Custom Bottom Navigation Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF141722).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.glassBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BottomNavigationBar(
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
