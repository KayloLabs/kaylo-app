import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'care_call_screen.dart';
import 'trusted_contacts_screen.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/error_state.dart';
import 'package:kaylo_ui/widgets/kaylo_chip.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/sos_phone_calls.dart';
import '../../application/phone_contact_picker.dart';
import '../../application/care_providers.dart';
import '../../domain/care_models.dart';
import '../widgets/care_scaffold.dart';

const _holdDuration = Duration(seconds: 3);

class EmergencySosScreen extends ConsumerStatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  ConsumerState<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends ConsumerState<EmergencySosScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _hold;
  late final SosPhoneCalls _calls;
  StreamSubscription<SosCallState>? _callUpdates;
  SosCallState? _callState;
  bool _inApp = !useMockData;
  bool _holding = false;
  bool _sending = false;
  // Set once the hold completes, so the pointer-up that follows is not
  // mistaken for an early release.
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _calls = ref.read(sosPhoneCallsProvider);
    if (_calls.supported) {
      _callUpdates = _calls.updates.listen(
        (state) {
          if (!mounted) return;
          setState(() {
            _callState = state;
            _sending = state.running;
          });
        },
        onError: (Object error) {
          if (!mounted) return;
          setState(() => _sending = false);
          KayloSnackbar.showError(
            context,
            AppLocalizations.of(context)!.somethingWentWrong,
          );
        },
      );
    }
    // A full three-second hold guards against pocket presses; releasing
    // early winds the ring back instead of firing.
    _hold = AnimationController(vsync: this, duration: _holdDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _trigger();
      });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callUpdates?.cancel();
    if (_calls.supported) {
      unawaited(
        _calls.stop().then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      );
    }
    _hold.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _holding) {
      _hold.reset();
      setState(() => _holding = false);
    }
  }

  void _onPressStart() {
    if (_sending || (!_inApp && !_calls.supported)) return;
    _fired = false;
    KayloFeedback.press();
    setState(() => _holding = true);
    _hold.forward(from: 0);
  }

  void _onPressEnd({required bool cancelled}) {
    if (_fired || _hold.status == AnimationStatus.completed) return;
    _hold.reset();
    setState(() => _holding = false);
    if (!cancelled) {
      KayloSnackbar.showInfo(
        context,
        AppLocalizations.of(context)!.sosReleasedEarly,
      );
    }
  }

  Future<void> _trigger() async {
    final l10n = AppLocalizations.of(context)!;
    _fired = true;
    _hold.reset();
    setState(() => _holding = false);

    if (_inApp) {
      setState(() => _sending = true);
      try {
        final response = await ref
            .read(supabaseClientProvider)
            .functions
            .invoke('care-call', body: {'action': 'start'});
        final callId = response.data['call_id'] as String;
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CareCallScreen(callId: callId)),
        );
      } on FunctionException catch (e) {
        final details = e.details;
        final message = details is Map && details['error'] is Map
            ? details['error']['message']
            : null;
        if (mounted) {
          KayloSnackbar.showError(
            context,
            message?.toString() ??
                'Could not start SOS. Check your connection and trusted contacts.',
          );
        }
      } catch (_) {
        if (mounted) {
          KayloSnackbar.showError(
            context,
            'Could not start SOS. Please try again.',
          );
        }
      } finally {
        if (mounted) setState(() => _sending = false);
      }
      return;
    }
    final contacts =
        ref.read(emergencyContactsProvider).whenOrNull(data: (c) => c) ??
        const <EmergencyContact>[];
    if (contacts.isEmpty) {
      KayloSnackbar.showError(context, l10n.sosNoContacts);
      return;
    }

    KayloFeedback.alert();
    setState(() => _sending = true);
    try {
      final state = await _calls.start(contacts);
      if (!mounted) return;
      setState(() {
        _callState = state;
        _sending = state.running;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      KayloSnackbar.showError(
        context,
        error.message ?? l10n.somethingWentWrong,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      KayloSnackbar.showError(context, l10n.somethingWentWrong);
    }
  }

  Future<void> _stopCalls() async {
    try {
      final state = await _calls.stop();
      if (mounted) {
        setState(() {
          _callState = state;
          _sending = false;
        });
      }
    } catch (_) {
      if (mounted) {
        KayloSnackbar.showError(
          context,
          AppLocalizations.of(context)!.somethingWentWrong,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contacts = ref.watch(emergencyContactsProvider);
    final history = ref.watch(sosHistoryProvider);

    return CareScaffold(
      title: l10n.emergencySos,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              icon: Icon(Icons.groups_outlined),
              label: Text('Kaylo call'),
            ),
            ButtonSegment(
              value: false,
              icon: Icon(Icons.sim_card_outlined),
              label: Text('SIM call'),
            ),
          ],
          selected: {_inApp},
          onSelectionChanged: _sending || _holding
              ? null
              : (selection) => setState(() => _inApp = selection.single),
        ),
        const SizedBox(height: AppSpacing.m),
        if (_inApp)
          OutlinedButton.icon(
            onPressed: _sending
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TrustedContactsScreen(),
                    ),
                  ),
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Manage trusted contacts'),
          ),
        const SizedBox(height: AppSpacing.l),
        Text(
          _inApp
              ? 'Hold for 3 seconds to invite your trusted Kaylo contacts. They can join the call together. An invitation does not mean someone has answered.'
              : l10n.sosHoldHint,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (_inApp || _calls.supported)
          Center(
            child: _SosHoldButton(
              controller: _hold,
              holding: _holding,
              sending: _sending,
              onPressStart: _onPressStart,
              onPressEnd: () => _onPressEnd(cancelled: false),
              onPressCancel: () => _onPressEnd(cancelled: true),
            ),
          )
        else
          Text(l10n.sosAndroidOnly, textAlign: TextAlign.center),
        if (_callState case final state?) ...[
          const SizedBox(height: AppSpacing.l),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(switch (state.status) {
                    'calling' => l10n.sosCallingPrimary(state.name ?? ''),
                    'waiting' => l10n.sosCallWaiting(state.name ?? ''),
                    'finished' => l10n.sosCallsFinished,
                    'stopped' => l10n.sosCallsStopped,
                    'failed' => state.error ?? l10n.somethingWentWrong,
                    _ => l10n.emergencySos,
                  }, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.s),
                  Text(l10n.sosCallProgress(state.attempted, state.total)),
                  if (state.running)
                    TextButton.icon(
                      onPressed: _stopCalls,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: Text(l10n.sosStopCalls),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (!_inApp) ...[
          const SizedBox(height: AppSpacing.xxxl),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.emergencyContacts,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(l10n.addContact),
                onPressed: () {
                  KayloFeedback.tap();
                  showCareSheet(context, const _AddContactSheet());
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          ...contacts.when(
            data: (list) => list.isEmpty
                ? [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          l10n.sosNoContacts,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ]
                : [
                    for (final contact in list) ...[
                      _ContactCard(contact: contact),
                      const SizedBox(height: AppSpacing.m),
                    ],
                  ],
            loading: () => const [Center(child: KayloLoader())],
            error: (error, _) => [
              ErrorState(
                title: l10n.somethingWentWrong,
                message: error.toString(),
                onRetry: () => ref.invalidate(emergencyContactsProvider),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                KayloFeedback.tap();
                context.push(Routes.careSosHistory);
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: AppColors.careAccent,
                    ),
                    const SizedBox(width: AppSpacing.l),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.sosHistory,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            l10n.alertsCount(
                              history.whenOrNull(data: (h) => h.length) ?? 0,
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SosHoldButton extends StatelessWidget {
  final AnimationController controller;
  final bool holding;
  final bool sending;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;
  final VoidCallback onPressCancel;

  const _SosHoldButton({
    required this.controller,
    required this.holding,
    required this.sending,
    required this.onPressStart,
    required this.onPressEnd,
    required this.onPressCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deepRed = Color.lerp(AppColors.error, Colors.black, 0.25)!;

    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => onPressStart(),
          onTapUp: (_) => onPressEnd(),
          onTapCancel: onPressCancel,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final remaining =
                  (_holdDuration.inSeconds * (1 - controller.value)).ceil();
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 224,
                    height: 224,
                    child: CircularProgressIndicator(
                      value: controller.value,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      color: AppColors.error,
                      backgroundColor: AppColors.error.withValues(alpha: 0.15),
                    ),
                  ),
                  AnimatedScale(
                    scale: holding ? 0.94 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: 188,
                      height: 188,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [AppColors.error, deepRed],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: sending
                          ? const Center(
                              child: KayloLoader(
                                isMono: true,
                                monoColor: Colors.white,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.sos_rounded,
                                  color: Colors.white,
                                  size: 56,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  l10n.pressAndHold,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  holding
                                      ? l10n.secondsShort(remaining)
                                      : l10n.holdSeconds,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContactCard extends ConsumerWidget {
  final EmergencyContact contact;

  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final primary = contact.isPrimary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.m,
          AppSpacing.s,
          AppSpacing.m,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: primary
                  ? AppColors.error
                  : AppColors.careAccent.withValues(alpha: 0.15),
              child: Text(
                contact.name.isEmpty ? '?' : contact.name[0].toUpperCase(),
                style: TextStyle(
                  color: primary ? Colors.white : AppColors.careAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          contact.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (primary) ...[
                        const SizedBox(width: AppSpacing.s),
                        KayloChip(
                          label: l10n.primary,
                          icon: Icons.star_rounded,
                          variant: KayloChipVariant.error,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.relation.isEmpty
                        ? contact.phone
                        : '${contact.relation} · ${contact.phone}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) async {
                KayloFeedback.tap();
                final controller = ref.read(careControllerProvider);
                if (value == 'primary') {
                  await controller.setPrimaryContact(contact.id);
                } else if (value == 'remove') {
                  await controller.removeContact(contact.id);
                }
              },
              itemBuilder: (context) => [
                if (!primary)
                  PopupMenuItem(
                    value: 'primary',
                    child: Text(l10n.setAsPrimary),
                  ),
                PopupMenuItem(
                  value: 'remove',
                  child: Text(
                    l10n.removeContact,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddContactSheet extends ConsumerStatefulWidget {
  const _AddContactSheet();

  @override
  ConsumerState<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends ConsumerState<_AddContactSheet> {
  final _name = TextEditingController();
  final _relation = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;
  bool _picking = false;

  @override
  void dispose() {
    _name.dispose();
    _relation.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    setState(() => _picking = true);
    try {
      final contact = await PhoneContactPicker.pick();
      if (!mounted || contact == null) return;
      _name.text = contact['name'] ?? '';
      _phone.text = contact['phone'] ?? '';
    } on PlatformException catch (error) {
      if (mounted) {
        KayloSnackbar.showError(
          context,
          error.message ?? 'Could not open phone contacts.',
        );
      }
    } catch (_) {
      if (mounted) {
        KayloSnackbar.showError(context, 'Could not open phone contacts.');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty) {
      KayloSnackbar.showError(context, l10n.nameRequired);
      return;
    }
    if (phone.isEmpty) {
      KayloSnackbar.showError(context, l10n.phoneRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(careControllerProvider)
          .addContact(
            name: name,
            relation: _relation.text.trim(),
            phone: phone,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        KayloSnackbar.showError(context, l10n.somethingWentWrong);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.addContact, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.l),
          if (PhoneContactPicker.supported) ...[
            OutlinedButton.icon(
              onPressed: _saving || _picking ? null : _pickContact,
              icon: const Icon(Icons.contacts_outlined),
              label: const Text('Choose from phone contacts'),
            ),
            const SizedBox(height: AppSpacing.m),
          ],
          KayloTextField(label: l10n.contactName, controller: _name),
          const SizedBox(height: AppSpacing.m),
          KayloTextField(
            label: l10n.relationship,
            hintText: l10n.relationshipHint,
            controller: _relation,
          ),
          const SizedBox(height: AppSpacing.m),
          KayloTextField(
            label: l10n.phoneNumber,
            hintText: '+91',
            controller: _phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: _saving || _picking ? null : _save,
            child: Text(l10n.save),
          ),
          const SizedBox(height: AppSpacing.s),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
