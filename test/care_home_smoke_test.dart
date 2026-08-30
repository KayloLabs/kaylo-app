import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo/features/care/presentation/screens/care_home_screen.dart';
import 'package:kaylo/l10n/generated/app_localizations.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      );

  testWidgets('Care Home renders its core actions', (tester) async {
    await tester.pumpWidget(wrap(const CareHomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Kaylo Care'), findsOneWidget);
    expect(find.text('Emergency SOS'), findsOneWidget);
    expect(find.text('Medicine Reminders'), findsOneWidget);
    expect(find.text('Doctor Appointment'), findsOneWidget);
    expect(find.text('Book a Caregiver'), findsOneWidget);
  });

  testWidgets('Care Home renders in Malayalam', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ml'),
      home: const CareHomeScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('കെയ്‌ലോ കെയർ'), findsOneWidget);
  });
}
