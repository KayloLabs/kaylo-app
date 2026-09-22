import 'package:flutter/material.dart';

import 'package:kaylo_core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Large-target stepper (56x56 buttons) so it works for gloved hands
/// in the field and for Care Mode users alike.
class QuantityStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 200,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          filled: false,
          enabled: value > min,
          onTap: () => onChanged(value - 1),
        ),
        const SizedBox(width: AppSpacing.xl),
        Container(
          constraints: const BoxConstraints(minWidth: 72),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.s,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceTintDark : AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        _StepButton(
          icon: Icons.add_rounded,
          filled: true,
          enabled: value < max,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final bool enabled;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.filled,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = filled
        ? AppColors.brandPrimary
        : AppColors.brandPrimary.withValues(alpha: 0.12);
    final foreground = filled ? Colors.white : AppColors.brandPrimary;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled
              ? () {
                  KayloFeedback.tap();
                  onTap();
                }
              : null,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(icon, color: foreground, size: 28),
          ),
        ),
      ),
    );
  }
}
