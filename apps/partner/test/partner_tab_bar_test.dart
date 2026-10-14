import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_partner/core/router/app_router.dart';
import 'package:kaylo_partner/core/widgets/partner_tab_bar.dart';
import 'package:kaylo_partner/features/earnings/presentation/screens/earnings_screen.dart';
import 'package:kaylo_partner/features/jobs/application/jobs_providers.dart';
import 'package:kaylo_partner/features/jobs/presentation/screens/jobs_home_screen.dart';
import 'package:kaylo_partner/l10n/generated/app_localizations.dart';
import 'package:kaylo_ui/theme/app_theme.dart';
import 'package:kaylo_ui/widgets/liquid_nav_surface.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, Widget)> createHarness() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  final router = container.read(partnerRouterProvider);
  return (
    container,
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
}

Future<void> signIn(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign in').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'NewKayloPass123!');
  await tester.enterText(find.byType(TextFormField).at(1), 'NewKayloPass123!');
  await tester.tap(find.text('Save password'));
  await tester.pumpAndSettle();
}

void main() {
  group('PartnerTabBar branch switching', () {
    testWidgets('tapping each destination changes the shell branch', (
      tester,
    ) async {
      final (container, app) = await createHarness();
      addTearDown(() async {
        await container.read(jobsRepositoryProvider).setDuty(false);
        container.dispose();
      });

      await tester.pumpWidget(app);
      await signIn(tester);

      // Verify initial tab is Jobs
      expect(find.byType(JobsHomeScreen), findsOneWidget);

      // Tap Earnings tab
      await tester.tap(find.byTooltip('Earnings'));
      await tester.pumpAndSettle();
      expect(find.byType(EarningsScreen), findsOneWidget);
      expect(find.text('Partner Earnings'), findsOneWidget);
      expect(find.byType(JobsHomeScreen), findsNothing);

      // Tap Profile tab
      await tester.tap(find.byTooltip('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Partner profile'), findsOneWidget);

      // Tap Jobs tab to return
      await tester.tap(find.byTooltip('Jobs'));
      await tester.pumpAndSettle();
      expect(find.byType(JobsHomeScreen), findsOneWidget);

      await container.read(jobsRepositoryProvider).setDuty(false);
      await tester.pump();
    });
  });

  group('PartnerTabBar responsive width & themes', () {
    final sampleItems3 = [
      const PartnerTabItem(
        icon: Icons.work_outline_rounded,
        selectedIcon: Icons.work_rounded,
        label: 'Jobs',
      ),
      const PartnerTabItem(
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart_rounded,
        label: 'Earnings',
      ),
      const PartnerTabItem(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];

    final sampleItems4 = [
      ...sampleItems3,
      const PartnerTabItem(
        icon: Icons.notifications_none_rounded,
        selectedIcon: Icons.notifications_rounded,
        label: 'Alerts',
      ),
    ];

    testWidgets('renders in light theme without overflow at 360 px width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.all(12),
              child: PartnerTabBar(
                currentIndex: selectedIndex,
                onSelected: (i) => selectedIndex = i,
                items: sampleItems3,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Jobs'), findsOneWidget);
      expect(find.byTooltip('Earnings'), findsOneWidget);
      expect(find.byTooltip('Profile'), findsOneWidget);
      expect(find.byType(LiquidNavSurface), findsOneWidget);
    });

    testWidgets('renders in dark theme without overflow at 360 px width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int selectedIndex = 1;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.all(12),
              child: PartnerTabBar(
                currentIndex: selectedIndex,
                onSelected: (i) => selectedIndex = i,
                items: sampleItems3,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Jobs'), findsOneWidget);
      expect(find.byTooltip('Earnings'), findsOneWidget);
      expect(find.byTooltip('Profile'), findsOneWidget);
    });

    testWidgets(
      'renders with 4 destinations without overflow at 360 px width',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        int selectedIndex = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.all(12),
                child: PartnerTabBar(
                  currentIndex: selectedIndex,
                  onSelected: (i) => selectedIndex = i,
                  items: sampleItems4,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byTooltip('Alerts'), findsOneWidget);
      },
    );
  });

  group('JobsHomeScreen preserves duty controls', () {
    testWidgets('renders the header and duty switch', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const JobsHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Preserve the functional header while the shell shares customer glass.
      expect(find.byType(AppBar), findsOneWidget);

      // Verify duty switch works
      expect(find.byType(Switch), findsOneWidget);
    });
  });
}
