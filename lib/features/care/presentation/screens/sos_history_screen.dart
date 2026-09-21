import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/kaylo_chip.dart';
import '../../../../core/widgets/kaylo_loader.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/care_providers.dart';
import '../../domain/care_models.dart';
import '../widgets/care_scaffold.dart';

class SosHistoryScreen extends ConsumerWidget {
  const SosHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final history = ref.watch(sosHistoryProvider);

    return CareScaffold(
      title: l10n.sosHistory,
      children: history.when(
        data: (alerts) => alerts.isEmpty
            ? [
                EmptyState(
                  title: l10n.noSosTitle,
                  description: l10n.noSosDescription,
                  icon: Icons.history_rounded,
                ),
              ]
            : [
                for (final alert in alerts) ...[
                  _AlertCard(alert: alert),
                  const SizedBox(height: AppSpacing.m),
                ],
              ],
        loading: () => const [
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.xxxl),
            child: Center(child: KayloLoader()),
          ),
        ],
        error: (error, _) => [
          ErrorState(
            title: l10n.somethingWentWrong,
            message: error.toString(),
            onRetry: () => ref.invalidate(sosHistoryProvider),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final SosAlert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loc = MaterialLocalizations.of(context);
    final (label, variant) = switch (alert.status) {
      SosStatus.open => (l10n.sosStatusOpen, KayloChipVariant.error),
      SosStatus.acknowledged =>
        (l10n.sosStatusAcknowledged, KayloChipVariant.warning),
      SosStatus.resolved => (l10n.sosStatusResolved, KayloChipVariant.success),
    };

    Widget line(IconData icon, String text, {bool emphasis = false}) => Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  size: 22, color: emphasis ? AppColors.error : AppColors.textSecondary),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: emphasis ? FontWeight.w700 : null,
                        color: emphasis ? AppColors.error : null,
                      ),
                ),
              ),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${loc.formatMediumDate(alert.triggeredAt)}, '
                    '${loc.formatTimeOfDay(TimeOfDay.fromDateTime(alert.triggeredAt))}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                KayloChip(label: label, variant: variant),
              ],
            ),
            line(Icons.group_rounded, l10n.alertedCount(alert.notifiedContacts)),
            if (alert.primaryContactName != null)
              line(
                Icons.call_rounded,
                l10n.primaryContact(alert.primaryContactName!),
                emphasis: true,
              ),
            if (alert.location != null)
              line(Icons.place_rounded, l10n.locationShared(alert.location!)),
          ],
        ),
      ),
    );
  }
}
