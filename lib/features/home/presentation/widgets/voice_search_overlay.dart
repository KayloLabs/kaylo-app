import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/service_item.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/kaylo_snackbar.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/home_providers.dart';
import '../../application/voice_search.dart';

/// Opens the full-screen voice search overlay: a Siri-style animated
/// gradient ring around the screen edge in Kaylo's colors, with the
/// live transcript in the middle. Shows the localized unavailable
/// notice instead when the device has no usable recogniser.
Future<void> showVoiceSearchOverlay(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final speech = ref.read(speechServiceProvider);

  KayloFeedback.press();
  final available = await speech.init();
  if (!context.mounted) return;
  if (!available) {
    KayloSnackbar.showInfo(context, l10n.voiceUnavailable);
    return;
  }

  await Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => const VoiceSearchOverlay(),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
  speech.onError = null;
  speech.onStatus = null;
  await speech.cancel();
}

enum _VoicePhase { listening, matching, results, noMatch, micDenied }

class VoiceSearchOverlay extends ConsumerStatefulWidget {
  const VoiceSearchOverlay({super.key});

  @override
  ConsumerState<VoiceSearchOverlay> createState() =>
      _VoiceSearchOverlayState();
}

class _VoiceSearchOverlayState extends ConsumerState<VoiceSearchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;
  _VoicePhase _phase = _VoicePhase.listening;
  String _transcript = '';
  List<ServiceItem> _matches = const [];
  bool _finished = false;

  /// 0..1 ring intensity: follows the mic level where the platform
  /// reports one, otherwise a gentle idle breath drives it.
  double _energy = 0.4;
  double _energyTarget = 0.4;
  bool _hasLevels = false;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _wave.addListener(_tick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
  }

  void _tick() {
    if (!_hasLevels && _phase == _VoicePhase.listening) {
      _energyTarget =
          0.42 + 0.22 * math.sin(_wave.value * 2 * math.pi * 4.5);
    }
    final eased = lerpDouble(_energy, _energyTarget, 0.12)!;
    if ((eased - _energy).abs() > 0.001) {
      _energy = eased;
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    final speech = ref.read(speechServiceProvider);
    setState(() {
      _phase = _VoicePhase.listening;
      _transcript = '';
      _matches = const [];
      _finished = false;
      _hasLevels = false;
      _energyTarget = 0.4;
    });

    speech.onError = (error, permanent) {
      if (!mounted || _finished) return;
      if (SpeechService.isPermissionError(error)) {
        setState(() => _phase = _VoicePhase.micDenied);
        _finished = true;
        _energyTarget = 0.15;
      } else if (_transcript.isNotEmpty) {
        _finish(_transcript);
      } else {
        setState(() => _phase = _VoicePhase.noMatch);
        _finished = true;
        _energyTarget = 0.15;
      }
    };
    speech.onStatus = (status) {
      if (!mounted || _finished) return;
      if ((status == 'notListening' || status == 'done') &&
          _phase == _VoicePhase.listening) {
        if (_transcript.isNotEmpty) {
          _finish(_transcript);
        } else if (status == 'done') {
          setState(() => _phase = _VoicePhase.noMatch);
          _finished = true;
          _energyTarget = 0.15;
        }
      }
    };

    final languageCode = Localizations.localeOf(context).languageCode;
    final localeId = await speech.localeFor(languageCode);
    await speech.listen(
      localeId: localeId,
      onSoundLevel: (level) {
        // Android reports roughly -2..10 dB; normalise into 0..1.
        _hasLevels = true;
        _energyTarget = ((level + 2) / 12).clamp(0.15, 1.0);
      },
      onResult: (words, isFinal) {
        if (!mounted || _finished) return;
        setState(() => _transcript = words);
        if (isFinal && words.isNotEmpty) _finish(words);
      },
    );
  }

  Future<void> _stopEarly() async {
    KayloFeedback.tap();
    await ref.read(speechServiceProvider).stop();
    if (!mounted || _finished) return;
    if (_transcript.isNotEmpty) {
      _finish(_transcript);
    } else {
      setState(() => _phase = _VoicePhase.noMatch);
      _finished = true;
      _energyTarget = 0.15;
    }
  }

  Future<void> _finish(String words) async {
    if (_finished) return;
    _finished = true;
    setState(() => _phase = _VoicePhase.matching);
    _energyTarget = 0.3;
    await ref.read(speechServiceProvider).stop();
    try {
      final pool = await ref.read(fullCatalogProvider.future);
      if (!mounted) return;
      final matches = matchServicesToTranscript(words, pool);
      setState(() {
        _matches = matches;
        _phase = matches.isEmpty ? _VoicePhase.noMatch : _VoicePhase.results;
      });
      _energyTarget = 0.2;
      if (matches.isNotEmpty) KayloFeedback.tap();
    } catch (_) {
      if (!mounted) return;
      setState(() => _phase = _VoicePhase.noMatch);
      _energyTarget = 0.15;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dimmed, blurred backdrop over the app.
          GestureDetector(
            onTap: _phase == _VoicePhase.listening ? _stopEarly : null,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Container(color: Colors.black.withValues(alpha: 0.35)),
            ),
          ),
          // The Siri-style ring, repainting every frame.
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _wave,
              builder: (_, _) => CustomPaint(
                painter: SiriEdgePainter(t: _wave.value, energy: _energy),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: switch (_phase) {
                      _VoicePhase.listening =>
                        _ListeningContent(transcript: _transcript, l10n: l10n),
                      _VoicePhase.matching => const Padding(
                          key: ValueKey('matching'),
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child:
                              CircularProgressIndicator(color: Colors.white),
                        ),
                      _VoicePhase.results => _ResultsCard(
                          transcript: _transcript,
                          matches: _matches,
                          l10n: l10n,
                          onRetry: _startListening,
                        ),
                      _VoicePhase.noMatch => _MessageCard(
                          key: const ValueKey('noMatch'),
                          icon: Icons.search_off_rounded,
                          transcript: _transcript,
                          message: l10n.voiceNoMatch,
                          retryLabel: l10n.voiceTryAgain,
                          l10n: l10n,
                          onRetry: _startListening,
                        ),
                      _VoicePhase.micDenied => _MessageCard(
                          key: const ValueKey('micDenied'),
                          icon: Icons.mic_off_rounded,
                          transcript: '',
                          message: l10n.voiceMicDenied,
                          retryLabel: l10n.voiceTryAgain,
                          l10n: l10n,
                          onRetry: _startListening,
                        ),
                    },
                  ),
                  const Spacer(),
                  if (_phase == _VoicePhase.listening)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.l),
                      child: GestureDetector(
                        onTap: _stopEarly,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.55),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(Icons.mic_rounded,
                              color: Colors.white, size: 34),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Siri-style edge glow as a field of light, not a stroke: soft
/// overlapping orbs of Kaylo green ride the screen edge, swelling and
/// fading as waves of intensity travel around the perimeter, and the
/// whole field breathes with [energy]. No visible outline anywhere.
class SiriEdgePainter extends CustomPainter {
  final double t;
  final double energy;

  SiriEdgePainter({required this.t, required this.energy});

  static const _green = AppColors.brandPrimaryBright;
  static const _mint = Color(0xFF8FE0B4);

  /// Intensity of the light field at perimeter position [phase]
  /// (0..1 around the edge): three travelling waves of different
  /// speeds and directions layered into slow organic swells.
  double _fieldIntensity(double phase) {
    final a = 0.5 + 0.5 * math.sin(2 * math.pi * (phase * 2 - t * 1.2));
    final b = 0.5 + 0.5 * math.sin(2 * math.pi * (phase * 3 + t * 0.7) + 1.7);
    return 0.55 * a + 0.45 * b;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 2.0;
    final rect = Rect.fromLTWH(
        inset, inset, size.width - inset * 2, size.height - inset * 2);
    final base = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(48)));
    final metric = base.computeMetrics().first;
    final length = metric.length;

    const count = 128;
    final softPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);
    final innerPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13);

    for (var i = 0; i < count; i++) {
      final phase = i / count;
      final d = length * phase;
      final tangent = metric.getTangentForOffset(d)!;
      final normal = Offset(-tangent.vector.dy, tangent.vector.dx);

      final field = _fieldIntensity(phase);
      final glow = (0.20 + 0.80 * field) * (0.35 + 0.65 * energy);
      if (glow < 0.06) continue;

      // Orbs sway gently in and out of the edge as the field moves.
      final sway = normal *
          (3 + 6 * energy) *
          math.sin(2 * math.pi * (phase * 2 + t * 0.6));
      final centre = tangent.position + sway;

      final color = Color.lerp(_green, _mint, field)!;

      // Wide soft halo.
      softPaint.color = color.withValues(alpha: 0.16 * glow + 0.04);
      canvas.drawCircle(centre, 16 + 34 * glow, softPaint);

      // Brighter heart of the orb.
      innerPaint.color = color.withValues(alpha: 0.30 * glow + 0.05);
      canvas.drawCircle(centre, 6 + 15 * glow, innerPaint);
    }
  }

  @override
  bool shouldRepaint(SiriEdgePainter old) =>
      old.t != t || old.energy != energy;
}

