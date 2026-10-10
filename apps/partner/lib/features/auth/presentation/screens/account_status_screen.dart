import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/partner_session.dart';
import '../../domain/partner_auth_repository.dart';
import 'login_screen.dart';

class PartnerAccountStatusScreen extends ConsumerWidget {
  const PartnerAccountStatusScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final access = ref.watch(partnerAuthStateProvider).asData?.value;
    final registration = access?.status == PartnerAccessStatus.registration;
    final verification = access?.status == PartnerAccessStatus.verification;
    final rejected = access?.verificationStatus == 'rejected';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 56),
                  const SizedBox(height: 24),
                  Text(
                    registration
                        ? l10n.notRegisteredTitle
                        : verification
                        ? rejected
                              ? l10n.verificationRejected
                              : l10n.verificationUnderReview
                        : l10n.authUnavailableTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    registration
                        ? l10n.authNotIssuedBody
                        : verification
                        ? l10n.authVerificationBody
                        : l10n.authUnavailable,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      await ref
                          .read(partnerAuthRepositoryProvider)
                          .checkAccess();
                      if (context.mounted) context.go(Routes.jobs);
                    },
                    child: Text(l10n.retry),
                  ),
                  if (registration)
                    TextButton(
                      onPressed: () => context.go(Routes.apply),
                      child: Text(l10n.authApply),
                    ),
                  if (verification)
                    TextButton(
                      onPressed: () => context.go(Routes.profile),
                      child: Text(l10n.tabProfile),
                    ),
                  TextButton(
                    onPressed: () => contactPartnerSupport(context),
                    child: Text(l10n.authSupport),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref.read(partnerAuthRepositoryProvider).signOut();
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
    );
  }
}
