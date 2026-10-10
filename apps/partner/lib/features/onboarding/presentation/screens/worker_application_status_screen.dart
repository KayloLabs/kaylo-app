import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../application/application_providers.dart';
import '../../domain/worker_application.dart';
import '../widgets/application_text.dart';

class WorkerApplicationStatusScreen extends ConsumerStatefulWidget {
  const WorkerApplicationStatusScreen({super.key, this.initialReference});
  final String? initialReference;

  @override
  ConsumerState<WorkerApplicationStatusScreen> createState() =>
      _WorkerApplicationStatusScreenState();
}

class _WorkerApplicationStatusScreenState
    extends ConsumerState<WorkerApplicationStatusScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _reference;
  bool _busy = false;
  ApplicationStatus? _status;
  Object? _error;

  @override
  void initState() {
    super.initState();
    String? savedReference;
    try {
      savedReference = ref
          .read(sharedPreferencesProvider)
          .getString(applicationReferencePreferenceKey);
    } catch (_) {}
    _reference = TextEditingController(
      text: widget.initialReference ?? savedReference ?? '',
    );
    if (_reference.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _lookup();
      });
    }
  }

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    final requestedReference = _reference.text.trim().toUpperCase();
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _status = null;
    });
    try {
      final status = await ref
          .read(workerApplicationRepositoryProvider)
          .checkStatus(requestedReference);
      if (mounted &&
          _reference.text.trim().toUpperCase() == requestedReference) {
        setState(() => _status = status);
      }
    } catch (error) {
      if (mounted &&
          _reference.text.trim().toUpperCase() == requestedReference) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _support() async {
    final l = AppLocalizations.of(context)!;
    final launched = await launchUrl(
      Uri(
        scheme: 'mailto',
        path: 'kayloapp@gmail.com',
        query:
            'subject=${Uri.encodeComponent(l.applicationSupportSubject(_reference.text.trim().toUpperCase()))}',
      ),
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.applicationSupportHint)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.applicationCheckStatus),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(Routes.login),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(l.applicationStatusHint),
                const SizedBox(height: 24),
                Form(
                  key: _form,
                  child: KayloTextField(
                    controller: _reference,
                    label: l.applicationReference,
                    maxLength: 80,
                    validator: (v) =>
                        RegExp(
                          r'^[A-Z0-9-]{8,80}$',
                        ).hasMatch(v?.trim().toUpperCase() ?? '')
                        ? null
                        : l.applicationInvalidReference,
                    onChanged: (_) {
                      setState(() {
                        _status = null;
                        _error = null;
                      });
                    },
                    onSubmitted: (_) => _lookup(),
                  ),
                ),
                const SizedBox(height: 16),
                KayloButton(
                  text: l.applicationCheckStatus,
                  isLoading: _busy,
                  onPressed: _busy ? null : _lookup,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        applicationFailureText(l, _error!),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                if (_status != null) _statusView(l, _status!),
                if (useMock)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(l.applicationDemoNotice),
                  ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: _support,
                  icon: const Icon(Icons.mail_outline_rounded),
                  label: Text(l.applicationContactSupport),
                ),
                Center(
                  child: SelectableText(
                    'kayloapp@gmail.com',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(Routes.login),
                  child: Text(l.applicationBackToSignIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusView(AppLocalizations l, ApplicationStatus status) {
    final (title, body, icon) = switch (status.stage) {
      WorkerApplicationStage.submitted => (
        l.applicationIncomplete,
        l.applicationIncompleteHint,
        Icons.upload_file_outlined,
      ),
      WorkerApplicationStage.underReview => (
        l.applicationUnderReview,
        l.applicationUnderReviewHint,
        Icons.fact_check_outlined,
      ),
      WorkerApplicationStage.approved => (
        l.applicationApproved,
        l.applicationApprovedHint,
        Icons.verified_outlined,
      ),
      WorkerApplicationStage.rejected => (
        l.applicationRejected,
        l.applicationRejectedHint,
        Icons.info_outline,
      ),
    };
    final submission = ref.read(applicationSubmissionProvider);
    final canResume =
        !submission.isComplete &&
        submission.hasStarted &&
        submission.receipt?.reference == status.reference;
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 36),
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(body, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SelectableText(
            status.reference,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: status.reference));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.applicationReferenceCopied)),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(l.applicationCopyReference),
          ),
          const SizedBox(height: 12),
          Text(
            l.applicationUploadProgress(status.documentsReceived, 5),
            textAlign: TextAlign.center,
          ),
          if (canResume) ...[
            const SizedBox(height: 20),
            KayloButton(
              text: l.applicationResumeUpload,
              onPressed: () => context.go(Routes.apply),
            ),
          ],
        ],
      ),
    );
  }
}
