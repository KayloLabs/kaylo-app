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
import 'package:kaylo_ui/widgets/kaylo_liquid_glass.dart';
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
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Verify & Sign In'));
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
      await tester.tap(find.text('Earnings'));
      await tester.pumpAndSettle();
      expect(find.byType(EarningsScreen), findsOneWidget);
      expect(find.text('Partner Earnings'), findsOneWidget);
      expect(find.byType(JobsHomeScreen), findsNothing);

      // Tap Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Partner Profile'), findsOneWidget);

      // Tap Jobs tab to return
      await tester.tap(find.text('Jobs'));
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
      expect(find.text('Jobs'), findsOneWidget);
      expect(find.text('Earnings'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byType(KayloLiquidGlass), findsOneWidget);
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
      expect(find.text('Jobs'), findsOneWidget);
      expect(find.text('Earnings'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('renders with 4 destinations without overflow at 360 px width', (
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
                items: sampleItems4,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Alerts'), findsOneWidget);
    });
  });

  group('JobsHomeScreen glass header and duty pill', () {
    testWidgets('renders glass SliverAppBar and glass duty pill', (
      tester,
    ) async {
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

      // Verify SliverAppBar is present
      expect(find.byType(SliverAppBar), findsOneWidget);

      // Verify KayloLiquidGlass is used for both flexibleSpace and duty pill
      expect(find.byType(KayloLiquidGlass), findsAtLeastNWidgets(2));

      // Verify duty switch works
      expect(find.byType(Switch), findsOneWidget);
    });
  });
}
