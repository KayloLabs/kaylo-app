import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/service_item.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/kaylo_snackbar.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/home_providers.dart';
import '../../application/voice_search.dart';

/// Opens the voice search sheet, or shows the localized unavailable
/// notice when the device has no usable speech recogniser.
Future<void> showVoiceSearchSheet(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final speech = ref.read(speechServiceProvider);

  KayloFeedback.press();
  final available = await speech.init();
  if (!context.mounted) return;
  if (!available) {
    KayloSnackbar.showInfo(context, l10n.voiceUnavailable);
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const VoiceSearchSheet(),
  );
  speech.onError = null;
  speech.onStatus = null;
  await speech.cancel();
}

enum _VoicePhase { listening, matching, results, noMatch, micDenied }

class VoiceSearchSheet extends ConsumerStatefulWidget {
  const VoiceSearchSheet({super.key});

  @override
  ConsumerState<VoiceSearchSheet> createState() => _VoiceSearchSheetState();
}

class _VoiceSearchSheetState extends ConsumerState<VoiceSearchSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  _VoicePhase _phase = _VoicePhase.listening;
  String _transcript = '';
  List<ServiceItem> _matches = const [];
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    final speech = ref.read(speechServiceProvider);
    setState(() {
      _phase = _VoicePhase.listening;
      _transcript = '';
      _matches = const [];
      _finished = false;
    });

    speech.onError = (error, permanent) {
      if (!mounted || _finished) return;
      if (SpeechService.isPermissionError(error)) {
        setState(() => _phase = _VoicePhase.micDenied);
        _finished = true;
      } else if (_transcript.isNotEmpty) {
        _finish(_transcript);
      } else {
        // no_match / timeout / audio errors: offer a retry.
        setState(() => _phase = _VoicePhase.noMatch);
        _finished = true;
      }
    };
    speech.onStatus = (status) {
      // The engine stopped on its own (pause timeout, engine end):
      // settle with whatever it heard rather than hanging forever.
      if (!mounted || _finished) return;
      if ((status == 'notListening' || status == 'done') &&
          _phase == _VoicePhase.listening) {
        if (_transcript.isNotEmpty) {
          _finish(_transcript);
        } else if (status == 'done') {
          setState(() => _phase = _VoicePhase.noMatch);
          _finished = true;
        }
      }
    };

    final languageCode = Localizations.localeOf(context).languageCode;
    final localeId = await speech.localeFor(languageCode);
    await speech.listen(
      localeId: localeId,
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
    }
  }

  Future<void> _finish(String words) async {
    if (_finished) return;
    _finished = true;
    setState(() => _phase = _VoicePhase.matching);
    await ref.read(speechServiceProvider).stop();
    try {
      final pool = await ref.read(homeRepositoryProvider).getPopularServices();
      if (!mounted) return;
      final matches = matchServicesToTranscript(words, pool);
      setState(() {
        _matches = matches;
        _phase = matches.isEmpty ? _VoicePhase.noMatch : _VoicePhase.results;
      });
      if (matches.isNotEmpty) KayloFeedback.tap();
    } catch (_) {
      if (!mounted) return;
      setState(() => _phase = _VoicePhase.noMatch);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.l,
        right: AppSpacing.l,
        top: AppSpacing.m,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.voiceSearch,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            // Fixed-height stage: phases swap inside it, so the sheet
            // never resizes while the mic pulses or text streams in.
            SizedBox(
              height: 320,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: switch (_phase) {
                  _VoicePhase.listening => _ListeningView(
                      key: const ValueKey('listening'),
                      pulse: _pulse,
                      transcript: _transcript,
                      l10n: l10n,
                      onStop: _stopEarly,
                    ),
                  _VoicePhase.matching => const Center(
                      key: ValueKey('matching'),
                      child: CircularProgressIndicator(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  _VoicePhase.results => _ResultsView(
                      key: const ValueKey('results'),
                      transcript: _transcript,
                      matches: _matches,
                      l10n: l10n,
                    ),
                  _VoicePhase.noMatch => _RetryView(
                      key: const ValueKey('noMatch'),
                      icon: Icons.search_off_rounded,
                      transcript: _transcript,
                      message: l10n.voiceNoMatch,
                      retryLabel: l10n.voiceTryAgain,
                      l10n: l10n,
                      onRetry: _startListening,
                    ),
                  _VoicePhase.micDenied => _RetryView(
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
            ),
          ],
        ),
      ),
    );
  }
}

class _ListeningView extends StatelessWidget {
  final AnimationController pulse;
  final String transcript;
  final AppLocalizations l10n;
  final VoidCallback onStop;

  const _ListeningView({
    super.key,
    required this.pulse,
    required this.transcript,
    required this.l10n,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // The ripple stack lives in a fixed box; growing rings paint
        // inside it without ever changing layout.
        SizedBox(
          width: 180,
          height: 180,
          child: AnimatedBuilder(
            animation: pulse,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  for (final offset in const [0.0, 0.5])
                    _Ripple(t: (pulse.value + offset) % 1.0),
                  GestureDetector(
                    onTap: onStop,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        color: AppColors.brandPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic_rounded,
                          color: Colors.white, size: 40),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          l10n.voiceListening,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 44,
          child: Text(
            transcript.isEmpty ? l10n.voiceTapToSpeak : transcript,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}

class _Ripple extends StatelessWidget {
  final double t;

  const _Ripple({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84 + 90 * t,
      height: 84 + 90 * t,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.35 * (1 - t)),
          width: 2,
        ),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  final String transcript;
  final List<ServiceItem> matches;
  final AppLocalizations l10n;

  const _ResultsView({
    super.key,
    required this.transcript,
    required this.matches,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Expanded(
          child: ListView(
            children: [
              for (final service in matches.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s),
                  child: ListTile(
                    onTap: () {
                      KayloFeedback.tap();
                      // TODO(M3): open the service detail screen.
                      KayloSnackbar.showInfo(context, l10n.comingSoon);
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
            ],
          ),
        ),
      ],
    );
  }
}

class _RetryView extends StatelessWidget {
  final IconData icon;
  final String transcript;
  final String message;
  final String retryLabel;
  final AppLocalizations l10n;
  final VoidCallback onRetry;

  const _RetryView({
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: AppColors.textSecondary),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        TextButton.icon(
          onPressed: () {
            KayloFeedback.tap();
            onRetry();
          },
          icon: const Icon(Icons.mic_rounded),
          label: Text(retryLabel),
        ),
      ],
    );
  }
}
