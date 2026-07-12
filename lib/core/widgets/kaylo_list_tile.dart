import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class KayloListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const KayloListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.l),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    child: title,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodySmall!,
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.l),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
