import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';
import '../../../../core/router/routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/partner_session.dart';
import 'auth_messages.dart';
import 'login_screen.dart';

class PartnerChangePasswordScreen extends ConsumerStatefulWidget {
  const PartnerChangePasswordScreen({super.key});
  @override
  ConsumerState<PartnerChangePasswordScreen> createState() =>
      _PartnerChangePasswordScreenState();
}

class _PartnerChangePasswordScreenState
    extends ConsumerState<PartnerChangePasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    if (_password.text.length < 12 || _password.text != _confirm.text) {
      setState(
        () => _error = _password.text.length < 12
            ? l10n.authPasswordRule
            : l10n.authPasswordMismatch,
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(partnerAuthRepositoryProvider)
          .changePassword(_password.text);
      if (mounted) context.go(Routes.jobs);
    } catch (error) {
      if (mounted) setState(() => _error = partnerAuthMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l10n.authChangePassword),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_reset_rounded, size: 56),
                    const SizedBox(height: 24),
                    Text(
                      l10n.authChangePasswordBody,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.authPasswordRule),
                    const SizedBox(height: 24),
                    KayloTextField(
                      key: const Key('new-password'),
                      label: l10n.authNewPassword,
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    KayloTextField(
                      key: const Key('confirm-password'),
                      label: l10n.authConfirmPassword,
                      controller: _confirm,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    KayloButton(
                      text: l10n.authSavePassword,
                      isLoading: _busy,
                      onPressed: _busy ? null : _save,
                    ),
                    TextButton(
                      onPressed: () => contactPartnerSupport(context),
                      child: Text(l10n.authSupport),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              await ref
                                  .read(partnerAuthRepositoryProvider)
                                  .signOut();
                              if (context.mounted) context.go(Routes.login);
                            },
                      child: Text(l10n.logOut),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
