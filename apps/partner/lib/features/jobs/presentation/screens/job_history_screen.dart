import '../../../reviews/presentation/widgets/review_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/pending_jobs_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/empty_state.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';

import '../../application/jobs_providers.dart';
import '../widgets/job_card.dart';

class JobHistoryScreen extends ConsumerWidget {
  const JobHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(jobHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Job History')),
      body: history.when(
        loading: () => const Center(child: KayloLoader()),
        error: (error, _) => Center(
          child: Text(
            error is LiveJobsPending
                ? AppLocalizations.of(context)!.liveJobsPending
                : 'Unable to load history: $error',
          ),
        ),
        data: (jobs) => jobs.isEmpty
            ? const EmptyState(
                title: 'No past jobs yet',
                description: 'Completed and cancelled jobs will appear here.',
                icon: Icons.history_rounded,
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.l),
                itemCount: jobs.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.m),
                itemBuilder: (context, index) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JobCard(job: jobs[index]),
                    if (jobs[index].isCompleted)
                      JobReviewStars(jobId: jobs[index].id),
                  ],
                ),
              ),
      ),
    );
  }
}
