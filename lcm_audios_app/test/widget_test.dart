import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lcm_audios_app/main.dart';
import 'package:lcm_audios_app/services/audio_player_service.dart';
import 'package:lcm_audios_app/services/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LCM Audios App initializes and renders without crashes', (WidgetTester tester) async {
    final themeService = ThemeService();
    final audioService = AudioPlayerService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeService),
          ChangeNotifierProvider.value(value: audioService),
        ],
        child: const LcmAudiosApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('MainNavigationShell renders bottom navigation bar and tabs', (WidgetTester tester) async {
    final themeService = ThemeService();
    final audioService = AudioPlayerService();

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeService),
          ChangeNotifierProvider.value(value: audioService),
        ],
        child: const MaterialApp(
          home: MainNavigationShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final navBarFinder = find.byType(BottomNavigationBar);
    expect(navBarFinder, findsOneWidget);
    expect(find.descendant(of: navBarFinder, matching: find.text('Home')), findsOneWidget);
    expect(find.descendant(of: navBarFinder, matching: find.text('Explore')), findsOneWidget);
    expect(find.descendant(of: navBarFinder, matching: find.text('Library')), findsOneWidget);
    expect(find.descendant(of: navBarFinder, matching: find.text('Profile')), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
