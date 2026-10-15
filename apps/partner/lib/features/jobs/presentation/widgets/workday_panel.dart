import 'package:flutter/material.dart';
import 'package:kaylo_ui/theme/app_colors.dart';

/// A quiet, hand-drawn neighbourhood, shared by the day's overview and empty state.
class NeighbourhoodSketch extends StatelessWidget {
  final Color color;
  const NeighbourhoodSketch({super.key, required this.color});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(painter: _NeighbourhoodPainter(color)),
  );
}

class _NeighbourhoodPainter extends CustomPainter {
  final Color color;
  const _NeighbourhoodPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 110);
    final ink = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(
      const Offset(126, 24),
      12,
      Paint()..color = AppColors.secondaryAccent.withValues(alpha: .85),
    );
    final street = Path()
      ..moveTo(2, 100)
      ..quadraticBezierTo(70, 92, 158, 100);
    canvas.drawPath(street, ink);
    final house = Path()
      ..moveTo(27, 94)
      ..lineTo(27, 49)
      ..lineTo(16, 49)
      ..lineTo(60, 15)
      ..lineTo(104, 49)
      ..lineTo(93, 49)
      ..lineTo(93, 94)
      ..moveTo(24, 43)
      ..lineTo(60, 16)
      ..lineTo(97, 43)
      ..moveTo(52, 94)
      ..lineTo(52, 68)
      ..quadraticBezierTo(60, 59, 68, 68)
      ..lineTo(68, 94);
    canvas.drawPath(house, ink);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(36, 54, 12, 15),
        const Radius.circular(2),
      ),
      ink,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(74, 54, 12, 15),
        const Radius.circular(2),
      ),
      ink,
    );
    canvas.drawLine(const Offset(128, 96), const Offset(128, 57), ink);
    canvas.drawPath(
      Path()
        ..moveTo(128, 81)
        ..quadraticBezierTo(108, 75, 110, 59)
        ..quadraticBezierTo(128, 60, 128, 81),
      ink,
    );
    canvas.drawPath(
      Path()
        ..moveTo(128, 72)
        ..quadraticBezierTo(145, 69, 146, 51)
        ..quadraticBezierTo(129, 51, 128, 72),
      ink,
    );
    canvas.drawLine(const Offset(9, 98), const Offset(9, 84), ink);
    canvas.drawLine(const Offset(3, 87), const Offset(15, 87), ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NeighbourhoodPainter oldDelegate) =>
      color != oldDelegate.color;
}

class WorkdayPanel extends StatelessWidget {
  final String earningsLabel, earnings, jobsLabel, jobs, ratingLabel, rating;
  final String dutyLabel, dutyDescription;
  final bool online, updating;
  final ValueChanged<bool> onDutyChanged;
  final VoidCallback onEarnings, onReviews;

  const WorkdayPanel({
    super.key,
    required this.earningsLabel,
    required this.earnings,
    required this.jobsLabel,
    required this.jobs,
    required this.ratingLabel,
    required this.rating,
    required this.dutyLabel,
    required this.dutyDescription,
    required this.online,
    required this.updating,
    required this.onDutyChanged,
    required this.onEarnings,
    required this.onReviews,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: reduced ? Duration.zero : const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: online ? AppColors.brandPrimaryDark : const Color(0xFF354B41),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? .12 : 0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _Metric(
                    label: earningsLabel,
                    value: earnings,
                    prominent: true,
                    onTap: onEarnings,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 85,
                    child: NeighbourhoodSketch(color: Color(0xFFB9D0B6)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Metric(label: jobsLabel, value: jobs),
                ),
                Container(
                  width: 1,
                  height: 42,
                  color: Colors.white.withValues(alpha: .18),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: _Metric(
                    label: ratingLabel,
                    value: rating,
                    onTap: onReviews,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(height: 1, color: Colors.white.withValues(alpha: .18)),
            const SizedBox(height: 10),
            Row(
              children: [
                AnimatedContainer(
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 400),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: online
                        ? const Color(0xFFB9D995)
                        : const Color(0xFFBAC4BD),
                    boxShadow: online
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFFB9D995,
                              ).withValues(alpha: .18),
                              spreadRadius: 4,
                            ),
                          ]
                        : [],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dutyLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dutyDescription,
                        style: const TextStyle(
                          color: Color(0xFFD3DED3),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Semantics(
                  label: dutyLabel,
                  child: Switch.adaptive(
                    value: online,
                    onChanged: updating ? null : onDutyChanged,
                    activeTrackColor: const Color(0xFFB9D995),
                    activeThumbColor: AppColors.brandPrimaryDark,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFF617469),
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

class _Metric extends StatelessWidget {
  final String label, value;
  final bool prominent;
  final VoidCallback? onTap;
  const _Metric({
    required this.label,
    required this.value,
    this.prominent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFD3DED3),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 5),
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 250),
          child: Text(
            value,
            key: ValueKey(value),
            style: TextStyle(
              color: Colors.white,
              fontSize: prominent ? 34 : 22,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: prominent ? -1 : -.4,
            ),
          ),
        ),
      ],
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: content,
        ),
      ),
    );
  }
}

class WorkdayShortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const WorkdayShortcut({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = dark ? const Color(0xFFB9D0B6) : AppColors.brandPrimaryDark;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 23),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
