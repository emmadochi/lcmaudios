import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lcm_audios_app/main.dart';
import 'package:lcm_audios_app/services/audio_player_service.dart';
import 'package:lcm_audios_app/features/auth/screens/auth_screen.dart';

void main() {
  testWidgets('LCM Audios App initializes and renders AuthScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const LcmAudiosApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets('MainNavigationShell renders bottom navigation bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AudioPlayerService(),
        child: const MaterialApp(
          home: MainNavigationShell(),
        ),
      ),
    );
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
