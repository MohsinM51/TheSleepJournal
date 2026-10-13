import 'package:flutter/material.dart';
import 'package:sleeptrack/data/models.dart';
import 'package:sleeptrack/logic/time_utils.dart';
import 'package:sleeptrack/theme/app_theme.dart';

const double _winStart = kAxisStartHour * 60; // 1200 (8 PM)
const double _winEnd = kAxisEndHour * 60; // 2160 (12 PM next day)

bool _inAnchored(double a, int startMin, int endMin) {
  var s = anchoredMinutes(startMin).toDouble();
  var e = anchoredMinutes(endMin).toDouble();
  if (e <= s) e += kDayMinutes;
  if (a < s) a += kDayMinutes;
  return a >= s && a < e;
}

/// One night rendered as a stadium bar of coloured segments across the
/// 8 PM -> 12 PM window. green = slept in goal, red = awake in goal,
/// amber = slept outside goal, track = awake.
class AlignmentBar extends StatefulWidget {
  final SleepEntry? entry;
  final int goalSleepMin;
  final int goalWakeMin;
  final double height;
  final bool animate;
  const AlignmentBar({
    super.key,
    required this.entry,
    required this.goalSleepMin,
    required this.goalWakeMin,
    this.height = 14,
    this.animate = true,
  });

  @override
  State<AlignmentBar> createState() => _AlignmentBarState();
}

class _AlignmentBarState extends State<AlignmentBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: widget.animate ? 0 : 1,
  );
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => CustomPaint(
        size: Size(double.infinity, widget.height),
        painter: _AlignPainter(
          entry: widget.entry,
          goalSleepMin: widget.goalSleepMin,
          goalWakeMin: widget.goalWakeMin,
          progress: _a.value,
          green: p.green,
          red: p.red,
          amber: p.amber,
          track: p.brightness == Brightness.light ? const Color(0xFFFFFFFF) : const Color(0xFF111316),
          border: p.outline,
        ),
      ),
    );
  }
}

class _AlignPainter extends CustomPainter {
  final SleepEntry? entry;
  final int goalSleepMin;
  final int goalWakeMin;
  final double progress;
  final Color green, red, amber, track, border;

  _AlignPainter({
    required this.entry,
    required this.goalSleepMin,
    required this.goalWakeMin,
    required this.progress,
    required this.green,
    required this.red,
    required this.amber,
    required this.track,
    required this.border,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    canvas.drawRRect(rrect, Paint()..color = track);

    if (entry != null) {
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress + 0.5, size.height));
      const segs = 144;
      const span = _winEnd - _winStart;
      for (var i = 0; i < segs; i++) {
        final a = _winStart + (i + 0.5) / segs * span;
        final sleeping = _inAnchored(a, entry!.sleepMin, entry!.wakeMin);
        final goal = _inAnchored(a, goalSleepMin, goalWakeMin);
        Color? col;
        if (sleeping && goal) {
          col = green;
        } else if (!sleeping && goal) {
          col = red;
        } else if (sleeping && !goal) {
          col = amber;
        }
        if (col != null) {
          final x0 = i / segs * size.width;
          final x1 = (i + 1) / segs * size.width;
          canvas.drawRect(Rect.fromLTRB(x0, 0, x1 + 0.7, size.height), Paint()..color = col);
        }
      }
      canvas.restore();
    }

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.height <= 9 ? 1.0 : 1.5,
    );
  }

  @override
  bool shouldRepaint(_AlignPainter old) =>
      old.progress != progress ||
      old.entry != entry ||
      old.goalSleepMin != goalSleepMin ||
      old.goalWakeMin != goalWakeMin ||
      old.green != green;
}

/// The 8p..12p tick labels above a timeline, inset to align with the bars.
class AlignmentAxis extends StatelessWidget {
  final double labelWidth;
  const AlignmentAxis({super.key, this.labelWidth = 40});

  static const _ticks = ['8p', '10p', '12a', '2a', '4a', '6a', '8a', '10a', '12p'];

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(children: [
      SizedBox(width: labelWidth),
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [for (final t in _ticks) Text(t, style: AppText.axis(p.textFaint))],
        ),
      ),
    ]);
  }
}

/// Compact stack of recent nights for the home "Alignment" widget.
class MiniAlignment extends StatelessWidget {
  final List<SleepEntry?> nights;
  final int goalSleepMin;
  final int goalWakeMin;
  const MiniAlignment({
    super.key,
    required this.nights,
    required this.goalSleepMin,
    required this.goalWakeMin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < nights.length; i++) ...[
          AlignmentBar(
            entry: nights[i],
            goalSleepMin: goalSleepMin,
            goalWakeMin: goalWakeMin,
            height: 7,
          ),
          if (i != nights.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }
}
