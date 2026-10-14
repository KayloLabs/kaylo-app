import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/language_selector_sheet.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';

class LanguageTile extends ConsumerWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(partnerLocaleProvider);

    String languageName = 'English';
    switch (currentLocale.languageCode) {
      case 'ml':
        languageName = 'Malayalam';
        break;
      case 'hi':
        languageName = 'Hindi';
        break;
      case 'ta':
        languageName = 'Tamil';
        break;
    }

    return KayloCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.language),
        title: Text(
          AppLocalizations.of(context)?.profileLanguageTile ?? 'Language',
        ),
        subtitle: Text(languageName),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          KayloFeedback.tap();
          showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const LanguageSelectorSheet(),
          );
        },
      ),
    );
  }
}
