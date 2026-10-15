import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';
import '../../../../core/router/routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/partner_password_recovery.dart';
import '../../domain/partner_auth_repository.dart';
import 'auth_messages.dart';

class PartnerForgotPasswordScreen extends ConsumerStatefulWidget {
  final String initialPartnerId;
  const PartnerForgotPasswordScreen({super.key, this.initialPartnerId = ''});
  @override
  ConsumerState<PartnerForgotPasswordScreen> createState() =>
      _PartnerForgotPasswordScreenState();
}

class _PartnerForgotPasswordScreenState
    extends ConsumerState<PartnerForgotPasswordScreen> {
  late final _id = TextEditingController(text: widget.initialPartnerId);
  final _email = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _loading = false;
  bool _sent = false;
  int _cooldown = 0;
  Timer? _timer;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _email.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _send() async {
    if (_loading ||
        _cooldown > 0 ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(sendPartnerResetProvider)(
        normalizePartnerId(_id.text)!,
        _email.text.trim().toLowerCase(),
      );
      if (!mounted) return;
      setState(() {
        _sent = true;
        _cooldown = 60;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _cooldown--);
        if (_cooldown == 0) timer.cancel();
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is PartnerResetDemoException
              ? l10n.authResetDemo
              : partnerAuthMessage(l10n, error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(Routes.login)),
        title: Text(l10n.authResetTitle),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: KayloCard(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        _sent
                            ? Icons.mark_email_read_outlined
                            : Icons.lock_reset_rounded,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.l),
                      Text(
                        _sent ? l10n.authResetInbox : l10n.authResetTitle,
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _sent
                              ? l10n.authResetSent
                              : l10n.authResetDescription,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      KayloTextField(
                        key: const Key('reset-partner-id'),
                        label: l10n.authPartnerId,
                        hintText: 'KP-000123',
                        controller: _id,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        validator: (value) =>
                            normalizePartnerId(value ?? '') == null
                            ? l10n.authInvalidId
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      KayloTextField(
                        key: const Key('reset-email'),
                        label: l10n.authResetEmail,
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _send(),
                        validator: (value) {
                          final email = (value ?? '').trim();
                          return email.length <= 254 &&
                                  RegExp(
                                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                  ).hasMatch(email) &&
                                  !email.toLowerCase().endsWith(
                                    '@partners.kaylo.app',
                                  )
                              ? null
                              : l10n.authResetInvalidEmail;
                        },
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.m),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              _error!,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.l),
                      KayloButton(
                        text: _cooldown > 0
                            ? l10n.authResetResendIn(_cooldown)
                            : _sent
                            ? l10n.authResetResend
                            : l10n.authResetSend,
                        isLoading: _loading,
                        onPressed: _loading || _cooldown > 0 ? null : _send,
                      ),
                      TextButton(
                        onPressed: () => context.go(Routes.login),
                        child: Text(l10n.authResetBack),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
