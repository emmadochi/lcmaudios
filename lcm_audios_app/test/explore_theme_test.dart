import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lcm_audios_app/core/theme/app_theme.dart';
import 'package:lcm_audios_app/services/theme_service.dart';
import 'package:lcm_audios_app/services/audio_player_service.dart';
import 'package:lcm_audios_app/features/explore/screens/explore_screen.dart';
import 'package:lcm_audios_app/features/explore/screens/intent_playlist_screen.dart';
import 'package:lcm_audios_app/core/models/spiritual_intent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ExploreScreen renders properly in Light Mode without color conflicts', (WidgetTester tester) async {
    final themeService = ThemeService();
    final audioService = AudioPlayerService();
    await themeService.setThemeMode(ThemeMode.light);

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeService),
          ChangeNotifierProvider.value(value: audioService),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: const ExploreScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Header & Filters in Light Mode
    expect(find.text('Explore & Search'), findsOneWidget);
    expect(find.text('Ministers & Preachers'), findsOneWidget);
    expect(find.text('🔥 Trending Faith Releases'), findsOneWidget);

    // Verify Search Box and Filter Chips
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Sermons'), findsOneWidget);
    expect(find.text('Worship'), findsOneWidget);

    // Tap a filter chip
    await tester.tap(find.text('Worship'));
    await tester.pumpAndSettle();

    // Reset filter to All
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    // Scroll down to reveal Sermon Series and Spiritual Need
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('📚 Featured Sermon Series'), findsOneWidget);
    expect(find.text('🕊️ Browse by Spiritual Need'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('IntentPlaylistScreen renders properly in Light Mode', (WidgetTester tester) async {
    final themeService = ThemeService();
    final audioService = AudioPlayerService();
    await themeService.setThemeMode(ThemeMode.light);

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    final sampleIntent = SpiritualIntent(
      categoryKey: 'deepWorship',
      title: 'Deep Worship & Chants',
      description: 'Atmosphere of intimate communion',
      icon: Icons.music_note_rounded,
      accentColor: const Color(0xFF8B5CF6),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeService),
          ChangeNotifierProvider.value(value: audioService),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: IntentPlaylistScreen(intent: sampleIntent),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deep Worship & Chants'), findsOneWidget);
    expect(find.text('Play Intent'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
