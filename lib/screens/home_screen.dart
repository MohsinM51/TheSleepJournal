import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sleeptrack/data/models.dart';
import 'package:sleeptrack/logic/date_utils.dart';
import 'package:sleeptrack/logic/metrics.dart';
import 'package:sleeptrack/logic/time_utils.dart';
import 'package:sleeptrack/state/app_state.dart';
import 'package:sleeptrack/theme/app_theme.dart';
import 'package:sleeptrack/widgets/anim.dart';
import 'package:sleeptrack/widgets/common.dart';
import 'package:sleeptrack/widgets/dashboard_cards.dart';
import 'package:sleeptrack/widgets/line_chart.dart';
import 'package:sleeptrack/widgets/segmented.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TimeOfDay _now = TimeOfDay.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      final t = TimeOfDay.now();
      if (t != _now && mounted) setState(() => _now = t);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final state = context.watch<AppState>();
    final s = state.settings;
    final period = state.period;
    final slots = state.windowSlots(period);
    final entries = slots.where((x) => x.entry != null).map((x) => x.entry!).toList();
    final labels = slots
        .map((x) => period == Period.week ? weekdayShort(x.date) : x.date.day.toString())
        .toList();
    final mini = (slots.length >= 3 ? slots.sublist(slots.length - 3) : slots)
        .map((x) => x.entry)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.screen, 8, Gap.screen, 120),
      children: [
        SafeArea(bottom: false, child: _utilityRow(context, state)),
        const SizedBox(height: 12),
        _header(context, s.name),
        const SizedBox(height: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 40),
          child: StatTrio(
            avgSleep: Metrics.avgDurationHours(entries),
            avgScore: state.avgSleepHealth(entries),
            alignment: Metrics.alignmentPercent(entries, s.goalSleepMin, s.goalWakeMin),
            miniNights: mini,
            goalSleepMin: s.goalSleepMin,
            goalWakeMin: s.goalWakeMin,
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 120),
          child: AvgTimesCard(
            sleep: Metrics.avgSleepTime(entries),
            wake: Metrics.avgWakeTime(entries),
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: ToggleGraphCard(
            baseRevealKey: period,
            toggles: const [Icons.snooze_rounded, Icons.monitor_heart_rounded],
            titleFor: (m) => m == 0 ? 'Sleep Duration' : 'Sleep Health',
            colorFor: (_) => p.accent,
            // duration: plain line over the healthy-range band (no line fill, which
            // clashed with the band); Sleep Health keeps its gradient fill.
            fillFor: (m) => m == 1,
            seriesFor: (m) => m == 0
                ? _durationSeries(slots, labels, state.sleepRange)
                : _healthSeries(slots, labels, state),
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 280),
          child: ToggleGraphCard(
            baseRevealKey: period,
            toggles: const [Icons.dark_mode_outlined, Icons.wb_sunny_outlined],
            titleFor: (m) => m == 0 ? 'Sleep Time' : 'Wake Up Time',
            colorFor: (_) => p.chartLine,
            fillFor: (_) => false,
            seriesFor: (m) => _timeSeries(slots, labels,
                wake: m == 1, goalSleepMin: s.goalSleepMin, goalWakeMin: s.goalWakeMin),
          ),
        ),
      ],
    );
  }

  Widget _utilityRow(BuildContext context, AppState state) {
    final p = context.pal;
    final isDark = p.brightness == Brightness.dark;
    return Row(children: [
      SizedBox(
        width: 168,
        child: Segmented(
          items: const [SegmentItem(label: 'Week'), SegmentItem(label: 'Month')],
          index: state.period.index,
          onChanged: (i) => state.setPeriod(Period.values[i]),
        ),
      ),
      const Spacer(),
      SoftIconButton(
        size: 42,
        onTap: state.toggleTheme,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (c, a) =>
              RotationTransition(turns: a, child: FadeTransition(opacity: a, child: c)),
          child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey(isDark), size: 19, color: p.textSecondary),
        ),
      ),
      const SizedBox(width: 10),
      SoftIconButton(
        size: 42,
        onTap: () => _openSettings(context, state),
        child: Icon(Icons.tune_rounded, size: 19, color: p.textSecondary),
      ),
    ]);
  }

  Widget _header(BuildContext context, String name) {
    final p = context.pal;
    final parts = clockParts(_now);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${greetingForHour(_now.hour)},', style: AppText.greeting(p.textSecondary)),
            Text(name.isEmpty ? 'Friend' : name, style: AppText.greeting(p.textPrimary)),
          ]),
        ),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.18), end: Offset.zero).animate(a),
                  child: c)),
          child: Row(
            key: ValueKey('${parts.time}${parts.period}'),
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(parts.time, style: AppText.clock(p.textPrimary)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(parts.period, style: AppText.clockPeriod(p.textSecondary)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- series builders ------------------------------------------------------
  LineSeries _durationSeries(List<DaySlot> slots, List<String> labels, ({int lo, int hi}) range) {
    final vals = slots.map((x) => x.entry?.durationHours).toList();
    final present = vals.whereType<double>().toList();
    // y-range always includes the healthy band so the shading stays visible
    final dataLo = present.isEmpty ? range.lo.toDouble() : present.reduce(min);
    final dataHi = present.isEmpty ? range.hi.toDouble() : present.reduce(max);
    final lo = (min(dataLo, range.lo.toDouble()).floorToDouble() - 1).clamp(0, 24).toDouble();
    final hi = max(dataHi, range.hi.toDouble()).ceilToDouble() + 1;
    return LineSeries(
      values: vals,
      labels: labels,
      minY: lo,
      maxY: hi,
      yTicks: niceIntTicks(lo, hi),
      yLabelFmt: (v) => v.toStringAsFixed(0),
      bandLo: range.lo.toDouble(),
      bandHi: range.hi.toDouble(),
    );
  }

  LineSeries _healthSeries(List<DaySlot> slots, List<String> labels, AppState state) {
    return LineSeries(
      values: slots.map((x) => x.entry == null ? null : state.sleepHealthFor(x.entry!)).toList(),
      labels: labels,
      minY: 1,
      maxY: 5,
      yTicks: const [1, 2, 3, 4, 5],
      yLabelFmt: (v) => v.toStringAsFixed(0),
    );
  }

  LineSeries _timeSeries(List<DaySlot> slots, List<String> labels,
      {required bool wake, required int goalSleepMin, required int goalWakeMin}) {
    final vals = slots
        .map((x) => x.entry == null
            ? null
            : anchoredMinutes(wake ? x.entry!.wakeMin : x.entry!.sleepMin) / 60.0)
        .toList();
    final markerY = anchoredMinutes(wake ? goalWakeMin : goalSleepMin) / 60.0;
    final present = [...vals.whereType<double>(), markerY];
    final lo = present.reduce(min).floorToDouble() - 1;
    final hi = present.reduce(max).ceilToDouble() + 1;
    return LineSeries(
      values: vals,
      labels: labels,
      minY: lo,
      maxY: hi,
      yTicks: niceIntTicks(lo, hi),
      yLabelFmt: clockLabelAnchored,
      markerY: markerY,
      markerLabel: 'Goal ${clockLabelAnchored(markerY)}',
    );
  }

  void _openSettings(BuildContext context, AppState state) {
    final nameController = TextEditingController(text: state.settings.name);
    final yearController =
        TextEditingController(text: state.settings.birthYear?.toString() ?? '');
    int? localYear = state.settings.birthYear;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheet) {
        final p = ctx.pal;
        return Padding(
          // viewInsets from the sheet's own context so it lifts above the keyboard
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
                color: p.bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(color: p.outline, width: 1.5)),
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
            child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration:
                            BoxDecoration(color: p.divider, borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Settings', style: AppText.cardTitle(p.textPrimary)),
                    const SizedBox(height: 18),
                    Text('Your name', style: AppText.sectionLabel(p.textSecondary)),
                    const SizedBox(height: 8),
                    _settingsField(p, controller: nameController, onSubmitted: state.setName),
                    const SizedBox(height: 18),
                    Text('Year of birth', style: AppText.sectionLabel(p.textSecondary)),
                    const SizedBox(height: 8),
                    _settingsField(
                      p,
                      controller: yearController,
                      number: true,
                      onChanged: (v) {
                        final now = DateTime.now().year;
                        final y = int.tryParse(v.trim());
                        setSheet(() => localYear = (y != null && y >= 1900 && y <= now) ? y : null);
                      },
                    ),
                    const SizedBox(height: 10),
                    _settingsRecommendation(p, localYear),
                    const SizedBox(height: 22),
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final ok = await _confirmClear(context);
                        if (ok == true) state.clearAll();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(children: [
                        Icon(Icons.delete_sweep_outlined, size: 19, color: p.red),
                        const SizedBox(width: 10),
                        Text('Clear all sleep data', style: AppText.label(p.red)),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        state.setName(nameController.text);
                        final now = DateTime.now().year;
                        final y = int.tryParse(yearController.text.trim());
                        if (y != null && y >= 1900 && y <= now) state.setBirthYear(y);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration:
                            BoxDecoration(color: p.island, borderRadius: BorderRadius.circular(27)),
                        child: Text('Done', style: AppText.button(p.islandIcon)),
                      ),
                    ),
                  ]),
            ),
          ),
        );
      }),
    );
  }

  Widget _settingsField(
    AppPalette p, {
    required TextEditingController controller,
    bool number = false,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      style: AppText.label(p.textPrimary),
      cursorColor: p.green,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      maxLength: number ? 4 : null,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: p.outline, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: p.green, width: 1.5)),
      ),
    );
  }

  Widget _settingsRecommendation(AppPalette p, int? year) {
    if (year == null) {
      return Text('Set your birth year for an age-based sleep target.',
          style: AppText.tiny(p.textFaint));
    }
    final age = DateTime.now().year - year;
    final r = recommendedSleepRange(age);
    return Text('At $age, ${r.lo}–${r.hi} h a night is recommended.',
        style: AppText.tiny(p.textSecondary));
  }

  Future<bool?> _confirmClear(BuildContext context) {
    final p = context.pal;
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.surface,
        title: Text('Clear all data?', style: AppText.cardTitle(p.textPrimary)),
        content: Text('This permanently removes every logged night.',
            style: AppText.body(p.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: AppText.label(p.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Clear', style: AppText.label(p.red))),
        ],
      ),
    );
  }
}
