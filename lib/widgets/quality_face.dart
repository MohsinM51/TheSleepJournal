import 'package:flutter/material.dart';
import 'package:sleeptrack/theme/app_theme.dart';

/// A round face whose mouth smoothly morphs from a frown (quality 1) to a grin
/// (quality 5), and whose background warms from neutral to sage with quality.
/// Animates whenever the value changes (e.g. toggling Week/30-day).
class QualityFace extends StatelessWidget {
  final double quality; // 1..5, may be fractional
  final double size;
  const QualityFace({super.key, required this.quality, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quality, end: quality),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      builder: (context, q, _) {
        // Outline-only face drawn in the muted score colour (clay red -> green).
        return CustomPaint(size: Size.square(size), painter: _FacePainter(q, p.bandForScore(q)));
      },
    );
  }
}

class _FacePainter extends CustomPainter {
  final double quality;
  final Color color;
  _FacePainter(this.quality, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final lineW = size.width * 0.05;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineW
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color;

    // outline circle (inset by half the stroke so it isn't clipped)
    canvas.drawCircle(c, size.width / 2 - lineW / 2, stroke);

    // eyes
    final eyeR = size.width * 0.045;
    final eyeY = c.dy - size.height * 0.10;
    final eyeDx = size.width * 0.19;
    canvas.drawCircle(Offset(c.dx - eyeDx, eyeY), eyeR, fill);
    canvas.drawCircle(Offset(c.dx + eyeDx, eyeY), eyeR, fill);

    // mouth: smile amount in -1..1
    final smile = ((quality - 3) / 2).clamp(-1.0, 1.0);
    final mouthY = c.dy + size.height * 0.12;
    final halfW = size.width * 0.2;
    final amp = size.height * 0.20 * smile;
    final path = Path()
      ..moveTo(c.dx - halfW, mouthY - (smile < 0 ? amp : 0))
      ..quadraticBezierTo(c.dx, mouthY + amp * 1.6, c.dx + halfW, mouthY - (smile < 0 ? amp : 0));
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_FacePainter old) => old.quality != quality || old.color != color;
}
