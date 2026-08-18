import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lcm_audios_app/core/theme/app_theme.dart';
import 'package:lcm_audios_app/services/theme_service.dart';
import 'package:lcm_audios_app/services/audio_player_service.dart';
import 'package:lcm_audios_app/features/premium/screens/premium_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PremiumScreen renders properly in Light Mode', (WidgetTester tester) async {
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
          home: const PremiumScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Hero Banner
    expect(find.text('Covenant Partner'), findsOneWidget);
    expect(find.text('Unlock Faith Unlimited'), findsOneWidget);
    expect(find.text('Upgrade Now via Paystack'), findsOneWidget);

    // Verify Plan Selectors
    expect(find.text('SELECT KINGDOM SEED PLAN'), findsOneWidget);
    expect(find.text('Monthly Seed'), findsOneWidget);
    expect(find.text('Annual Covenant'), findsOneWidget);

    // Verify Partnership Privileges
    expect(find.text('PARTNERSHIP PRIVILEGES'), findsOneWidget);
    expect(find.text('Unrestricted Exclusive Catalog'), findsOneWidget);
    expect(find.text('Unlimited AES-256 DRM Downloads'), findsOneWidget);

    // Switch plan selection
    await tester.tap(find.text('Monthly Seed'));
    await tester.pumpAndSettle();

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('PremiumScreen renders properly in Dark Mode', (WidgetTester tester) async {
    final themeService = ThemeService();
    final audioService = AudioPlayerService();
    await themeService.setThemeMode(ThemeMode.dark);

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
          themeMode: ThemeMode.dark,
          home: const PremiumScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Covenant Partner'), findsOneWidget);
    expect(find.text('Unlock Faith Unlimited'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
