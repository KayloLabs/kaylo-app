import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/models/app_user.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';

/// Name editor used from the profile header and the settings account
/// card. Saves through the session controller so every screen showing
/// the name updates at once.
Future<void> showEditProfileSheet(BuildContext context, AppUser user) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _EditProfileSheet(user: user),
  );
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final AppUser user;

  const _EditProfileSheet({required this.user});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final _first = TextEditingController(text: widget.user.firstName);
  late final _last = TextEditingController(text: widget.user.lastName);
  bool _saving = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final first = _first.text.trim();
    if (first.isEmpty) {
      KayloSnackbar.showError(context, l10n.nameRequired);
      return;
    }
    KayloFeedback.tap();
    setState(() => _saving = true);
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .updateProfile(firstName: first, lastName: _last.text.trim());
      if (!mounted) return;
      KayloFeedback.press();
      Navigator.of(context).pop();
      KayloSnackbar.showSuccess(context, l10n.profileUpdated);
    } catch (e) {
      if (mounted) KayloSnackbar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.editProfile, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.l),
          KayloTextField(
            label: l10n.firstName,
            controller: _first,
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
          const SizedBox(height: AppSpacing.m),
          KayloTextField(
            label: l10n.lastName,
            controller: _last,
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          if (widget.user.contactLine.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.m),
            Text(
              widget.user.contactLine,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          KayloButton(
            text: l10n.save,
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
