import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/kaylo_chip.dart';
import '../../../../core/widgets/kaylo_loader.dart';
import '../../../../core/widgets/kaylo_snackbar.dart';
import '../../../../core/widgets/kaylo_text_field.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../home/application/user_location_provider.dart';
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold;
  bool _holding = false;
  bool _sending = false;
  // Set once the hold completes, so the pointer-up that follows is not
  // mistaken for an early release.
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    // A full three-second hold guards against pocket presses; releasing
    // early winds the ring back instead of firing.
    _hold = AnimationController(vsync: this, duration: _holdDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _trigger();
      });
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _onPressStart() {
    if (_sending) return;
    _fired = false;
    KayloFeedback.press();
    setState(() => _holding = true);
    _hold.forward();
  }

  void _onPressEnd({required bool cancelled}) {
    if (_fired || _hold.status == AnimationStatus.completed) return;
    _hold.reverse();
    setState(() => _holding = false);
    if (!cancelled) {
      KayloSnackbar.showInfo(
          context, AppLocalizations.of(context)!.sosReleasedEarly);
    }
  }

  Future<void> _trigger() async {
    final l10n = AppLocalizations.of(context)!;
    _fired = true;
    _hold.reset();
    setState(() => _holding = false);

    final contacts =
        ref.read(emergencyContactsProvider).whenOrNull(data: (c) => c) ??
            const <EmergencyContact>[];
    if (contacts.isEmpty) {
      KayloSnackbar.showError(context, l10n.sosNoContacts);
      return;
    }

    KayloFeedback.alert();
    setState(() => _sending = true);
    final location = ref.read(userLocationProvider).label;
    try {
      final alert =
          await ref.read(careControllerProvider).triggerSos(location: location);
      if (!mounted) return;
      await _showDispatched(alert);
    } catch (_) {
      if (mounted) KayloSnackbar.showError(context, l10n.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showDispatched(SosAlert alert) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Theme(
        data: AppTheme.careTheme,
        child: AlertDialog(
          icon: const Icon(Icons.sos_rounded, color: AppColors.error, size: 44),
          title: Text(l10n.sosSentTitle, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogLine(
                icon: Icons.group_rounded,
                text: l10n.sosSentContacts(alert.notifiedContacts),
              ),
              if (alert.location != null)
                _DialogLine(
                  icon: Icons.place_rounded,
                  text: l10n.locationShared(alert.location!),
                ),
              if (alert.primaryContactName != null)
                _DialogLine(
                  icon: Icons.call_rounded,
                  text: l10n.sosCallingPrimary(alert.primaryContactName!),
                  emphasis: true,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.dismiss),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contacts = ref.watch(emergencyContactsProvider);
    final history = ref.watch(sosHistoryProvider);

    return CareScaffold(
      title: l10n.emergencySos,
      children: [
        Text(
          l10n.sosHoldHint,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: _SosHoldButton(
            controller: _hold,
            holding: _holding,
            sending: _sending,
            onPressStart: _onPressStart,
            onPressEnd: () => _onPressEnd(cancelled: false),
            onPressCancel: () => _onPressEnd(cancelled: true),
          ),
        ),
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
                  const Icon(Icons.history_rounded, color: AppColors.careAccent),
                  const SizedBox(width: AppSpacing.l),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.sosHistory,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          l10n.alertsCount(
                            history.whenOrNull(data: (h) => h.length) ?? 0,
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
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
    );
  }
}

class _DialogLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool emphasis;

  const _DialogLine({
    required this.icon,
    required this.text,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: emphasis ? AppColors.error : null),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: emphasis ? FontWeight.w700 : null,
                    color: emphasis ? AppColors.error : null,
                  ),
            ),
          ),
        ],
      ),
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
                                const Icon(Icons.sos_rounded,
                                    color: Colors.white, size: 56),
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
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
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

  @override
  void dispose() {
    _name.dispose();
    _relation.dispose();
    _phone.dispose();
    super.dispose();
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
      await ref.read(careControllerProvider).addContact(
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
            onPressed: _saving ? null : _save,
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
