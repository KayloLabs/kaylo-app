import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_core/services/sound_service.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_core/utils/money.dart';
import 'package:kaylo_ui/theme/app_colors.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/kaylo_offer.dart';
import 'offer_motion.dart';
import 'offer_ticket.dart';

const _green = AppColors.brandPrimary;

/// The coin's short run across the lower part of the card, and how many
/// points of it are drawn as a scratch.
const _coinSteps = 14;
Offset _coinAt(Size size, double t) => Offset(
  size.width * (.30 + .40 * t),
  // Low on the card, clear of the words printed on the foil.
  size.height * (.87 - .04 * math.sin(t * math.pi)),
);

/// A reward ticket under a layer of foil. Scratching wears the foil away
/// where the finger goes and sheds flakes; once about half is gone the
/// rest falls off and the ticket is shown. The reveal is only a flourish:
/// the database decides whether the reward can be used.
class ScratchReward extends ConsumerStatefulWidget {
  final KayloOffer offer;
  final String userId;
  final double? subtotal;
  final String? category;
  final VoidCallback onApply;
  final Animation<double>? stamp;
  const ScratchReward({
    super.key,
    required this.offer,
    required this.userId,
    this.subtotal,
    this.category,
    required this.onApply,
    this.stamp,
  });
  @override
  ConsumerState<ScratchReward> createState() => _ScratchRewardState();
}

