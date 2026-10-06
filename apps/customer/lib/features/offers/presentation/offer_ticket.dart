import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kaylo_core/utils/money.dart';
import 'package:kaylo_ui/theme/app_colors.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/kaylo_offer.dart';
import 'offer_copy.dart';

const _green = AppColors.brandPrimary;

/// One offer as a paper ticket: the saving, what it is for, and a stub
/// with the code below a perforation. When [stamp] runs, an "applied"
/// stamp lands on it.
class OfferTicket extends StatelessWidget {
  final KayloOffer offer;
  final double? subtotal;
  final String? category;
  final VoidCallback onApply;
  final Animation<double>? stamp;
  const OfferTicket({
    super.key,
    required this.offer,
    this.subtotal,
    this.category,
    required this.onApply,
    this.stamp,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reason = offer.reasonIn(l10n, subtotal, category: category);
    final available = reason == null;
    final ink = dark ? const Color(0xffd0e6b9) : _green;
    final kind = offer.categoryIn(l10n);
    final still = MediaQuery.disableAnimationsOf(context);
    return ClipPath(
      clipper: const _TicketClipper(),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: dark ? const Color(0xff25392e) : const Color(0xffe9eee4),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A ticket that cannot be used yet reads as set aside.
                Opacity(
                  opacity: offer.eligible ? 1 : .6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            // The amount counts up once as the ticket arrives.
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: offer.eligible && !still
                                    ? 0.0
                                    : offer.discount,
                                end: offer.discount,
                              ),
                              duration: const Duration(milliseconds: 650),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) => Text(
                                l10n.offerAmountOff(
                                  formatRupees(value.roundToDouble()),
                                ),
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                  color: ink,
                                ),
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
                        offer.titleIn(l10n),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        offer.descriptionIn(l10n),
                        style: const TextStyle(height: 1.5, fontSize: 13),
                      ),
                      if (kind != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            kind,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: _Perforation(
                      Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
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
                      FilledButton(
                        onPressed: onApply,
                        child: Text(l10n.applyOffer),
                      )
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
                if (reason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (stamp != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: stamp!,
                  builder: (context, _) =>
                      _Stamp(t: stamp!.value, label: l10n.offerStampApplied),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A rubber stamp coming down: it starts large and loose, lands with a
/// small overshoot and stays, slightly askew, the way a hand leaves it.
class _Stamp extends StatelessWidget {
  final double t;
  final String label;
  const _Stamp({required this.t, required this.label});
  @override
  Widget build(BuildContext context) {
    if (t <= 0) return const SizedBox.shrink();
    final land = const Interval(0, .55, curve: Curves.easeOutBack).transform(t);
    final ink = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xffd0e6b9)
        : _green;
    return Align(
      alignment: const Alignment(.72, -.35),
      child: Opacity(
        opacity: const Interval(0, .25).transform(t),
        child: Transform.rotate(
          angle: -.24,
          child: Transform.scale(
            scale: 2.3 - 1.3 * land,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                border: Border.all(color: ink, width: 2.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: ink, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The tear line between the ticket and its stub.
class _Perforation extends CustomPainter {
  final Color color;
  const _Perforation(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (double x = 2; x < size.width; x += 9) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(math.min(x + 4, size.width), 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Perforation old) => old.color != color;
}

class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper();
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
