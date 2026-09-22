import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_ui/kaylo_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: KayloPartnerApp()));
}

/// The worker-side app. Shares theme, widgets, models and backend access
/// with the customer app through kaylo_ui and kaylo_core; its own
/// features (jobs inbox, job detail, availability, earnings) land here.
class KayloPartnerApp extends StatelessWidget {
  const KayloPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kaylo Partner',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const PartnerHomePlaceholder(),
    );
  }
}

class PartnerHomePlaceholder extends StatelessWidget {
  const PartnerHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const KayloLogo(width: 96),
              const SizedBox(height: AppSpacing.l),
              Text(
                'Kaylo Partner',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Jobs inbox coming next',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
