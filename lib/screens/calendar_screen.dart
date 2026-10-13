import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sleeptrack/data/models.dart';
import 'package:sleeptrack/logic/date_utils.dart';
import 'package:sleeptrack/logic/metrics.dart';
import 'package:sleeptrack/logic/time_utils.dart';
import 'package:sleeptrack/state/app_state.dart';
import 'package:sleeptrack/theme/app_theme.dart';
import 'package:sleeptrack/widgets/add_sleep_sheet.dart';
import 'package:sleeptrack/widgets/alignment_bar.dart';
import 'package:sleeptrack/widgets/anim.dart';
import 'package:sleeptrack/widgets/common.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _weekOffset = 0;
  late int _year = DateTime.now().year;
  late int _month = DateTime.now().month;

  String _monShort(int m) => kMonthNames[m - 1].substring(0, 3);

  Future<void> _pickGoal(BuildContext context, AppState state, {required bool sleep}) async {
    final initial = sleep ? state.settings.goalSleep : state.settings.goalWake;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final m = minutesOf(picked);
      state.setGoals(
        sleep ? m : state.settings.goalSleepMin,
        sleep ? state.settings.goalWakeMin : m,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final state = context.watch<AppState>();
    final s = state.settings;
    final week = state.weekSlots(_weekOffset);
    final weekLabel =
        '${week.first.date.day} ${_monShort(week.first.date.month)} – ${week.last.date.day} ${_monShort(week.last.date.month)}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.screen, 8, Gap.screen, 120),
      children: [
        SafeArea(bottom: false, child: _utilityRow(context, state)),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Calendar', style: AppText.heading(p.textPrimary)),
                const SizedBox(height: 2),
                Text('Your sleep at a glance', style: AppText.label(p.textFaint)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Icon(Icons.calendar_month_rounded, color: p.textPrimary, size: 42),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- Weekly Sleep Alignment ---------------------------------------
        FadeSlideIn(
          delay: const Duration(milliseconds: 40),
          child: AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CardTitle('Weekly Sleep Alignment'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: _GoalField(
                      label: 'Goal Sleep',
                      time: s.goalSleep,
                      onTap: () => _pickGoal(context, state, sleep: true)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _GoalField(
                      label: 'Goal Wake',
                      time: s.goalWake,
                      onTap: () => _pickGoal(context, state, sleep: false)),
                ),
              ]),
              const SizedBox(height: 12),
              _goalRecommendation(context, state, s),
              const SizedBox(height: 20),
              Row(children: [
                _roundChevron(p, Icons.chevron_left_rounded, () => setState(() => _weekOffset--)),
                Expanded(child: Center(child: Text(weekLabel, style: AppText.label(p.textSecondary)))),
                _roundChevron(
                    p,
                    Icons.chevron_right_rounded,
                    _weekOffset >= 0 ? null : () => setState(() => _weekOffset++)),
              ]),
              const SizedBox(height: 14),
              const AlignmentAxis(labelWidth: 40),
              const SizedBox(height: 8),
              for (final slot in week) _alignmentRow(context, state, slot, s),
              const SizedBox(height: 14),
              Divider(color: p.divider, height: 1),
              const SizedBox(height: 14),
              Wrap(spacing: 16, runSpacing: 10, children: [
                const LegendDot(Colors.transparent, 'Awake', ring: true),
                LegendDot(p.green, 'Slept during goal'),
                LegendDot(p.red, 'Awake during goal'),
                LegendDot(p.amber, 'Slept outside goal'),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 14),

        // --- Sleep Score heatmap ------------------------------------------
        FadeSlideIn(
          delay: const Duration(milliseconds: 140),
          child: AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Sleep Health', style: AppText.cardTitle(p.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Duration · timing · consistency', style: AppText.tiny(p.textFaint)),
                  ]),
                ),
                _roundChevron(p, Icons.chevron_left_rounded, () => _shiftMonth(-1)),
                GestureDetector(
                  onTap: () => _pickMonthYear(context, state),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('${_monShort(_month)} $_year', style: AppText.label(p.textPrimary)),
                  ),
                ),
                _roundChevron(
                    p,
                    Icons.chevron_right_rounded,
                    _isCurrentMonthOrLater() ? null : () => _shiftMonth(1)),
              ]),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _MonthGrid(
                  key: ValueKey('$_year-$_month'),
                  year: _year,
                  month: _month,
                  today: state.today,
                  entryFor: state.entryOn,
                  healthFor: state.sleepHealthFor,
                  onTapDay: (d) => showAddSleepSheet(context, date: d, existing: state.entryOn(d)),
                ),
              ),
              const SizedBox(height: 18),
              Divider(color: p.divider, height: 1),
              const SizedBox(height: 14),
              _scoreLegend(context),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _utilityRow(BuildContext context, AppState state) {
    final p = context.pal;
    final isDark = p.brightness == Brightness.dark;
    return Row(children: [
      const Spacer(),
      SoftIconButton(
        size: 42,
        onTap: state.toggleTheme,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (c, a) => RotationTransition(turns: a, child: FadeTransition(opacity: a, child: c)),
          child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey(isDark), size: 19, color: p.textSecondary),
        ),
      ),
    ]);
  }

  Widget _alignmentRow(BuildContext context, AppState state, DaySlot slot, Settings s) {
    final p = context.pal;
    final isToday = sameDay(slot.date, state.today);
    return GestureDetector(
      onTap: () => showAddSleepSheet(context, date: slot.date, existing: slot.entry),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          SizedBox(
            width: 40,
            child: Text(weekdayShort(slot.date),
                style: AppText.label(isToday ? p.green : p.textSecondary)),
          ),
          Expanded(
            child: AlignmentBar(
              entry: slot.entry,
              goalSleepMin: s.goalSleepMin,
              goalWakeMin: s.goalWakeMin,
              height: 13,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _roundChevron(AppPalette p, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: p.surfaceAlt,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: p.outline, width: 1.5),
        ),
        child: Icon(icon, size: 20, color: onTap == null ? p.textFaint.withValues(alpha: 0.4) : p.textSecondary),
      ),
    );
  }

  Widget _scoreLegend(BuildContext context) {
    final p = context.pal;
    const ranges = ['Very Poor', 'Poor', 'Average', 'Good', 'Excellent'];
    return Wrap(spacing: 14, runSpacing: 10, children: [
      for (var i = 0; i < 5; i++) LegendDot(p.qualityBands[i], ranges[i]),
      LegendDot(p.noData, 'No Data'),
    ]);
  }

  /// One-line read on how the goal window compares to the age-based range.
  Widget _goalRecommendation(BuildContext context, AppState state, Settings s) {
    final p = context.pal;
    final range = state.sleepRange;
    final goalH = goalWindowMinutes(s.goalSleepMin, s.goalWakeMin) / 60.0;
    final goalStr = goalH == goalH.roundToDouble() ? goalH.toStringAsFixed(0) : goalH.toStringAsFixed(1);

    final String text;
    final IconData icon;
    final Color color;
    if (state.age == null) {
      text = 'Set your age in Settings for a personalized target.';
      icon = Icons.info_outline_rounded;
      color = p.textFaint;
    } else {
      final note = goalVsRecommendation(goalH, range);
      final within = note == 'within the recommended range';
      text = 'Recommended ${recommendedRangeLabel(range)} · your goal is $goalStr h ($note).';
      icon = within ? Icons.check_circle_rounded : Icons.error_outline_rounded;
      color = within ? p.green : p.amber;
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: AppText.tiny(p.textSecondary))),
    ]);
  }

  bool _isCurrentMonthOrLater() {
    final now = DateTime.now();
    return _year > now.year || (_year == now.year && _month >= now.month);
  }

  void _shiftMonth(int delta) {
    var m = _month + delta;
    var y = _year;
    while (m < 1) {
      m += 12;
      y--;
    }
    while (m > 12) {
      m -= 12;
      y++;
    }
    setState(() {
      _month = m;
      _year = y;
    });
  }

  void _pickMonthYear(BuildContext context, AppState state) {
    final now = DateTime.now();
    final earliest = state.earliestDate?.year ?? now.year;
    var tmpYear = _year;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (context, setSheet) {
        final p = context.pal;
        return Container(
          decoration: BoxDecoration(
              color: p.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(color: p.divider, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 18),
            Row(children: [
              _roundChevron(
                  p,
                  Icons.chevron_left_rounded,
                  tmpYear > earliest ? () => setSheet(() => tmpYear--) : null),
              Expanded(child: Center(child: Text('$tmpYear', style: AppText.cardTitle(p.textPrimary)))),
              _roundChevron(
                  p,
                  Icons.chevron_right_rounded,
                  tmpYear < now.year ? () => setSheet(() => tmpYear++) : null),
            ]),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: 1.9,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: List.generate(12, (i) {
                final m = i + 1;
                final disabled = tmpYear == now.year && m > now.month;
                final selected = tmpYear == _year && m == _month;
                return GestureDetector(
                  onTap: disabled
                      ? null
                      : () {
                          setState(() {
                            _year = tmpYear;
                            _month = m;
                          });
                          Navigator.pop(context);
                        },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? p.green : p.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.divider),
                    ),
                    child: Text(_monShort(m),
                        style: AppText.label(disabled
                            ? p.textFaint.withValues(alpha: 0.4)
                            : selected
                                ? Colors.white
                                : p.textPrimary)),
                  ),
                );
              }),
            ),
          ]),
        );
      }),
    );
  }
}

