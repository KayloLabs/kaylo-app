import 'package:flutter/material.dart';

import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/theme/app_theme.dart';

/// Every Care screen runs under [AppTheme.careTheme] regardless of the
/// app-wide theme, and leaves room for the floating bottom nav.
class CareScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const CareScaffold({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.careTheme,
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(title: Text(title)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.s,
              AppSpacing.xl,
              140,
            ),
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheets and dialogs opened from Care screens keep the senior
/// theme too; the root navigator would otherwise fall back to the app one.
Future<T?> showCareSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Theme(
      data: AppTheme.careTheme,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: child,
      ),
    ),
  );
}
