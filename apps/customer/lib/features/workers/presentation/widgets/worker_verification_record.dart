import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/models/worker.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/widgets/error_state.dart';
import 'package:kaylo_ui/widgets/kaylo_logo.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../home/application/home_providers.dart';
import '../../application/workers_providers.dart';

/// A view of the live verification flag, never a fabricated qualification.
/// The existing data does not contain check documents, an issuer or issue date.
Future<void> showWorkerVerificationRecord(
  BuildContext context,
  String workerId,
) async {
  KayloFeedback.press();
  final reducedMotion = MediaQuery.disableAnimationsOf(context);
  await Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: Duration(milliseconds: reducedMotion ? 0 : 420),
      reverseTransitionDuration: Duration(
        milliseconds: reducedMotion ? 0 : 260,
      ),
      pageBuilder: (_, _, _) => WorkerVerificationRecord(workerId: workerId),
      transitionsBuilder: (_, animation, _, child) {
        final eased = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: eased,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, .035),
              end: Offset.zero,
            ).animate(eased),
            child: child,
          ),
        );
      },
    ),
  );
}

class WorkerVerificationRecord extends ConsumerWidget {
  final String workerId;

  const WorkerVerificationRecord({super.key, required this.workerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final worker = ref.watch(workerDetailProvider(workerId));
    final services = ref.watch(fullCatalogProvider).asData?.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.verificationRecord),
        actions: [
          IconButton(
            tooltip: l10n.refreshVerification,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(workerDetailProvider(workerId)),
          ),
        ],
      ),
      body: worker.when(
        data: (person) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: _Record(
                  worker: person,
                  services:
                      services
                          ?.where((s) => person.skillIds.contains(s.id))
                          .map((s) => s.name)
                          .toList() ??
                      const [],
                ),
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          title: l10n.somethingWentWrong,
          message: l10n.verificationLoadError,
          onRetry: () => ref.invalidate(workerDetailProvider(workerId)),
        ),
      ),
    );
  }
}

class _Record extends StatelessWidget {
  final Worker worker;
  final List<String> services;

  const _Record({required this.worker, required this.services});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.brandPrimaryDark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final verified = worker.isVerified;
    return Semantics(
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : const Color(0xFFFFFDF6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ink.withValues(alpha: .16)),
        ),
        padding: const EdgeInsets.all(9),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: ink.withValues(alpha: .10)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ClipRect(
                  child: Align(
                    widthFactor: .5,
                    heightFactor: .4,
                    child: KayloLogo(width: 200, isMono: true, monoColor: ink),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                l10n.verificationRecord,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ink,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(
                    milliseconds: MediaQuery.disableAnimationsOf(context)
                        ? 0
                        : 700,
                  ),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => CustomPaint(
                    foregroundPainter: _VerificationRing(
                      progress: value,
                      color: ink.withValues(alpha: .4),
                    ),
                    child: Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ink.withValues(alpha: .07),
                      ),
                      child: Icon(
                        verified
                            ? Icons.verified_outlined
                            : Icons.pending_outlined,
                        size: 38,
                        color: ink,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                worker.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                verified ? l10n.kayloVerified : l10n.notYetVerified,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                verified
                    ? l10n.verificationRecorded
                    : l10n.verificationNotRecorded,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: secondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              Divider(color: ink.withValues(alpha: .15)),
              const SizedBox(height: 12),
              if (worker.location.isNotEmpty)
                _RecordField(label: l10n.serviceArea, value: worker.location),
              if (services.isNotEmpty)
                _RecordField(
                  label: l10n.listedServices,
                  value: services.join(' · '),
                ),
              _RecordField(label: l10n.profileReference, value: worker.id),
              const SizedBox(height: 8),
              Divider(color: ink.withValues(alpha: .15)),
              const SizedBox(height: 12),
              Text(
                l10n.verificationScope,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: secondary, height: 1.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordField extends StatelessWidget {
  final String label;
  final String value;

  const _RecordField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        SelectableText(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class _VerificationRing extends CustomPainter {
  final double progress;
  final Color color;

  const _VerificationRing({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(
      (Offset.zero & size).deflate(2),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_VerificationRing oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
