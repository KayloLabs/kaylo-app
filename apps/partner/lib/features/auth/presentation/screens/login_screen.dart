import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/kaylo_logo.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/partner_session.dart';
import '../../domain/partner_auth_repository.dart';
import 'auth_messages.dart';

Future<void> contactPartnerSupport(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  var opened = false;
  try {
    opened = await launchUrl(Uri(scheme: 'mailto', path: 'kayloapp@gmail.com'));
  } catch (_) {
    // Keep the support address available even without an email application.
  }
  if (!opened && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.authSupport),
        content: const SelectableText('kayloapp@gmail.com'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

class PartnerLoginScreen extends ConsumerStatefulWidget {
  const PartnerLoginScreen({super.key});
  @override
  ConsumerState<PartnerLoginScreen> createState() => _PartnerLoginScreenState();
}

class _PartnerLoginScreenState extends ConsumerState<PartnerLoginScreen> {
  final _id = TextEditingController(text: useMockData ? 'KP-000123' : '');
  final _password = TextEditingController(text: useMockData ? 'kaylo123' : '');
  bool _loading = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_loading) return;
    final l10n = AppLocalizations.of(context)!;
    if (normalizePartnerId(_id.text) == null) {
      setState(() => _error = l10n.authInvalidId);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(partnerAuthRepositoryProvider)
          .signIn(_id.text, _password.text);
      if (!mounted) return;
      KayloFeedback.press();
      context.go(Routes.jobs);
    } catch (error) {
      if (mounted) setState(() => _error = partnerAuthMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const KayloLogo(width: 80),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(l10n.authSubtitle, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xl),
                  KayloCard(
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.authSignIn,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.l),
                          KayloTextField(
                            key: const Key('partner-id'),
                            label: l10n.authPartnerId,
                            hintText: 'KP-000123',
                            controller: _id,
                            autofillHints: const [AutofillHints.username],
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          KayloTextField(
                            key: const Key('partner-password'),
                            label: l10n.authPassword,
                            controller: _password,
                            obscureText: !_showPassword,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) => _signIn(),
                            textInputAction: TextInputAction.done,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _showPassword
                                  ? l10n.authHidePassword
                                  : l10n.authShowPassword,
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.m),
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
                          const SizedBox(height: AppSpacing.l),
                          KayloButton(
                            text: l10n.authSignIn,
                            isLoading: _loading,
                            onPressed: _loading ? null : _signIn,
                          ),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => context.push(
                                    Routes.forgotPassword,
                                    extra: _id.text.trim(),
                                  ),
                            child: Text(l10n.authForgotPassword),
                          ),
                          if (useMockData)
                            Text(
                              l10n.authDemoCredentials,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextButton(
                    onPressed: () => context.go(Routes.apply),
                    child: Text(l10n.authApply),
                  ),
                  TextButton(
                    onPressed: () => context.go(Routes.applicationStatus),
                    child: Text(l10n.authCheckStatus),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