class _ListeningContent extends StatelessWidget {
  final String transcript;
  final AppLocalizations l10n;

  const _ListeningContent({required this.transcript, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('listening'),
      children: [
        Text(
          l10n.voiceListening,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Text(
            transcript.isEmpty ? l10n.voiceTapToSpeak : transcript,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: transcript.isEmpty ? 18 : 26,
              fontWeight:
                  transcript.isEmpty ? FontWeight.w400 : FontWeight.w700,
              height: 1.3,
              shadows: const [
                Shadow(color: Colors.black45, blurRadius: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultsCard extends StatelessWidget {
  final String transcript;
  final List<ServiceItem> matches;
  final AppLocalizations l10n;
  final VoidCallback onRetry;

  const _ResultsCard({
    required this.transcript,
    required this.matches,
    required this.l10n,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: const ValueKey('results'),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.voiceYouSaid}: "$transcript"',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.m),
          for (final service in matches.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: ListTile(
                onTap: () {
                  KayloFeedback.tap();
                  if (service.category == 'care') {
                    // Care has a real destination already.
                    context.go(Routes.careHome);
                    Navigator.of(context).pop();
                  } else {
                    // TODO(M3): open the service detail screen.
                    KayloSnackbar.showInfo(context, l10n.comingSoon);
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: BorderSide(
                    color: AppColors.brandPrimary.withValues(alpha: 0.25),
                  ),
                ),
                leading: service.iconPath.isEmpty
                    ? const Icon(Icons.handyman_rounded,
                        color: AppColors.brandPrimary)
                    : Image.asset(service.iconPath, width: 40, height: 40),
                title: Text(service.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
          Center(
            child: TextButton.icon(
              onPressed: () {
                KayloFeedback.tap();
                onRetry();
              },
              icon: const Icon(Icons.mic_rounded),
              label: Text(l10n.voiceTryAgain),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String transcript;
  final String message;
  final String retryLabel;
  final AppLocalizations l10n;
  final VoidCallback onRetry;

  const _MessageCard({
    super.key,
    required this.icon,
    required this.transcript,
    required this.message,
    required this.retryLabel,
    required this.l10n,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.m),
          if (transcript.isNotEmpty) ...[
            Text(
              '${l10n.voiceYouSaid}: "$transcript"',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.s),
          TextButton.icon(
            onPressed: () {
              KayloFeedback.tap();
              onRetry();
            },
            icon: const Icon(Icons.mic_rounded),
            label: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}
