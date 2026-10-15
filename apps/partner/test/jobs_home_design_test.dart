import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_partner/features/jobs/application/jobs_providers.dart';
import 'package:kaylo_partner/features/jobs/data/supabase_jobs_repository.dart';
import 'package:kaylo_partner/features/jobs/presentation/screens/jobs_home_screen.dart';
import 'package:kaylo_partner/features/messages/application/messages_providers.dart';
import 'package:kaylo_partner/features/profile/application/profile_providers.dart';
import 'package:kaylo_partner/features/profile/domain/worker_profile.dart';
import 'package:kaylo_partner/l10n/generated/app_localizations.dart';
import 'package:kaylo_ui/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final locale in ['en', 'ml', 'hi', 'ta']) {
    for (final dark in [false, true]) {
      testWidgets('home fits 320px with larger $locale text, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repo = SupabaseJobsRepository(
          loadRows: () async => [],
          initiallyOnline: false,
        );
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            jobsRepositoryProvider.overrideWithValue(repo),
            partnerMessageUnreadProvider.overrideWithValue(0),
            workerProfileProvider.overrideWith(
              (ref) => Stream.value(
                WorkerProfile(
                  id: 'worker',
                  personId: 'person',
                  name: 'An exceptionally long partner name',
                  phone: '',
                  joinedOn: DateTime(2026),
                  rating: 4,
                  reviewsCount: 1,
                  isAvailable: false,
                ),
              ),
            ),
          ],
        );
        final router = GoRouter(
          initialLocation: '/jobs',
          routes: [
            GoRoute(path: '/jobs', builder: (_, _) => const JobsHomeScreen()),
            for (final route in [
              'availability',
              'history',
              'reviews',
              'earnings',
            ])
              GoRoute(
                path: '/$route',
                builder: (_, _) => Scaffold(body: Text('Opened $route')),
              ),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              locale: Locale(locale),
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.35),
                  disableAnimations: true,
                ),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final l10n = lookupAppLocalizations(Locale(locale));
        await tester.scrollUntilVisible(find.text(l10n.homeRestTitle), 150);
        expect(find.text(l10n.homeRestBody), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (locale == 'en' && !dark) {
          for (final entry in {
            'Schedule': 'availability',
            'History': 'history',
            'Reviews': 'reviews',
          }.entries) {
            await tester.ensureVisible(find.text(entry.key));
            await tester.tap(find.text(entry.key));
            await tester.pumpAndSettle();
            expect(find.text('Opened ${entry.value}'), findsOneWidget);
            router.pop();
            await tester.pumpAndSettle();
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        repo.dispose();
        router.dispose();
      });
    }
  }
}
