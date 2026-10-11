import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/widgets/empty_state.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/partner_load_error.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/alerts_providers.dart';
import '../../domain/partner_notification.dart';

String alertTitle(PartnerNotification n, AppLocalizations l) =>
    switch (n.event) {
      'requested' => l.alertNewRequest,
      'accepted' => l.alertAccepted,
      'onTheWay' => l.alertOnTheWay,
      'arrived' => l.alertArrived,
      'inProgress' => l.alertInProgress,
      'completed' => l.alertCompleted,
      'cancelled' => l.alertCancelled,
      _ => switch (n.title) {
        'New job request' => l.alertNewRequest,
        'Booking cancelled' => l.alertCancelled,
        'Job completed' => l.alertCompleted,
        'Job accepted' => l.alertAccepted,
        'On the way' => l.alertOnTheWay,
        'Arrival confirmed' => l.alertArrived,
        'Job started' => l.alertInProgress,
        'Cash collected' => l.alertCashCollected,
        'Payment received' => l.alertPaymentReceived,
        'Settlement recorded' => l.alertSettlement,
        _ => n.title,
      },
    };
String alertBody(PartnerNotification n, AppLocalizations l) => n.event == null
    ? n.body
    : n.event == 'requested' && (n.details['distance'] ?? '').isNotEmpty
    ? l.alertRequestBody(
        n.details['service'] ?? '',
        n.details['distance'] ?? '',
      )
    : l.alertJobBody(n.details['service'] ?? '');

class PartnerAlertsScreen extends ConsumerStatefulWidget {
  const PartnerAlertsScreen({super.key});
  @override
  ConsumerState<PartnerAlertsScreen> createState() => _AlertsState();
}

class _AlertsState extends ConsumerState<PartnerAlertsScreen> {
  bool _busy = false;
  Future<bool> _mark(String? id) async {
    final repo = ref.read(partnerAlertsRepositoryProvider);
    if (repo == null) return false;
    try {
      if (id == null) {
        await repo.markAllRead();
      } else {
        await repo.markRead(id);
      }
      return true;
    } catch (_) {
      if (mounted) {
        KayloSnackbar.showError(
          context,
          AppLocalizations.of(context)!.alertsUpdateFailed,
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!,
        scheme = Theme.of(context).colorScheme;
    final alerts = ref.watch(partnerAlertsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.alertsTitle),
        actions: [
          TextButton(
            onPressed: _busy || ref.watch(partnerAlertUnreadProvider) == 0
                ? null
                : () async {
                    setState(() => _busy = true);
                    await _mark(null);
                    if (mounted) setState(() => _busy = false);
                  },
            child: Text(l.alertsMarkAllRead),
          ),
        ],
      ),
      body: alerts.when(
        loading: () => const Center(child: KayloLoader()),
        error: (_, _) => PartnerLoadError(
          message: l.alertsLoadFailed,
          onRetry: () => ref.invalidate(partnerAlertsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              title: l.alertsEmpty,
              description: l.alertsEmptyBody,
              icon: Icons.notifications_none_rounded,
            );
          }
          final now = DateTime.now(),
              today = DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              );
          final groups = [
            items
                .where(
                  (n) =>
                      !n.createdAt.isBefore(today) && !n.createdAt.isAfter(now),
                )
                .toList(),
            items
                .where(
                  (n) =>
                      n.createdAt.isBefore(today) || n.createdAt.isAfter(now),
                )
                .toList(),
          ];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              for (var i = 0; i < groups.length; i++)
                if (groups[i].isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                    child: Text(
                      i == 0 ? l.alertsToday : l.alertsEarlier,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  for (final n in groups[i])
                    Dismissible(
                      key: ValueKey(n.id),
                      direction: n.isRead
                          ? DismissDirection.none
                          : DismissDirection.endToStart,
                      background: Container(
                        alignment: AlignmentDirectional.centerEnd,
                        padding: const EdgeInsets.all(24),
                        color: scheme.primaryContainer,
                        child: Icon(
                          Icons.done_all_rounded,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      confirmDismiss: (_) async {
                        await _mark(n.id);
                        return false;
                      },
                      child: Card(
                        elevation: 0,
                        color: n.isRead
                            ? scheme.surface
                            : scheme.primaryContainer.withValues(alpha: 0.35),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: Badge(
                            isLabelVisible: !n.isRead,
                            child: Icon(switch (n.type) {
                              PartnerNotificationType.request =>
                                Icons.work_outline_rounded,
                              PartnerNotificationType.job =>
                                Icons.event_available_outlined,
                              PartnerNotificationType.payout =>
                                Icons.account_balance_wallet_outlined,
                              PartnerNotificationType.system =>
                                Icons.notifications_outlined,
                            }),
                          ),
                          title: Text(
                            alertTitle(n, l),
                            style: TextStyle(
                              fontWeight: n.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(alertBody(n, l)),
                              const SizedBox(height: 6),
                              Text(
                                MaterialLocalizations.of(
                                  context,
                                ).formatShortMonthDay(n.createdAt),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                          trailing: n.jobId == null
                              ? null
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: () async {
                            KayloFeedback.tap();
                            await _mark(n.id);
                            if (context.mounted && n.jobId != null) {
                              context.push(Routes.jobDetail(n.jobId!));
                            }
                          },
                        ),
                      ),
                    ),
                ],
            ],
          );
        },
      ),
    );
  }
}
