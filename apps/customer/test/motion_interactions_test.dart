import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo/features/profile/presentation/screens/settings_screen.dart';
import 'package:kaylo/features/profile/presentation/widgets/kaylo_secret.dart';
import 'package:kaylo/core/widgets/liquid_tab_bar.dart';
import 'package:kaylo/features/auth/application/current_user_provider.dart';
import 'package:kaylo/l10n/generated/app_localizations.dart';
import 'package:kaylo_core/services/sound_service.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'version opens the secret on exactly the fifth tap and can close',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final sounds = SilentSoundService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentUserProvider.overrideWithValue(null),
            soundServiceProvider.overrideWithValue(sounds),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('1.0.0'));
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('1.0.0'));
        await tester.pump(const Duration(milliseconds: 80));
      }
      expect(find.byType(KayloSecret), findsNothing);
      await tester.tap(find.text('1.0.0'));
      await tester.pumpAndSettle();
      expect(find.byType(KayloSecret), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Four rising notes on the way in, then the bell as the mark lands.
      expect(sounds.played, [
        ...KayloSound.notes.take(4),
        KayloSound.logoChime,
      ]);
      await tester.tap(find.byType(KayloSecret));
      await tester.pumpAndSettle();
      expect(sounds.played.last, KayloSound.note1);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(KayloSecret), findsNothing);
    },
  );
  testWidgets(
    'compact navbar remains tappable with reduced motion and large text',
    (tester) async {
      tester.view.physicalSize = const Size(960, 1704);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      var index = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
              textScaler: TextScaler.linear(2),
            ),
            child: StatefulBuilder(
              builder: (context, update) => Scaffold(
                bottomNavigationBar: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LiquidTabBar(
                    index: index,
                    labels: const [
                      'Home',
                      'Bookings',
                      'Care',
                      'Messages',
                      'Profile',
                    ],
                    onSelected: (value) => update(() => index = value),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.favorite_outline));
      await tester.pumpAndSettle();
      expect(index, 2);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
