import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_core/utils/money.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/widgets/empty_state.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:kaylo_ui/widgets/section_header.dart';

import '../../../../core/router/routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../earnings/application/earnings_providers.dart';
import '../../../messages/application/messages_providers.dart';
import '../../../profile/application/profile_providers.dart';
import '../../application/jobs_providers.dart';
import '../../application/jobs_sort.dart';
import '../../data/pending_jobs_repository.dart';
import '../widgets/job_card.dart';
import '../widgets/workday_panel.dart';

class JobsHomeScreen extends ConsumerStatefulWidget {
  const JobsHomeScreen({super.key});

  @override
  ConsumerState<JobsHomeScreen> createState() => _JobsHomeScreenState();
}

class _JobsHomeScreenState extends ConsumerState<JobsHomeScreen> {
  bool _updatingDuty = false;

  Future<void> _refresh() async {
    KayloFeedback.tap();
    final l10n = AppLocalizations.of(context)!;
    ref.invalidate(workerProfileProvider);
    try {
      await ref.read(jobsRepositoryProvider).getJobs();
    } catch (_) {
      if (mounted) KayloSnackbar.showError(context, l10n.jobsRefreshFailed);
    }
  }

  Future<void> _setDuty(bool online) async {
    if (_updatingDuty) return;
    setState(() => _updatingDuty = true);
    KayloFeedback.press();
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(dutySwitchProvider).set(online);
    } catch (_) {
      if (mounted) KayloSnackbar.showError(context, l10n.dutyUpdateFailed);
    } finally {
      if (mounted) setState(() => _updatingDuty = false);
    }
  }

  void _open(String route) {
    KayloFeedback.selection();
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final secondary = dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final profileState = ref.watch(workerProfileProvider);
    final profile = profileState.asData?.value;
    final onlineState = ref.watch(dutyStatusProvider);
    final online = onlineState.asData?.value ?? profile?.isAvailable ?? false;
    final pending = ref.watch(jobsRepositoryProvider) is PendingJobsRepository;
    final jobs = ref.watch(jobsStreamProvider);
    final earnings = ref.watch(earningsSummaryProvider);
    final active = ref.watch(activeJobProvider);
    final requests = ref.watch(sortedIncomingRequestsProvider);
    final unread = ref.watch(partnerMessageUnreadProvider);
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? l10n.homeMorning
        : now.hour < 17
        ? l10n.homeAfternoon
        : l10n.homeEvening;
    final name = profile?.name.trim().split(RegExp(r'\s+')).first ?? '';
    final unavailable = pending || !jobs.hasValue || jobs.hasError;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.appTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.chatMessages,
            icon: Badge.count(
              count: unread,
              isLabelVisible: unread > 0,
              child: const Icon(Icons.mail_outline_rounded),
            ),
            onPressed: () => _open(Routes.messages),
          ),
          IconButton(
            tooltip: l10n.refreshJobsTooltip,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
          children: [
            Text(
              [
                DateFormat.MMMEd(l10n.localeName).format(now),
                if (profile?.district?.isNotEmpty ?? false) profile!.district!,
              ].join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(color: secondary),
            ),
            const SizedBox(height: 10),
            Text(
              name.isEmpty ? greeting : '$greeting, $name.',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -.7,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              l10n.homeDayOverview,
              style: theme.textTheme.bodyMedium?.copyWith(color: secondary),
            ),
            const SizedBox(height: 22),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - value)),
                  child: child,
                ),
              ),
              child: WorkdayPanel(
                earningsLabel: l10n.todaysPay,
                earnings: unavailable ? '—' : formatRupees(earnings.todayTotal),
                jobsLabel: l10n.jobsToday,
                jobs: unavailable ? '—' : '${earnings.todayJobsCount}',
                ratingLabel: l10n.rating,
                rating: profile == null || profile.reviewsCount == 0
                    ? '—'
                    : '${profile.rating.toStringAsFixed(1)} ★',
                dutyLabel: online ? l10n.homeOnDuty : l10n.homeOffDuty,
                dutyDescription: online
                    ? l10n.homeOnDutyHint
                    : l10n.homeOffDutyHint,
                online: online,
                updating: _updatingDuty || pending || !onlineState.hasValue,
                onDutyChanged: _setDuty,
                onEarnings: () => _open(Routes.earnings),
                onReviews: () => _open(Routes.reviews),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: WorkdayShortcut(
                    icon: Icons.calendar_month_outlined,
                    label: l10n.homeSchedule,
                    onTap: () => _open(Routes.availability),
                  ),
                ),
                Expanded(
                  child: WorkdayShortcut(
                    icon: Icons.history_rounded,
                    label: l10n.homeHistory,
                    onTap: () => _open(Routes.history),
                  ),
                ),
                Expanded(
                  child: WorkdayShortcut(
                    icon: Icons.star_outline_rounded,
                    label: l10n.reviewsTitle,
                    onTap: () => _open(Routes.reviews),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            active.when(
              data: (job) => job == null
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(title: l10n.activeJob),
                        const SizedBox(height: 12),
                        JobCard(job: job),
                        const SizedBox(height: 24),
                      ],
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            // Existing scheduled requests must remain actionable off duty.
            requests.when(
              data: (items) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: l10n.newRequests(items.length)),
                  const SizedBox(height: 14),
                  if ((ref
                              .watch(incomingRequestsProvider)
                              .asData
                              ?.value
                              .isNotEmpty ??
                          false) ||
                      ref.watch(jobServiceFilterProvider).isNotEmpty)
                    const _SortAndFilterChipsRow(),
                  if (items.isEmpty &&
                      ref.watch(jobServiceFilterProvider).isNotEmpty)
                    EmptyState(
                      title: l10n.filterEmptyTitle,
                      description: l10n.filterEmptySubtitle,
                      icon: Icons.filter_alt_off_outlined,
                    )
                  else if (items.isEmpty)
                    _QuietWorkday(
                      title: online ? l10n.homeReadyTitle : l10n.homeRestTitle,
                      body: pending
                          ? l10n.liveJobsPending
                          : online
                          ? l10n.homeReadyBody
                          : l10n.homeRestBody,
                    )
                  else
                    for (final job in items) ...[
                      JobCard(key: ValueKey(job.id), job: job),
                      const SizedBox(height: 14),
                    ],
                ],
              ),
              loading: () => const Center(child: KayloLoader()),
              error: (err, _) => Column(
                children: [
                  Text(
                    err is LiveJobsPending
                        ? l10n.liveJobsPending
                        : l10n.jobsRefreshFailed,
                  ),
                  TextButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuietWorkday extends StatelessWidget {
  final String title, body;
  const _QuietWorkday({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceDark : const Color(0xFFF6F5EC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: dark ? AppColors.borderDark : const Color(0xFFE7E7D8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: 28,
            color: dark ? const Color(0xFFB9D0B6) : AppColors.brandPrimary,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: dark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SortAndFilterChipsRow extends ConsumerWidget {
  const _SortAndFilterChipsRow();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sort = ref.watch(jobSortProvider);
    final filters = ref.watch(jobServiceFilterProvider);
    final jobs = ref.watch(incomingRequestsProvider).asData?.value ?? [];
    final services = {
      for (final job in jobs) jobServiceKey(job): job.serviceName,
    };
    String label(String key) => switch (key) {
      'plumbing' => l10n.servicePlumbing,
      'electrical' => l10n.serviceElectrical,
      'appliances' => l10n.serviceAppliances,
      'carpentry' => l10n.serviceCarpentry,
      _ => services[key] ?? key,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final value in JobSort.values)
                ChoiceChip(
                  label: Text(switch (value) {
                    JobSort.nearest => l10n.sortNearest,
                    JobSort.highestPayout => l10n.sortHighestPayout,
                    JobSort.soonest => l10n.sortSoonest,
                  }),
                  selected: sort == value,
                  onSelected: (_) {
                    KayloFeedback.selection();
                    ref.read(jobSortProvider.notifier).setSort(value);
                  },
                ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final key in services.keys)
                FilterChip(
                  label: Text(label(key)),
                  selected: filters.contains(key),
                  onSelected: (_) {
                    KayloFeedback.selection();
                    ref.read(jobServiceFilterProvider.notifier).toggle(key);
                  },
                ),
              if (filters.isNotEmpty)
                ActionChip(
                  label: Text(l10n.clearFilters),
                  onPressed: () =>
                      ref.read(jobServiceFilterProvider.notifier).clear(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
