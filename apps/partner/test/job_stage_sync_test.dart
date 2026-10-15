import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_partner/features/jobs/application/jobs_providers.dart';
import 'package:kaylo_partner/features/jobs/data/supabase_jobs_repository.dart';
import 'package:kaylo_partner/features/jobs/domain/job.dart';
import 'supabase_jobs_repository_test.dart' show row;

void main() {
  test(
    'same booking refreshes detail and active job through every stage',
    () async {
      var stage = 'requested';
      final repo = SupabaseJobsRepository(
        initiallyOnline: true,
        loadRows: () async => [row(status: stage)],
        rpc: (function, {params}) async {
          stage = params!['p_stage'] as String;
        },
      );
      final container = ProviderContainer(
        overrides: [jobsRepositoryProvider.overrideWithValue(repo)],
      );
      final detail = <JobStage>[];
      final active = <JobStage>[];
      final a = container.listen(jobDetailProvider('booking-1'), (_, next) {
        if (next.asData?.value case final Job job) detail.add(job.stage);
      });
      final b = container.listen(activeJobProvider, (_, next) {
        if (next.asData?.value case final Job job) active.add(job.stage);
      });
      addTearDown(() {
        a.close();
        b.close();
        container.dispose();
        repo.dispose();
      });
      await container.read(jobDetailProvider('booking-1').future);
      for (var i = 0; i < 5; i++) {
        await repo.advanceJob('booking-1');
        await Future<void>.delayed(Duration.zero);
        await container.pump();
      }
      expect(detail, [
        JobStage.requested,
        JobStage.accepted,
        JobStage.onTheWay,
        JobStage.arrived,
        JobStage.inProgress,
        JobStage.completed,
      ]);
      expect(active, [
        JobStage.accepted,
        JobStage.onTheWay,
        JobStage.arrived,
        JobStage.inProgress,
      ]);
      expect(container.read(activeJobProvider).requireValue, isNull);
    },
  );

  test('successful write waits for a fresh read after an older poll', () async {
    var stage = 'requested';
    Completer<List<Map<String, dynamic>>>? delayed;
    final repo = SupabaseJobsRepository(
      initiallyOnline: true,
      loadRows: () => delayed?.future ?? Future.value([row(status: stage)]),
      rpc: (function, {params}) async {
        stage = params!['p_stage'] as String;
      },
    );
    addTearDown(repo.dispose);
    await repo.getJobs();
    delayed = Completer();
    final oldRead = repo.getJobs();
    final action = repo.advanceJob('booking-1');
    await Future<void>.delayed(Duration.zero);
    final pending = delayed;
    delayed = null;
    pending.complete([row()]);
    await oldRead;
    await action;
    expect((await repo.watchJobs().first).single.stage, JobStage.accepted);
  });

  test(
    'failed status write propagates and keeps the last confirmed stage',
    () async {
      final repo = SupabaseJobsRepository(
        initiallyOnline: true,
        loadRows: () async => [row()],
        rpc: (function, {params}) async => throw StateError('Offline'),
      );
      addTearDown(repo.dispose);
      await repo.getJobs();
      await expectLater(repo.advanceJob('booking-1'), throwsA(anything));
      expect((await repo.watchJobs().first).single.stage, JobStage.requested);
    },
  );
}
