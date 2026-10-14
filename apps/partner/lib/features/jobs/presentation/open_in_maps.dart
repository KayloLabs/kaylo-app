import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import '../../../l10n/generated/app_localizations.dart';

Future<void> openJobInMaps(BuildContext context, String address) async {
  final uri = Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': address,
  });
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {}
  if (context.mounted) {
    KayloSnackbar.showInfo(
      context,
      AppLocalizations.of(context)!.mapNavigationUnavailable,
    );
  }
}
