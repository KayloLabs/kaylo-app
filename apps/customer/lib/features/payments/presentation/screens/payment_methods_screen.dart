import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/empty_state.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/kaylo_chip.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/payment_methods_providers.dart';
import '../../domain/payment_method.dart';
import '../widgets/add_payment_sheet.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final methodsAsync = ref.watch(paymentMethodsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paymentMethods),
      ),
      body: methodsAsync.when(
        data: (methods) {
          if (methods.isEmpty) {
            return Center(
              child: EmptyState(
                title: l10n.noPaymentMethods,
                description: l10n.noPaymentMethodsSubtitle,
                icon: Icons.account_balance_wallet_outlined,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.m,
              AppSpacing.l,
              120,
            ),
            itemCount: methods.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
            itemBuilder: (context, index) {
              final method = methods[index];
              return _PaymentMethodCard(method: method);
            },
          );
        },
        loading: () => const Center(child: KayloLoader()),
        error: (error, _) => Center(
          child: Text(
            error.toString(),
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          0,
          AppSpacing.l,
          AppSpacing.l,
        ),
        child: KayloButton(
          text: l10n.addPaymentMethod,
          icon: Icons.add_rounded,
          onPressed: () => AddPaymentSheet.show(context),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends ConsumerWidget {
  final SavedPaymentMethod method;

  const _PaymentMethodCard({required this.method});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isUpi = method.type.isUpi;
    final iconData = isUpi
        ? Icons.account_balance_wallet_rounded
        : Icons.credit_card_rounded;
    final accentColor = isUpi ? AppColors.brandPrimary : AppColors.careAccent;

    return KayloCard(
      onTap: method.isDefault
          ? null
          : () async {
              KayloFeedback.tap();
              await ref
                  .read(paymentMethodsRepositoryProvider)
                  .setDefaultPaymentMethod(method.id);
            },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              iconData,
              color: accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        method.label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (method.isDefault) ...[
                      const SizedBox(width: AppSpacing.s),
                      KayloChip(
                        label: l10n.defaultTag,
                        variant: KayloChipVariant.brand,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  method.detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        letterSpacing: isUpi ? 0 : 1.2,
                      ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            onSelected: (action) async {
              if (action == 'default') {
                KayloFeedback.tap();
                await ref
                    .read(paymentMethodsRepositoryProvider)
                    .setDefaultPaymentMethod(method.id);
              } else if (action == 'remove') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.removeMethod),
                    content: Text(l10n.deletePaymentMethodConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(
                          l10n.removeMethod,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  KayloFeedback.tap();
                  await ref
                      .read(paymentMethodsRepositoryProvider)
                      .removePaymentMethod(method.id);
                  if (context.mounted) {
                    KayloSnackbar.showSuccess(
                      context,
                      l10n.paymentMethodRemoved,
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              if (!method.isDefault)
                PopupMenuItem(
                  value: 'default',
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 18),
                      const SizedBox(width: AppSpacing.s),
                      Text(l10n.setDefault),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      l10n.removeMethod,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