class _GoalField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _GoalField({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final parts = clockParts(time);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppText.sectionLabel(p.textSecondary)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.outline, width: 1.5),
          ),
          child: Row(children: [
            Text('${parts.time} ${parts.period}', style: AppText.label(p.textPrimary)),
            const Spacer(),
            Icon(Icons.access_time_rounded, size: 17, color: p.textSecondary),
          ]),
        ),
      ),
    ]);
  }
}

class _MonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final DateTime today;
  final SleepEntry? Function(DateTime) entryFor;
  final double Function(SleepEntry) healthFor;
  final void Function(DateTime) onTapDay;

  const _MonthGrid({
    super.key,
    required this.year,
    required this.month,
    required this.today,
    required this.entryFor,
    required this.healthFor,
    required this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final lead = DateTime(year, month, 1).weekday - 1; // Mon-based
    final cells = <DateTime?>[
      ...List.filled(lead, null),
      for (var d = 1; d <= daysInMonth; d++) DateTime(year, month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Column(children: [
      Row(
        children: [
          for (final w in kWeekdayShort)
            Expanded(child: Center(child: Text(w, style: AppText.axis(p.textFaint)))),
        ],
      ),
      const SizedBox(height: 8),
      for (var i = 0; i < cells.length; i += 7)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.5),
          child: Row(
            children: [
              for (final d in cells.sublist(i, i + 7)) Expanded(child: _cell(context, d)),
            ],
          ),
        ),
    ]);
  }

  Widget _cell(BuildContext context, DateTime? d) {
    final p = context.pal;
    const h = 38.0;
    if (d == null) return const SizedBox(height: h);
    final future = d.isAfter(today);
    final entry = entryFor(d);
    final isToday = sameDay(d, today);
    Color color;
    if (future) {
      color = Colors.transparent;
    } else if (entry == null) {
      color = p.noData;
    } else {
      color = p.bandForScore(healthFor(entry));
    }
    final textColor = future
        ? p.textFaint.withValues(alpha: 0.5)
        : entry == null
            ? p.textSecondary
            : p.textPrimary;
    return GestureDetector(
      onTap: future ? null : () => onTapDay(d),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: h,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(11),
          border: future
              ? null
              : Border.all(color: isToday ? p.green : p.outline, width: isToday ? 2 : 1),
        ),
        alignment: Alignment.center,
        child: Text('${d.day}', style: AppText.tiny(textColor)),
      ),
    );
  }
}
