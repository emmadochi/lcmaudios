import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lcm_audios_app/core/theme/app_colors.dart';
import 'package:lcm_audios_app/core/theme/app_theme.dart';
import 'package:lcm_audios_app/services/theme_service.dart';
import 'package:lcm_audios_app/services/audio_player_service.dart';
import 'package:lcm_audios_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:lcm_audios_app/features/profile/screens/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeService Tests', () {
    test('Initializes with default dark mode', () async {
      final themeService = ThemeService();
      await themeService.init();
      expect(themeService.themeMode, equals(ThemeMode.dark));
      expect(themeService.isDarkMode, isTrue);
      expect(themeService.isLightMode, isFalse);
    });

    test('Toggling theme switches between dark and light', () async {
      final themeService = ThemeService();
      await themeService.setThemeMode(ThemeMode.dark);
      expect(themeService.isDarkMode, isTrue);

      await themeService.toggleTheme();
      expect(themeService.isLightMode, isTrue);
      expect(themeService.themeMode, equals(ThemeMode.light));

      await themeService.toggleTheme();
      expect(themeService.isDarkMode, isTrue);
    });

    test('Setting system theme mode persists', () async {
      final themeService = ThemeService();
      await themeService.setThemeMode(ThemeMode.system);
      expect(themeService.isSystemMode, isTrue);
    });
  });

  group('Theme Palette & Tokens Tests', () {
    testWidgets('AppTheme builds both light and dark ThemeData correctly', (WidgetTester tester) async {
      final darkTheme = AppTheme.darkTheme;
      final lightTheme = AppTheme.lightTheme;

      expect(darkTheme.brightness, equals(Brightness.dark));
      expect(darkTheme.scaffoldBackgroundColor, equals(AppColors.background));

      expect(lightTheme.brightness, equals(Brightness.light));
      expect(lightTheme.scaffoldBackgroundColor, equals(AppColors.lightBackground));
    });
  });

  group('Widget Theme Integration Tests', () {
    testWidgets('OnboardingScreen renders theme atmosphere selection cards', (WidgetTester tester) async {
      final themeService = ThemeService();
      final audioService = AudioPlayerService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeService),
            ChangeNotifierProvider.value(value: audioService),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            home: const OnboardingScreen(),
          ),
        ),
      );

      // Verify Welcome Step is rendered first
      expect(find.text('LCM AUDIOS'), findsOneWidget);
      expect(find.text('GET STARTED'), findsOneWidget);

      // Tap GET STARTED to advance to Theme Selection
      await tester.tap(find.text('GET STARTED'));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify Theme Selection Step is rendered
      expect(find.text('Choose Your Atmosphere'), findsOneWidget);
      expect(find.text('Midnight Vigil'), findsOneWidget);
      expect(find.text('Daylight Devotion'), findsOneWidget);
      expect(find.text('Match Device System'), findsOneWidget);

      // Tap Light Mode Card
      await tester.tap(find.text('Daylight Devotion'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(themeService.isLightMode, isTrue);
    });

    testWidgets('ProfileScreen renders 3-way segmented theme options and switches', (WidgetTester tester) async {
      final themeService = ThemeService();
      final audioService = AudioPlayerService();
      await themeService.setThemeMode(ThemeMode.dark);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeService),
            ChangeNotifierProvider.value(value: audioService),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            home: const ProfileScreen(),
          ),
        ),
      );

      // Verify theme header & options in profile
      expect(find.text('🎨 App Atmosphere & Visual Theme'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);

      // Tap Light pill
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(themeService.isLightMode, isTrue);
    });
  });
}
