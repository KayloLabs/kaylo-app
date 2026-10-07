import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_radius.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/payment_methods_providers.dart';
import '../../domain/payment_method.dart';
import '../../domain/saved_card.dart';

class AddPaymentSheet extends ConsumerStatefulWidget {
  const AddPaymentSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddPaymentSheet(),
    );
  }

  @override
  ConsumerState<AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends ConsumerState<AddPaymentSheet> {
  PaymentMethodType _selectedType = PaymentMethodType.upi;
  final _upiController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  bool _isDefault = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _upiController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedType == PaymentMethodType.upi) {
      final upi = _upiController.text.trim();
      if (!upi.contains('@') || upi.length < 4) {
        KayloSnackbar.showError(
          context,
          'Please enter a valid UPI ID (e.g. name@upi)',
        );
        return;
      }

      setState(() => _isSubmitting = true);
      try {
        String label = 'UPI';
        if (upi.contains('okaxis') ||
            upi.contains('okhdfcbank') ||
            upi.contains('okicici') ||
            upi.contains('oksbi')) {
          label = 'Google Pay UPI';
        } else if (upi.contains('ybl') || upi.contains('ibl')) {
          label = 'PhonePe UPI';
        } else if (upi.contains('paytm')) {
          label = 'Paytm UPI';
        }

        await ref
            .read(paymentMethodsRepositoryProvider)
            .addPaymentMethod(
              type: PaymentMethodType.upi,
              label: label,
              detail: upi,
              isDefault: _isDefault,
            );

        if (!mounted) return;
        KayloFeedback.press();
        KayloSnackbar.showSuccess(context, l10n.paymentMethodAdded);
        Navigator.of(context).pop();
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    } else {
      final card = SavedCard(
        number: _cardNumberController.text,
        holder: _cardHolderController.text,
        expiry: _expiryController.text,
      );
      if (!card.hasValidLength) {
        KayloSnackbar.showError(context, 'Please enter a valid card number');
        return;
      }

      setState(() => _isSubmitting = true);
      try {
        await ref
            .read(paymentMethodsRepositoryProvider)
            .addPaymentMethod(
              type: PaymentMethodType.card,
              label: card.label,
              detail: card.detail,
              isDefault: _isDefault,
            );

        if (!mounted) return;
        KayloFeedback.press();
        KayloSnackbar.showSuccess(context, l10n.paymentMethodAdded);
        Navigator.of(context).pop();
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.m,
        AppSpacing.l,
        viewInsets.bottom + AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.m),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.addPaymentMethod,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),

            // Segmented toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceMutedDark
                    : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: l10n.payUpi,
                      icon: Icons.account_balance_wallet_rounded,
                      isSelected: _selectedType == PaymentMethodType.upi,
                      onTap: () {
                        KayloFeedback.tap();
                        setState(() => _selectedType = PaymentMethodType.upi);
                      },
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      label: l10n.cardNumber,
                      icon: Icons.credit_card_rounded,
                      isSelected: _selectedType == PaymentMethodType.card,
                      onTap: () {
                        KayloFeedback.tap();
                        setState(() => _selectedType = PaymentMethodType.card);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),

            if (_selectedType == PaymentMethodType.upi) ...[
              KayloTextField(
                controller: _upiController,
                label: l10n.upiId,
                hintText: 'e.g. anjali@okhdfcbank',
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.s),
              Wrap(
                spacing: AppSpacing.s,
                children: [
                  for (final suffix in [
                    '@okhdfcbank',
                    '@okaxis',
                    '@ybl',
                    '@paytm',
                  ])
                    ActionChip(
                      label: Text(suffix),
                      labelStyle: const TextStyle(fontSize: 12),
                      backgroundColor: isDark
                          ? AppColors.surfaceTintDark
                          : AppColors.surfaceAlt,
                      onPressed: () {
                        final current = _upiController.text.trim();
                        final prefix = current.contains('@')
                            ? current.split('@').first
                            : current;
                        if (prefix.isNotEmpty) {
                          _upiController.text = '$prefix$suffix';
                        }
                      },
                    ),
                ],
              ),
            ] else ...[
              KayloTextField(
                controller: _cardNumberController,
                label: l10n.cardNumber,
                hintText: '4532 •••• •••• 4242',
                prefixIcon: const Icon(Icons.credit_card_rounded),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.m),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: KayloTextField(
                      controller: _cardHolderController,
                      label: l10n.cardHolderName,
                      hintText: 'Name on card',
                      keyboardType: TextInputType.name,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    flex: 2,
                    child: KayloTextField(
                      controller: _expiryController,
                      label: l10n.cardExpiry,
                      hintText: 'MM/YY',
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.l),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _isDefault,
              onChanged: (val) => setState(() => _isDefault = val),
              title: Text(
                l10n.setDefault,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              activeTrackColor: AppColors.brandPrimary,
            ),
            const SizedBox(height: AppSpacing.l),

            KayloButton(
              text: l10n.savePaymentMethod,
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.surfaceDark : AppColors.surface)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? AppColors.brandPrimary
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.s),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary)
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
