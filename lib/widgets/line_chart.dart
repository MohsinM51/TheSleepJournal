import 'package:flutter/material.dart';
import 'package:sleeptrack/theme/app_theme.dart';

/// A single line series expressed in chart units, with everything the painter
/// needs to draw its axes. Times are passed as "anchored hours" (20..36) so
/// the caller controls clock formatting via [yLabelFmt].
class LineSeries {
  final List<double?> values; // null = no data that day (a gap)
  final List<String> labels; // x label per point
  final double minY;
  final double maxY;
  final List<double> yTicks;
  final String Function(double) yLabelFmt;
  final double? bandLo; // shaded "healthy" band (in Y units) — e.g. 7..9 hrs
  final double? bandHi;
  final double? markerY; // thin dashed reference line (in Y units) — e.g. goal time
  final String? markerLabel;

  const LineSeries({
    required this.values,
    required this.labels,
    required this.minY,
    required this.maxY,
    required this.yTicks,
    required this.yLabelFmt,
    this.bandLo,
    this.bandHi,
    this.markerY,
    this.markerLabel,
  });

  bool get hasData => values.any((v) => v != null);
}

class AnimatedLineChart extends StatefulWidget {
  final LineSeries series;
  final Color lineColor;
  final bool fill;
  final Object revealKey; // change this to replay the draw-on animation
  final double height;

  const AnimatedLineChart({
    super.key,
    required this.series,
    required this.lineColor,
    required this.revealKey,
    this.fill = false,
    this.height = 156,
  });

  @override
  State<AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<AnimatedLineChart> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 820))..forward();
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void didUpdateWidget(AnimatedLineChart old) {
    super.didUpdateWidget(old);
    if (old.revealKey != widget.revealKey) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (!widget.series.hasData) {
      return SizedBox(
        height: widget.height,
        child: Center(child: Text('No data yet', style: AppText.label(p.textFaint))),
      );
    }
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => CustomPaint(
        size: Size(double.infinity, widget.height),
        painter: _LinePainter(
          series: widget.series,
          progress: _a.value,
          line: widget.lineColor,
          fill: widget.fill,
          axisColor: p.textFaint,
          gridColor: p.divider,
          dotFill: p.surface,
          bandColor: p.green,
          markerColor: p.green,
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final LineSeries series;
  final double progress;
  final Color line;
  final bool fill;
  final Color axisColor;
  final Color gridColor;
  final Color dotFill;
  final Color bandColor;
  final Color markerColor;

  _LinePainter({
    required this.series,
    required this.progress,
    required this.line,
    required this.fill,
    required this.axisColor,
    required this.gridColor,
    required this.dotFill,
    required this.bandColor,
    required this.markerColor,
  });

  static const double _padL = 34;
  static const double _padB = 22;
  static const double _padT = 10;
  static const double _padR = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(_padL, _padT, size.width - _padR, size.height - _padB);
    final span = (series.maxY - series.minY).abs() < 1e-6 ? 1.0 : series.maxY - series.minY;

    double yOf(double v) => plot.bottom - (v - series.minY) / span * plot.height;
    double xOf(int i) =>
        plot.left + (series.values.length == 1 ? 0.5 : i / (series.values.length - 1)) * plot.width;

    // healthy-range band (drawn behind the grid)
    if (series.bandLo != null && series.bandHi != null) {
      final top = yOf(series.bandHi!).clamp(plot.top, plot.bottom).toDouble();
      final bot = yOf(series.bandLo!).clamp(plot.top, plot.bottom).toDouble();
      canvas.drawRect(
          Rect.fromLTRB(plot.left, top, plot.right, bot), Paint()..color = bandColor.withValues(alpha: 0.13));
      final edge = Paint()
        ..color = bandColor.withValues(alpha: 0.30)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(plot.left, top), Offset(plot.right, top), edge);
      canvas.drawLine(Offset(plot.left, bot), Offset(plot.right, bot), edge);
    }

    // y ticks: faint label + hairline
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (final t in series.yTicks) {
      final y = yOf(t);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      _text(canvas, series.yLabelFmt(t), Offset(plot.left - 8, y), axisColor, alignRight: true);
    }

    // x labels (thin them out when crowded)
    final n = series.labels.length;
    final step = n <= 8 ? 1 : (n / 6).ceil();
    for (var i = 0; i < n; i++) {
      if (i % step != 0 && i != n - 1) continue;
      _text(canvas, series.labels[i], Offset(xOf(i), size.height - _padB + 6), axisColor,
          center: true);
    }

    // goal-line marker (full width, behind the data line)
    if (series.markerY != null) {
      final y = yOf(series.markerY!);
      if (y >= plot.top - 0.5 && y <= plot.bottom + 0.5) {
        _dashed(canvas, Offset(plot.left, y), Offset(plot.right, y),
            Paint()..color = markerColor..strokeWidth = 1.3, 5, 4);
        if (series.markerLabel != null) {
          _text(canvas, series.markerLabel!, Offset(plot.left + 3, y - 12), markerColor);
        }
      }
    }

    // reveal clip (left -> right draw-on)
    final revealX = plot.left + plot.width * progress;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, revealX + 0.5, size.height));

    // build contiguous runs (skip gaps)
    final runs = <List<Offset>>[];
    var run = <Offset>[];
    for (var i = 0; i < series.values.length; i++) {
      final v = series.values[i];
      if (v == null) {
        if (run.isNotEmpty) {
          runs.add(run);
          run = [];
        }
      } else {
        run.add(Offset(xOf(i), yOf(v)));
      }
    }
    if (run.isNotEmpty) runs.add(run);

    for (final pts in runs) {
      final path = _smooth(pts);
      if (fill) {
        final fillPath = Path.from(path)
          ..lineTo(pts.last.dx, plot.bottom)
          ..lineTo(pts.first.dx, plot.bottom)
          ..close();
        canvas.drawPath(
          fillPath,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [line.withValues(alpha: 0.26), line.withValues(alpha: 0.0)],
            ).createShader(Rect.fromLTRB(plot.left, plot.top, plot.right, plot.bottom)),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.restore();

    // dots for revealed points
    for (var i = 0; i < series.values.length; i++) {
      final v = series.values[i];
      if (v == null) continue;
      final c = Offset(xOf(i), yOf(v));
      if (c.dx > revealX + 0.5) continue;
      canvas.drawCircle(c, 3.4, Paint()..color = line);
      canvas.drawCircle(c, 1.5, Paint()..color = dotFill);
    }
  }

  Path _smooth(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 1) return path;
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[i] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      final c1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final c2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  void _text(Canvas canvas, String s, Offset at, Color color,
      {bool center = false, bool alignRight = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w400, letterSpacing: 0.2)),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = at.dx;
    if (center) dx -= tp.width / 2;
    if (alignRight) dx -= tp.width;
    var dy = at.dy;
    if (alignRight) dy -= tp.height / 2; // vertically center y-axis labels
    tp.paint(canvas, Offset(dx, dy));
  }

  void _dashed(Canvas c, Offset a, Offset b, Paint paint, double dash, double gap) {
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final end = (d + dash).clamp(0.0, total);
      c.drawLine(a + dir * d, a + dir * end, paint);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.progress != progress ||
      old.line != line ||
      old.series != series ||
      old.gridColor != gridColor ||
      old.bandColor != bandColor ||
      old.markerColor != markerColor;
}
