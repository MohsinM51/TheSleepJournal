import 'package:flutter/material.dart';
import 'package:sleeptrack/data/models.dart';
import 'package:sleeptrack/logic/metrics.dart';
import 'package:sleeptrack/logic/time_utils.dart';
import 'package:sleeptrack/theme/app_theme.dart';
import 'package:sleeptrack/widgets/alignment_bar.dart';
import 'package:sleeptrack/widgets/common.dart';
import 'package:sleeptrack/widgets/line_chart.dart';
import 'package:sleeptrack/widgets/quality_face.dart';

/// The Average Sleep · Average Quality · Alignment trio.
class StatTrio extends StatelessWidget {
  final double? avgSleep;
  final double? avgScore;
  final double? alignment;
  final List<SleepEntry?> miniNights;
  final int goalSleepMin;
  final int goalWakeMin;

  const StatTrio({
    super.key,
    required this.avgSleep,
    required this.avgScore,
    required this.alignment,
    required this.miniNights,
    required this.goalSleepMin,
    required this.goalWakeMin,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _col(context, 'Average Sleep', [
                Text(avgSleep == null ? '—' : formatHrs(avgSleep!),
                    style: AppText.statNumber(p.textPrimary).copyWith(fontSize: 56)),
                const SizedBox(height: 2),
                Text('hrs', style: AppText.tiny(p.textSecondary)),
              ]),
            ),
            _divider(p),
            Expanded(
              child: _col(context, 'Sleep Health', [
                QualityFace(quality: avgScore ?? 3, size: 56),
                const SizedBox(height: 8),
                Text(avgScore == null ? '—' : scoreLabel(avgScore!),
                    style: AppText.label(p.textPrimary)),
              ]),
            ),
            _divider(p),
            Expanded(
              child: _col(context, 'Alignment', [
                Text(alignment == null ? '—' : '${alignment!.round()}%',
                    style: AppText.statNumber(p.textPrimary).copyWith(fontSize: 38)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: MiniAlignment(
                      nights: miniNights, goalSleepMin: goalSleepMin, goalWakeMin: goalWakeMin),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _col(BuildContext context, String label, List<Widget> children) {
    final p = context.pal;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(label, style: AppText.sectionLabel(p.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _divider(AppPalette p) =>
      Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 4), color: p.divider);
}

/// Average sleep + wake pills.
class AvgTimesCard extends StatelessWidget {
  final TimeOfDay? sleep;
  final TimeOfDay? wake;
  const AvgTimesCard({super.key, required this.sleep, required this.wake});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Average Sleep & Wake Up Times', style: AppText.cardTitle(p.textPrimary)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: _pill(context, bg: p.sleepBg, icon: Icons.bedtime_rounded, time: sleep),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _pill(context, bg: p.wakeBg, icon: Icons.wb_sunny_rounded, time: wake),
          ),
        ]),
      ]),
    );
  }

  Widget _pill(BuildContext context,
      {required Color bg, required IconData icon, required TimeOfDay? time}) {
    final p = context.pal;
    final parts = time == null ? null : clockParts(time);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.outline, width: 1.5)),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration:
              BoxDecoration(color: p.textPrimary.withValues(alpha: 0.06), shape: BoxShape.circle),
          child: Icon(icon, size: 17, color: p.textSecondary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(parts?.time ?? '—:—', style: AppText.pillTime(p.textPrimary)),
              const SizedBox(width: 5),
              if (parts != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(parts.period, style: AppText.pillPeriod(p.textSecondary)),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// A graph card with a two-way icon toggle; switching replays the draw-on
/// animation and cross-fades the title.
class ToggleGraphCard extends StatefulWidget {
  final String Function(int mode) titleFor;
  final List<IconData> toggles;
  final LineSeries Function(int mode) seriesFor;
  final Color Function(int mode) colorFor;
  final bool Function(int mode) fillFor;
  final Object baseRevealKey;
  const ToggleGraphCard({
    super.key,
    required this.titleFor,
    required this.toggles,
    required this.seriesFor,
    required this.colorFor,
    required this.fillFor,
    required this.baseRevealKey,
  });

  @override
  State<ToggleGraphCard> createState() => _ToggleGraphCardState();
}

class _ToggleGraphCardState extends State<ToggleGraphCard> {
  int _mode = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerLeft,
                children: [...previous, if (current != null) current],
              ),
              child: Text(widget.titleFor(_mode),
                  key: ValueKey(_mode), style: AppText.cardTitle(p.textPrimary)),
            ),
          ),
          const SizedBox(width: 12),
          CycleIconButton(
            icon: widget.toggles[_mode],
            onTap: () => setState(() => _mode = (_mode + 1) % widget.toggles.length),
          ),
        ]),
        const SizedBox(height: 18),
        AnimatedLineChart(
          series: widget.seriesFor(_mode),
          lineColor: widget.colorFor(_mode),
          fill: widget.fillFor(_mode),
          revealKey: (widget.baseRevealKey, _mode),
        ),
      ]),
    );
  }
}
