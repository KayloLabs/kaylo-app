import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

class PartnerLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const PartnerLoadError({
    super.key,
    required this.message,
    required this.onRetry,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 36,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    ),
  );
}
