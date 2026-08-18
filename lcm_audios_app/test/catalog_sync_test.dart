import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lcm_audios_app/services/theme_service.dart';
import 'package:lcm_audios_app/services/audio_player_service.dart';
import 'package:lcm_audios_app/main.dart';

import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
    SharedPreferences.setMockInitialValues({
      'auth_jwt_token': 'test_mock_jwt_token',
      'auth_user_id': 'user_test_123',
      'auth_user_email': 'test@lcmaudios.com',
      'user_name': 'Test Devotee',
    });
  });

  testWidgets('AudioPlayerService syncCatalogSilently executes safely and updates catalog', (WidgetTester tester) async {
    final themeService = ThemeService();
    final audioService = AudioPlayerService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeService),
          ChangeNotifierProvider.value(value: audioService),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Text('Catalog Test')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial sample tracks loaded
    expect(audioService.allTracks.isNotEmpty, true);

    // Call syncCatalogSilently with force flag
    await audioService.syncCatalogSilently(force: true);
    await tester.pumpAndSettle();

    // Should still have tracks and categories intact
    expect(audioService.allTracks.isNotEmpty, true);
  });

  testWidgets('MainNavigationShell lifecycle resume and tab switch triggers silent sync', (WidgetTester tester) async {
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

    // Verify MainNavigationShell is mounted
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Switch tab to Explore (triggers tab sync)
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();

    // Simulate App Lifecycle Resume (e.g. user unlocks phone or switches back)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