class _ScratchRewardState extends ConsumerState<ScratchReward>
    with TickerProviderStateMixin {
  static const _columns = 12;
  static const _rows = 8;
  static const _brush = 22.0;

  /// Share of the card that must be scratched before the rest gives way:
  /// about four good strokes across it.
  static const _enough = .42;

  final _strokes = <List<Offset>>[];
  final _cells = <int>{};
  final _flakes = _Flakes();
  final _random = math.Random(11);
  late final AnimationController _reveal;
  late final _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );
  // A coin makes one short scratch by itself, to show what the foil is for.
  late final _hint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  // The words printed on the foil step back once scratching starts, so
  // they do not tangle with the ticket showing through.
  late final _words = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );
  late final Ticker _ticker = createTicker(_fall);
  Duration _lastTick = Duration.zero;
  Offset? _light;
  Size _size = Size.zero;
  bool _opened = false;
  bool _hinted = false;
  String get _pref => 'offer_revealed_${widget.userId}_${widget.offer.code}';

  @override
  void initState() {
    super.initState();
    _opened = ref.read(sharedPreferencesProvider).getBool(_pref) ?? false;
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: _opened ? 1 : 0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hinted) return;
    _hinted = true;
    if (!_opened && !MediaQuery.disableAnimationsOf(context)) {
      // The coin's scratch is real: it stays on the foil afterwards.
      _hint.forward().whenComplete(() {
        if (!mounted || _opened || _strokes.isNotEmpty || _size.isEmpty) {
          return;
        }
        if (_hint.status != AnimationStatus.completed) return;
        setState(
          () => _strokes.add([
            for (var i = 0; i <= _coinSteps; i++)
              _coinAt(_size, i / _coinSteps),
          ]),
        );
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _reveal.dispose();
    _burst.dispose();
    _hint.dispose();
    _words.dispose();
    _flakes.dispose();
    super.dispose();
  }

  void _fall(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    _flakes.step(dt.clamp(0, .05));
    if (_flakes.isEmpty) {
      _ticker.stop();
      _lastTick = Duration.zero;
    }
  }

  void _shed(Offset at, Offset push, {int count = 1}) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    for (var i = 0; i < count; i++) {
      _flakes.add(
        at + Offset(_random.nextDouble() - .5, _random.nextDouble() - .5) * 16,
        // Carried a little by the finger, then left to gravity.
        push * (.5 + _random.nextDouble()) +
            Offset(
              (_random.nextDouble() - .5) * 110,
              -40 - _random.nextDouble() * 90,
            ),
        _random,
      );
    }
    if (!_ticker.isActive) _ticker.start();
  }

  void _open() {
    if (_opened) return;
    setState(() => _opened = true);
    KayloFeedback.success();
    ref.read(soundServiceProvider).play(KayloSound.reveal);
    ref.read(sharedPreferencesProvider).setBool(_pref, true);
    _hint.stop();
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = 1;
      return;
    }
    // What is left of the foil comes away in pieces instead of fading.
    if (!_size.isEmpty) {
      for (var i = 0; i < 46; i++) {
        final at = Offset(
          _random.nextDouble() * _size.width,
          _random.nextDouble() * _size.height,
        );
        _shed(at, (at - _size.center(Offset.zero)) * 1.6);
      }
    }
    _reveal.forward();
    _burst.forward(from: 0);
  }

  void _begin(Offset point) {
    _hint.stop();
    if (MediaQuery.disableAnimationsOf(context)) {
      _words.value = 0;
    } else {
      _words.reverse();
    }
    _strokes.add([]);
    _scratch(point, Offset.zero);
  }

  void _continue(Offset point) {
    final stroke = _strokes.lastOrNull;
    final from = stroke == null || stroke.isEmpty ? point : stroke.last;
    _scratch(point, point - from);
  }

  void _scratch(Offset point, Offset delta) {
    if (_opened || _strokes.isEmpty || _size.isEmpty) return;
    setState(() {
      _strokes.last.add(point);
      _light = point;
      // A quick swipe reports points far apart; walk the path between
      // them so progress matches the line the eye sees being cleared.
      final steps = (delta.distance / 10).ceil().clamp(1, 60);
      for (var step = 1; step <= steps; step++) {
        _wear(point - delta * (1 - step / steps));
      }
    });
    if (delta.distance > 1.5) {
      // However far the finger jumped, a flake only gets a flick.
      final flick = Offset.fromDirection(
        delta.direction,
        math.min(delta.distance, 14),
      );
      _shed(point, flick * 14, count: delta.distance > 30 ? 3 : 1);
    }
    KayloFeedback.selection();
    if (_cells.length >= _columns * _rows * _enough) _open();
  }

  /// Marks every cell the brush touches at [at], not just the one under
  /// its centre.
  void _wear(Offset at) {
    final cellWidth = _size.width / _columns;
    final cellHeight = _size.height / _rows;
    for (var row = 0; row < _rows; row++) {
      for (var column = 0; column < _columns; column++) {
        final centre = Offset(
          (column + .5) * cellWidth,
          (row + .5) * cellHeight,
        );
        if ((centre - at).distance <= _brush + 6) {
          _cells.add(row * _columns + column);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_reveal, _burst, _hint, _words]),
          builder: (context, _) {
            // The foil is gone in the first half; the ticket then settles.
            final cover =
                1 -
                const Interval(
                  0,
                  .45,
                  curve: Curves.easeOut,
                ).transform(_reveal.value);
            return Transform.scale(
              scale: 1 + math.sin(_reveal.value * math.pi) * .035,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ExcludeSemantics(
                    excluding: !_opened,
                    child: IgnorePointer(
                      ignoring: !_opened,
                      child: OfferTicket(
                        offer: widget.offer,
                        subtotal: widget.subtotal,
                        category: widget.category,
                        onApply: widget.onApply,
                        stamp: widget.stamp,
                      ),
                    ),
                  ),
                  if (cover > 0)
                    Positioned.fill(
                      child: Opacity(
                        opacity: cover,
                        child: LayoutBuilder(
                          builder: (context, bounds) {
                            _size = Size(bounds.maxWidth, bounds.maxHeight);
                            return Semantics(
                              label: l10n.scratchSemantics(
                                formatRupees(widget.offer.discount),
                              ),
                              button: true,
                              onTap: _open,
                              // Both drag directions are claimed here, so a
                              // downward scratch wears the foil instead of
                              // scrolling the list behind the card.
                              child: GestureDetector(
                                onVerticalDragStart: (d) =>
                                    _begin(d.localPosition),
                                onVerticalDragUpdate: (d) =>
                                    _continue(d.localPosition),
                                onHorizontalDragStart: (d) =>
                                    _begin(d.localPosition),
                                onHorizontalDragUpdate: (d) =>
                                    _continue(d.localPosition),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: CustomPaint(
                                    painter: _Foil(
                                      strokes: _strokes,
                                      light: _light,
                                      hint: _hint.isAnimating || _hint.value < 1
                                          ? _hint.value
                                          : 0,
                                      wording: _words.value,
                                      title: l10n.scratchCoverTitle,
                                      body: l10n.scratchCoverHint,
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _FlakePainter(_flakes)),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: PaperBurstPainter(
                          t: _burst.value,
                          origin: const Alignment(0, -.2),
                          seed: widget.offer.code.hashCode,
                          pieces: 34,
                          reach: 1.25,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (!_opened)
          TextButton(onPressed: _open, child: Text(l10n.revealReward)),
      ],
    );
  }
}

/// The foil: a brushed metal sheet that catches the light where the
/// finger last was, with the scratched paths cut out of it.
class _Foil extends CustomPainter {
  final List<List<Offset>> strokes;
  final Offset? light;
  final double hint;
  final double wording;
  final String title;
  final String body;
  _Foil({
    required this.strokes,
    required this.light,
    required this.hint,
    required this.wording,
    required this.title,
    required this.body,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    canvas.saveLayer(area, Paint());
    canvas.drawRect(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffd7ddbb), Color(0xffeef0d9), Color(0xffbbcba9)],
        ).createShader(area),
    );
    // Brushing: fine lines along the sheet, as rolled foil has.
    final grain = Paint()..strokeWidth = 1;
    for (double y = 1; y < size.height; y += 3) {
      grain.color = (y % 6 < 3 ? Colors.white : Colors.black).withValues(
        alpha: .045,
      );
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grain);
    }
    final motif = Paint()
      ..color = _green.withValues(alpha: .13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width; x += 22) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        motif,
      );
    }
    // The highlight sits where the finger pressed last, like a lamp
    // reflected in metal that follows the hand.
    final lamp = light ?? Offset(size.width * .3, size.height * .25);
    canvas.drawRect(
      area,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: .42), Colors.transparent],
        ).createShader(Rect.fromCircle(center: lamp, radius: size.width * .55)),
    );
    final text = TextPainter(
      text: TextSpan(
        text: '$title\n\n$body',
        style: TextStyle(
          color: _green.withValues(alpha: wording),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width - 48);
    text.paint(
      canvas,
      Offset((size.width - text.width) / 2, (size.height - text.height) / 2),
    );

    final wipe = Paint()..blendMode = BlendMode.clear;
    void scratchAlong(List<Offset> points) {
      for (var i = 0; i < points.length; i++) {
        // An uneven edge: a fingernail does not cut a clean line.
        final ragged = 19 + (i * 37 % 11) * .7;
        canvas.drawCircle(points[i], ragged, wipe);
        if (i > 0) {
          canvas.drawLine(
            points[i - 1],
            points[i],
            Paint()
              ..blendMode = BlendMode.clear
              ..strokeWidth = 38
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }

    strokes.forEach(scratchAlong);
    final travelled = Curves.easeInOut.transform(
      const Interval(.15, .8).transform(hint),
    );
    if (hint > 0 && hint < 1 && strokes.isEmpty) {
      scratchAlong([
        for (var i = 0; i <= _coinSteps * travelled; i++)
          _coinAt(size, i / _coinSteps),
      ]);
    }
    canvas.restore();

    if (hint > 0 && hint < 1 && strokes.isEmpty) {
      final shown =
          const Interval(0, .15).transform(hint) *
          (1 - const Interval(.8, 1).transform(hint));
      final at = _coinAt(size, travelled);
      canvas.drawCircle(
        at + const Offset(0, 3),
        17,
        Paint()
          ..color = Colors.black.withValues(alpha: .18 * shown)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(
        at,
        16,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.4, -.5),
            colors: [
              const Color(0xfff6e2a6).withValues(alpha: shown),
              const Color(0xffc99a3c).withValues(alpha: shown),
            ],
          ).createShader(Rect.fromCircle(center: at, radius: 16)),
      );
      canvas.drawCircle(
        at,
        11,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xff9a7424).withValues(alpha: .7 * shown),
      );
    }
  }

  @override
  bool shouldRepaint(_Foil oldDelegate) => true;
}

/// Flakes of foil in flight. A plain list stepped by a ticker; it repaints
/// its painter directly so the card is not rebuilt on every frame.
class _Flakes extends ChangeNotifier {
  final _list = <_Flake>[];
  bool get isEmpty => _list.isEmpty;
  Iterable<_Flake> get all => _list;

  void add(Offset at, Offset velocity, math.Random random) {
    if (_list.length > 160) return;
    _list.add(
      _Flake(
        at,
        velocity,
        size: 3 + random.nextDouble() * 5,
        turn: random.nextDouble() * math.pi,
        spin: (random.nextDouble() - .5) * 14,
        shade: random.nextInt(_Flake.shades.length),
        span: .55 + random.nextDouble() * .4,
      ),
    );
  }

  void step(double dt) {
    for (final flake in _list) {
      flake.velocity += Offset(0, 900 * dt);
      flake.at += flake.velocity * dt;
      flake.turn += flake.spin * dt;
      flake.age += dt;
    }
    _list.removeWhere((flake) => flake.age >= flake.span);
    notifyListeners();
  }
}

class _Flake {
  static const shades = [
    Color(0xffc9d1a8),
    Color(0xffe8ebcf),
    Color(0xffaebd98),
  ];
  Offset at;
  Offset velocity;
  double turn;
  double age = 0;
  final double size;
  final double spin;
  final int shade;
  final double span;
  _Flake(
    this.at,
    this.velocity, {
    required this.size,
    required this.turn,
    required this.spin,
    required this.shade,
    required this.span,
  });
}

class _FlakePainter extends CustomPainter {
  final _Flakes flakes;
  _FlakePainter(this.flakes) : super(repaint: flakes);
  @override
  void paint(Canvas canvas, Size size) {
    for (final flake in flakes.all) {
      final left = 1 - flake.age / flake.span;
      canvas
        ..save()
        ..translate(flake.at.dx, flake.at.dy)
        ..rotate(flake.turn)
        ..drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: flake.size,
            height: flake.size * .55,
          ),
          Paint()
            ..color = _Flake.shades[flake.shade].withValues(
              alpha: left.clamp(0, 1),
            ),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_FlakePainter oldDelegate) => false;
}
