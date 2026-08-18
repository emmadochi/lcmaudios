import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lcm_audios_app/services/audio_player_service.dart';
import 'package:lcm_audios_app/services/theme_service.dart';
import 'package:lcm_audios_app/features/partner/widgets/paystack_checkout_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PaystackCheckoutSheet renders email and phone number inputs', (WidgetTester tester) async {
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
          home: Scaffold(
            body: PaystackCheckoutSheet(
              planType: 'monthly',
              amount: 2500,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify presence of Phone Number input & Email input
    expect(find.text('DONOR EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('PHONE NUMBER (SMS CONFIRMATION & RECEIPT)'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(5)); // Email, Phone, Card Number, Expiry, CVV

    // Verify phone controller default value can be edited
    final phoneFinder = find.widgetWithText(TextField, '+234 801 234 5678');
    expect(phoneFinder, findsOneWidget);

    await tester.enterText(phoneFinder, '+234 809 999 8888');
    await tester.pump();

    expect(find.text('+234 809 999 8888'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
