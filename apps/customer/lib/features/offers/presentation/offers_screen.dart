import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_core/utils/money.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import '../../auth/application/current_user_provider.dart';
import '../application/offers_providers.dart';
import '../domain/kaylo_offer.dart';

const _green = AppColors.brandPrimary;

Future<KayloOffer?> showKayloOffers(BuildContext context, {double? subtotal}) =>
    Navigator.of(context).push<KayloOffer>(
      MaterialPageRoute(builder: (_) => OffersScreen(subtotal: subtotal)),
    );

class OffersBanner extends ConsumerWidget {
  const OffersBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final first = ref
        .watch(offersProvider)
        .whenOrNull(
          data: (offers) => offers
              .where((o) => o.code == 'FIRST100' && o.eligible)
              .firstOrNull,
        );
    return Semantics(
      button: true,
      child: Material(
        color: _green,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            KayloFeedback.press();
            showKayloOffers(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                const _RewardMark(size: 60),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        first != null
                            ? 'A warm welcome. ₹100 on us.'
                            : 'Good work. A little extra joy.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        first != null
                            ? 'Your first-booking offer is unlocked'
                            : 'Explore your offers & scratch rewards',
                        style: const TextStyle(
                          color: Color(0xffd9e8df),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single checkout control shared by Home, Farm and Care.
class OfferSelector extends ConsumerWidget {
  final double subtotal;
  final KayloOffer? selected;
  final ValueChanged<KayloOffer?> onChanged;
  final bool enabled;
  const OfferSelector({
    super.key,
    required this.subtotal,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valid = selected?.appliesTo(subtotal) ?? false;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 280);
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: valid ? .10 : .04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _green.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                valid ? Icons.check_circle_rounded : Icons.local_offer_outlined,
                color: _green,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: duration,
                  child: Text(
                    valid
                        ? 'You save ${formatRupees(selected!.discount)}'
                        : 'Offers & rewards',
                    key: ValueKey(valid ? selected!.code : 'none'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: !enabled
                    ? null
                    : () async {
                        final offer = await showKayloOffers(
                          context,
                          subtotal: subtotal,
                        );
                        if (offer != null && context.mounted) {
                          KayloFeedback.success();
                          onChanged(offer);
                        }
                      },
                child: Text(valid ? 'Change' : 'Apply'),
              ),
            ],
          ),
          if (selected != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    valid
                        ? '${selected!.code} applied'
                        : selected!.reasonFor(subtotal) ??
                              'Offer not available',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: enabled ? () => onChanged(null) : null,
                  child: const Text('Remove'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class OffersScreen extends ConsumerStatefulWidget {
  final double? subtotal;
  const OffersScreen({super.key, this.subtotal});
  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen> {
  final _code = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _apply(KayloOffer offer) {
    if (widget.subtotal == null) return;
    if (!offer.appliesTo(widget.subtotal!)) {
      setState(
        () =>
            _error = offer.reasonFor(widget.subtotal!) ?? 'Offer not available',
      );
      return;
    }
    Navigator.pop(context, offer);
  }

  @override
  Widget build(BuildContext context) {
    final offers = ref.watch(offersProvider);
    final user = ref.watch(currentUserIdProvider) ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('A little more Kaylo')),
      body: offers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_offer_outlined, size: 40, color: _green),
                const SizedBox(height: 16),
                const Text('Your offers couldn’t load. Please try again.'),
                TextButton(
                  onPressed: () => ref.invalidate(offersProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          children: [
            Text(
              'Everyday help.\nA little extra happiness.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -.8,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Thoughtful savings for the jobs that matter. One offer per booking.',
              style: TextStyle(height: 1.5),
            ),
            if (widget.subtotal != null) ...[
              const SizedBox(height: 24),
              TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter coupon code',
                  errorText: _error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  suffixIcon: TextButton(
                    onPressed: () {
                      final match = items
                          .where(
                            (o) => o.code == _code.text.trim().toUpperCase(),
                          )
                          .firstOrNull;
                      if (match == null) {
                        setState(() => _error = 'That code isn’t available');
                        return;
                      }
                      _apply(match);
                    },
                    child: const Text('Apply'),
                  ),
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
            ],
            const SizedBox(height: 28),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: item.scratch && item.eligible
                    ? ScratchReward(
                        key: ValueKey('$user:${item.code}'),
                        offer: item,
                        userId: user,
                        subtotal: widget.subtotal,
                        onApply: () => _apply(item),
                      )
                    : _OfferTicket(
                        offer: item,
                        subtotal: widget.subtotal,
                        onApply: () => _apply(item),
                      ),
              ),
            const SizedBox(height: 10),
            const Text(
              'Discounts reduce your booking total. They cannot be exchanged for cash or combined. '
              'Cancelled bookings release their offer. Eligibility is checked again at checkout.',
              style: TextStyle(fontSize: 12, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferTicket extends StatelessWidget {
  final KayloOffer offer;
  final double? subtotal;
  final VoidCallback onApply;
  const _OfferTicket({
    required this.offer,
    this.subtotal,
    required this.onApply,
  });
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final available =
        offer.eligible && (subtotal == null || offer.appliesTo(subtotal!));
    return ClipPath(
      clipper: _TicketClipper(),
      child: Container(
        decoration: BoxDecoration(
          color: dark ? const Color(0xff25392e) : const Color(0xffe9eee4),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${formatRupees(offer.discount)} off',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      color: dark ? const Color(0xffd0e6b9) : _green,
                    ),
                  ),
                ),
                Icon(
                  offer.scratch
                      ? Icons.redeem_rounded
                      : Icons.local_offer_outlined,
                  color: _green,
                  size: 30,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              offer.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              offer.description,
              style: const TextStyle(height: 1.5, fontSize: 13),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    offer.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
                if (subtotal != null && available)
                  FilledButton(onPressed: onApply, child: const Text('Apply'))
                else
                  Icon(
                    offer.eligible
                        ? Icons.check_circle_outline
                        : Icons.lock_outline_rounded,
                    size: 20,
                    color: _green,
                  ),
              ],
            ),
            if (!available)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  subtotal != null
                      ? offer.reasonFor(subtotal!) ?? ''
                      : offer.unavailableReason ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final shape = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      );
    final cuts = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, size.height * .7), radius: 8))
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width, size.height * .7),
          radius: 8,
        ),
      );
    return Path.combine(PathOperation.difference, shape, cuts);
  }

  @override
  bool shouldReclip(_TicketClipper oldClipper) => false;
}

class ScratchReward extends ConsumerStatefulWidget {
  final KayloOffer offer;
  final String userId;
  final double? subtotal;
  final VoidCallback onApply;
  const ScratchReward({
    super.key,
    required this.offer,
    required this.userId,
    this.subtotal,
    required this.onApply,
  });
  @override
  ConsumerState<ScratchReward> createState() => _ScratchRewardState();
}

class _ScratchRewardState extends ConsumerState<ScratchReward>
    with SingleTickerProviderStateMixin {
  final _strokes = <List<Offset>>[];
  final _cells = <int>{};
  late final AnimationController _reveal;
  bool _opened = false;
  String get _pref => 'offer_revealed_${widget.userId}_${widget.offer.code}';
  @override
  void initState() {
    super.initState();
    _opened = ref.read(sharedPreferencesProvider).getBool(_pref) ?? false;
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
      value: _opened ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _open() {
    if (_opened) return;
    setState(() => _opened = true);
    KayloFeedback.success();
    ref.read(sharedPreferencesProvider).setBool(_pref, true);
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
  }

  void _scratch(Offset point, Size size) {
    if (_opened || _strokes.isEmpty) return;
    setState(() {
      _strokes.last.add(point);
      final x = (point.dx / size.width * 12).floor().clamp(0, 11);
      final y = (point.dy / size.height * 8).floor().clamp(0, 7);
      _cells.add(y * 12 + x);
    });
    if (_cells.length >= 24) _open();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AnimatedBuilder(
        animation: _reveal,
        builder: (context, _) => Transform.scale(
          scale: 1 + math.sin(_reveal.value * math.pi) * .025,
          child: Stack(
            children: [
              ExcludeSemantics(
                excluding: !_opened,
                child: IgnorePointer(
                  ignoring: !_opened,
                  child: _OfferTicket(
                    offer: widget.offer,
                    subtotal: widget.subtotal,
                    onApply: widget.onApply,
                  ),
                ),
              ),
              if (_reveal.value < 1)
                Positioned.fill(
                  child: Opacity(
                    opacity: 1 - _reveal.value,
                    child: LayoutBuilder(
                      builder: (context, bounds) {
                        final size = Size(bounds.maxWidth, bounds.maxHeight);
                        return Semantics(
                          label:
                              'Scratch reward. Reveal ₹75 off your next booking.',
                          button: true,
                          onTap: _open,
                          child: GestureDetector(
                            onPanStart: (d) {
                              _strokes.add([]);
                              KayloFeedback.selection();
                              _scratch(d.localPosition, size);
                            },
                            onPanUpdate: (d) => _scratch(d.localPosition, size),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CustomPaint(
                                painter: _ScratchCover(_strokes),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      if (!_opened)
        TextButton(onPressed: _open, child: const Text('Reveal reward')),
    ],
  );
}

class _ScratchCover extends CustomPainter {
  final List<List<Offset>> strokes;
  _ScratchCover(this.strokes);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffd7ddbb), Color(0xffeef0d9), Color(0xffbbcba9)],
        ).createShader(Offset.zero & size),
    );
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
    final text = TextPainter(
      text: const TextSpan(
        text: 'A little thank you\n\nScratch to reveal your reward',
        style: TextStyle(
          color: _green,
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
    final eraser = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = 44
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          22,
          Paint()..blendMode = BlendMode.clear,
        );
      } else {
        canvas.drawPath(path, eraser);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScratchCover oldDelegate) => true;
}

class _RewardMark extends StatelessWidget {
  final double size;
  const _RewardMark({required this.size});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 750),
    curve: Curves.easeOutCubic,
    builder: (context, value, _) => Transform.rotate(
      angle: (1 - value) * -.4,
      child: Transform.scale(
        scale: .8 + .2 * value,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xffdce9b3),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.redeem_rounded, color: _green, size: size * .53),
        ),
      ),
    ),
  );
}
