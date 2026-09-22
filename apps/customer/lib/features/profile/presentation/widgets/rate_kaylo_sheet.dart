import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/app_rating_provider.dart';

Future<void> showRateKayloSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    // Over the whole app so the floating bottom nav stays underneath.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const RateKayloSheet(),
  );
}

class RateKayloSheet extends ConsumerStatefulWidget {
  const RateKayloSheet({super.key});

  @override
  ConsumerState<RateKayloSheet> createState() => _RateKayloSheetState();
}

class _RateKayloSheetState extends ConsumerState<RateKayloSheet> {
  late int _stars = ref.read(appRatingProvider) ?? 0;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_stars == 0) {
      KayloSnackbar.showError(context, l10n.pickAStar);
      return;
    }
    await ref.read(appRatingProvider.notifier).rate(_stars);
    if (!mounted) return;
    KayloFeedback.press();
    Navigator.of(context).pop();
    KayloSnackbar.showSuccess(context, l10n.rateThanks);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.rateTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.rateSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                _Star(
                  filled: i <= _stars,
                  onTap: () {
                    KayloFeedback.tap();
                    setState(() => _stars = i);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          KayloTextField(label: l10n.rateComment, controller: _comment),
          const SizedBox(height: AppSpacing.xl),
          KayloButton(text: l10n.submitRating, onPressed: _submit),
          const SizedBox(height: AppSpacing.s),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

class _Star extends StatelessWidget {
  final bool filled;
  final VoidCallback onTap;

  const _Star({required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: AnimatedScale(
        scale: filled ? 1.15 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 44,
            color: filled ? AppColors.secondaryAccent : AppColors.border,
          ),
        ),
      ),
    );
  }
}
