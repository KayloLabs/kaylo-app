import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../profile/domain/worker_profile.dart';
import '../../application/application_document_picker.dart';
import '../../application/application_providers.dart';
import '../../application/application_submission.dart';
import '../../domain/worker_application.dart';
import '../widgets/application_text.dart';

class WorkerApplicationScreen extends ConsumerStatefulWidget {
  const WorkerApplicationScreen({super.key});
  @override
  ConsumerState<WorkerApplicationScreen> createState() =>
      _WorkerApplicationScreenState();
}

class _WorkerApplicationScreenState
    extends ConsumerState<WorkerApplicationScreen> {
  final _forms = List.generate(4, (_) => GlobalKey<FormState>());
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _profession = TextEditingController();
  final _experience = TextEditingController();
  final _radius = TextEditingController(text: '15');
  final _upi = TextEditingController();
  final _holder = TextEditingController();
  final _bank = TextEditingController();
  final _account = TextEditingController();
  final _confirmAccount = TextEditingController();
  final _ifsc = TextEditingController();
  final _services = <String>{};
  final _documents = <ApplicationDocumentType, ApplicationDocument>{};
  final _scroll = ScrollController();
  late final ApplicationSubmission _submission;
  String? _district;
  bool _bankPayout = false;
  bool _consent = false;
  bool _busy = false;
  ApplicationDocumentType? _picking;
  int _step = 0;
  Object? _error;
  String? _validation;

  @override
  void initState() {
    super.initState();
    _submission = ref.read(applicationSubmissionProvider);
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _email,
      _profession,
      _experience,
      _radius,
      _upi,
      _holder,
      _bank,
      _account,
      _confirmAccount,
      _ifsc,
    ]) {
      controller.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _move(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _validation = null;
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _next() {
    final l = AppLocalizations.of(context)!;
    if (!(_forms[_step].currentState?.validate() ?? false)) return;
    if (_step == 1 && _services.isEmpty) {
      setState(() => _validation = l.chooseOneService);
      return;
    }
    if (_step == 2 &&
        _documents.length != ApplicationDocumentType.values.length) {
      setState(() => _validation = l.applicationAllDocuments);
      return;
    }
    if (_step < 3) {
      _move(_step + 1);
      return;
    }
    if (!_consent) {
      setState(() => _validation = l.applicationConsentRequired);
      return;
    }
    _send();
  }

  Future<void> _pick(ApplicationDocumentType type) async {
    if (_picking != null) return;
    setState(() {
      _picking = type;
      _error = null;
      _validation = null;
    });
    try {
      final document = await ref
          .read(applicationDocumentPickerProvider)
          .pick(type);
      if (mounted && document != null) {
        setState(() => _documents[type] = document);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _picking = null);
    }
  }

  Future<void> _send() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _validation = null;
    });
    try {
      final status = await _submission.send(
        details: _submission.hasStarted
            ? null
            : ApplicationDetails(
                fullName: _name.text,
                phone: _phone.text,
                email: _email.text,
                profession: _profession.text,
                services: _services.toList(),
                experienceYears: int.tryParse(_experience.text) ?? -1,
                district: _district ?? '',
                travelRadiusKm: int.tryParse(_radius.text) ?? -1,
                upiId: _bankPayout ? null : _upi.text,
                bankAccount: !_bankPayout
                    ? null
                    : ApplicationBankAccount(
                        holder: _holder.text,
                        bankName: _bank.text,
                        accountNumber: _account.text,
                        ifsc: _ifsc.text,
                      ),
                consent: _consent,
              ),
        documents: _submission.hasStarted ? null : _documents,
        onProgress: () {
          if (mounted) setState(() {});
        },
      );
      if (!mounted) return;
      _documents.clear();
      context.go(
        '${Routes.applicationStatus}?reference=${Uri.encodeQueryComponent(status.reference)}',
      );
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final recovering = _submission.hasStarted || _submission.isComplete;
    final labels = [
      l.applicationPersonal,
      l.applicationSkills,
      l.applicationDocuments,
      l.applicationPayout,
    ];
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.applicationTitle),
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _busy ? null : () => context.go(Routes.login),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: recovering
                  ? _recovery(l)
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.applicationStep(_step + 1, 4),
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: List.generate(
                                  4,
                                  (index) => Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: index == 3 ? 0 : 6,
                                      ),
                                      child: AnimatedContainer(
                                        duration:
                                            MediaQuery.disableAnimationsOf(
                                              context,
                                            )
                                            ? Duration.zero
                                            : const Duration(milliseconds: 220),
                                        height: 4,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                          color: index <= _step
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.outlineVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                labels[_step],
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            child: AnimatedSwitcher(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                              child: Form(
                                key: _forms[_step],
                                child: Column(
                                  key: ValueKey(_step),
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (useMock)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: Text(l.applicationDemoNotice),
                                      ),
                                    ...switch (_step) {
                                      0 => _personal(l),
                                      1 => _skills(l),
                                      2 => _documentFields(l),
                                      _ => _payout(l),
                                    },
                                    if (_validation != null)
                                      _errorText(_validation!),
                                    if (_error != null)
                                      _errorText(
                                        applicationFailureText(l, _error!),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                          child: Row(
                            children: [
                              if (_step > 0) ...[
                                Expanded(
                                  child: KayloButton(
                                    text: l.applicationBack,
                                    variant: KayloButtonVariant.secondary,
                                    onPressed: _picking != null
                                        ? null
                                        : () => _move(_step - 1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: KayloButton(
                                  text: _step == 3
                                      ? l.applicationSubmit
                                      : l.applicationContinue,
                                  onPressed: _picking != null ? null : _next,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _personal(AppLocalizations l) => [
    Text(l.applicationIntro),
    const SizedBox(height: 24),
    KayloTextField(
      controller: _name,
      label: l.fullNameLabel,
      maxLength: 120,
      autofillHints: const [AutofillHints.name],
      validator: (v) => (v?.trim().length ?? 0) < 2 ? l.nameRequired : null,
    ),
    const SizedBox(height: 20),
    KayloTextField(
      controller: _phone,
      label: l.applicationPhone,
      maxLength: 24,
      hintText: '+91',
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumber],
      validator: (v) => ApplicationDetails.validPhone(v ?? '')
          ? null
          : l.applicationInvalidPhone,
    ),
    const SizedBox(height: 20),
    KayloTextField(
      controller: _email,
      label: l.applicationEmail,
      maxLength: 254,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      validator: (v) => ApplicationDetails.validEmail(v ?? '')
          ? null
          : l.applicationInvalidEmail,
    ),
    const SizedBox(height: 8),
    Text(l.applicationEmailHint, style: Theme.of(context).textTheme.bodySmall),
  ];

  List<Widget> _skills(AppLocalizations l) => [
    KayloTextField(
      controller: _profession,
      label: l.applicationProfession,
      maxLength: 120,
      validator: (v) =>
          (v?.trim().length ?? 0) >= 2 ? null : l.applicationProfessionRequired,
    ),
    const SizedBox(height: 20),
    Text(l.servicesLabel, style: Theme.of(context).textTheme.titleSmall),
    const SizedBox(height: 8),
    ref
        .watch(applicationServicesProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(applicationFailureText(l, error)),
              TextButton(
                onPressed: () => ref.invalidate(applicationServicesProvider),
                child: Text(l.retry),
              ),
            ],
          ),
          data: (services) => services.isEmpty
              ? Text(l.applicationNoServices)
              : Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: services
                      .map(
                        (service) => FilterChip(
                          label: Text(service.name),
                          selected: _services.contains(service.id),
                          onSelected: (selected) => setState(() {
                            selected
                                ? _services.add(service.id)
                                : _services.remove(service.id);
                            _validation = null;
                          }),
                        ),
                      )
                      .toList(),
                ),
        ),
    const SizedBox(height: 20),
    KayloTextField(
      controller: _experience,
      label: l.applicationExperience,
      maxLength: 2,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) {
        final n = int.tryParse(v ?? '');
        return n != null && n >= 0 && n <= 60
            ? null
            : l.applicationInvalidExperience;
      },
    ),
    const SizedBox(height: 20),
    DropdownButtonFormField<String>(
      initialValue: _district,
      isExpanded: true,
      decoration: InputDecoration(labelText: l.districtLabel),
      items: keralaDistricts
          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
          .toList(),
      onChanged: (value) => setState(() => _district = value),
      validator: (v) => v == null ? l.applicationChooseDistrict : null,
    ),
    const SizedBox(height: 20),
    KayloTextField(
      controller: _radius,
      label: l.travelRadiusLabel,
      maxLength: 3,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) {
        final n = int.tryParse(v ?? '');
        return n != null && n >= 1 && n <= 100 ? null : l.radiusRange;
      },
    ),
  ];

  List<Widget> _documentFields(AppLocalizations l) => [
    Text(l.applicationDocumentsHint),
    const SizedBox(height: 16),
    for (final type in ApplicationDocumentType.values) ...[
      ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        leading: Icon(
          _documents.containsKey(type)
              ? Icons.task_alt_rounded
              : Icons.upload_file_rounded,
          color: _documents.containsKey(type)
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
        title: Text(applicationDocumentLabel(l, type)),
        subtitle: Text(
          _documents[type]?.name ?? l.applicationChooseFile,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _picking == type
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right_rounded),
        onTap: _picking == null ? () => _pick(type) : null,
      ),
      const Divider(height: 1),
    ],
    const SizedBox(height: 16),
    Text(
      l.applicationDocumentsPrivacy,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  ];

  List<Widget> _payout(AppLocalizations l) => [
    SegmentedButton<bool>(
      segments: [
        ButtonSegment(value: false, label: Text(l.applicationUpi)),
        ButtonSegment(value: true, label: Text(l.applicationBank)),
      ],
      selected: {_bankPayout},
      onSelectionChanged: (values) =>
          setState(() => _bankPayout = values.single),
    ),
    const SizedBox(height: 24),
    if (!_bankPayout)
      KayloTextField(
        controller: _upi,
        label: l.upiIdLabel,
        hintText: 'name@bank',
        maxLength: 100,
        validator: (v) =>
            upiIdPattern.hasMatch(v?.trim() ?? '') ? null : l.invalidUpi,
      ),
    if (_bankPayout) ...[
      KayloTextField(
        controller: _holder,
        label: l.applicationAccountHolder,
        maxLength: 120,
        validator: (v) =>
            (v?.trim().length ?? 0) >= 2 ? null : l.applicationBankRequired,
      ),
      const SizedBox(height: 20),
      KayloTextField(
        controller: _bank,
        label: l.applicationBankName,
        maxLength: 120,
        validator: (v) =>
            (v?.trim().length ?? 0) >= 2 ? null : l.applicationBankRequired,
      ),
      const SizedBox(height: 20),
      KayloTextField(
        controller: _account,
        label: l.applicationAccountNumber,
        maxLength: 18,
        obscureText: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (v) => RegExp(r'^[0-9]{9,18}$').hasMatch(v ?? '')
            ? null
            : l.applicationInvalidAccount,
      ),
      const SizedBox(height: 20),
      KayloTextField(
        controller: _confirmAccount,
        label: l.applicationConfirmAccount,
        maxLength: 18,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (v) => v == _account.text && (v?.isNotEmpty ?? false)
            ? null
            : l.applicationAccountMismatch,
      ),
      const SizedBox(height: 20),
      KayloTextField(
        controller: _ifsc,
        label: l.applicationIfsc,
        maxLength: 11,
        validator: (v) =>
            RegExp(
              r'^[A-Z]{4}0[A-Z0-9]{6}$',
            ).hasMatch(v?.trim().toUpperCase() ?? '')
            ? null
            : l.applicationInvalidIfsc,
      ),
    ],
    const SizedBox(height: 24),
    Text(l.applicationReviewHint),
    const SizedBox(height: 8),
    Text('${_name.text.trim()} · ${_profession.text.trim()}'),
    Text('${_district ?? ''} · ${l.travelRadius(_radius.text)}'),
    const SizedBox(height: 16),
    CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: _consent,
      onChanged: (value) => setState(() => _consent = value ?? false),
      title: Text(
        l.applicationConsent,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
    const SizedBox(height: 8),
    Text(l.applicationKeepOpen, style: Theme.of(context).textTheme.bodySmall),
  ];

  Widget _errorText(String text) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Semantics(
      liveRegion: true,
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    ),
  );

  Widget _recovery(AppLocalizations l) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Icon(
        _submission.isComplete
            ? Icons.task_alt_rounded
            : Icons.cloud_upload_outlined,
        size: 52,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 20),
      Text(
        _submission.isComplete
            ? l.applicationUnderReview
            : l.applicationSending,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      Text(l.applicationRecoveryHint),
      if (_submission.receipt != null) ...[
        const SizedBox(height: 20),
        Text(l.applicationReference),
        SelectableText(
          _submission.receipt!.reference,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
      const SizedBox(height: 24),
      Semantics(
        liveRegion: true,
        child: Text(
          l.applicationUploadProgress(_submission.uploaded.length, 5),
        ),
      ),
      const SizedBox(height: 8),
      LinearProgressIndicator(value: _submission.uploaded.length / 5),
      const SizedBox(height: 20),
      for (final type in ApplicationDocumentType.values)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(applicationDocumentLabel(l, type)),
          trailing: Icon(
            _submission.uploaded.contains(type)
                ? Icons.check_circle_outline
                : Icons.schedule,
          ),
        ),
      if (_error != null) _errorText(applicationFailureText(l, _error!)),
      const SizedBox(height: 24),
      KayloButton(
        text: _submission.isComplete ? l.applicationCheckStatus : l.retry,
        isLoading: _busy,
        onPressed: _busy ? null : _send,
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: _busy ? null : () => context.go(Routes.login),
        child: Text(l.applicationBackToSignIn),
      ),
    ],
  );
}
