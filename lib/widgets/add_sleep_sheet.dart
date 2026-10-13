import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sleeptrack/data/models.dart';
import 'package:sleeptrack/logic/date_utils.dart';
import 'package:sleeptrack/logic/metrics.dart';
import 'package:sleeptrack/logic/time_utils.dart';
import 'package:sleeptrack/state/app_state.dart';
import 'package:sleeptrack/theme/app_theme.dart';
import 'package:sleeptrack/widgets/quality_face.dart';

Future<void> showAddSleepSheet(BuildContext context, {DateTime? date, SleepEntry? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => _AddSleepSheet(date: date ?? DateTime.now(), existing: existing),
  );
}

class _AddSleepSheet extends StatefulWidget {
  final DateTime date;
  final SleepEntry? existing;
  const _AddSleepSheet({required this.date, this.existing});

  @override
  State<_AddSleepSheet> createState() => _AddSleepSheetState();
}

enum _Open { none, sleep, wake }

class _AddSleepSheetState extends State<_AddSleepSheet> {
  late DateTime _date = dateOnly(widget.date);
  late TimeOfDay _sleep = widget.existing?.sleepTime ?? const TimeOfDay(hour: 22, minute: 30);
  late TimeOfDay _wake = widget.existing?.wakeTime ?? const TimeOfDay(hour: 6, minute: 30);
  late int _quality = widget.existing?.quality ?? 4;
  _Open _open = _Open.none;

  int get _durationMin => durationMinutes(minutesOf(_sleep), minutesOf(_wake));

  Future<void> _pickDate() async {
    final state = context.read<AppState>();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2018),
      lastDate: state.today,
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  void _save() {
    context.read<AppState>().saveEntry(SleepEntry(
          wakeDate: dateKey(_date),
          sleepMin: minutesOf(_sleep),
          wakeMin: minutesOf(_wake),
          quality: _quality,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ));
    Navigator.of(context).pop();
  }

  void _delete() {
    context.read<AppState>().deleteEntry(dateKey(_date));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: p.outline, width: 1.5),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                      color: p.divider, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const SizedBox(width: 28),
                  Expanded(
                    child: Text(widget.existing == null ? 'Add Sleep' : 'Edit Sleep',
                        textAlign: TextAlign.center, style: AppText.cardTitle(p.textPrimary)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close_rounded, color: p.textSecondary, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // date
              GestureDetector(
                onTap: _pickDate,
                behavior: HitTestBehavior.opaque,
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.calendar_today_rounded, size: 15, color: p.textSecondary),
                    const SizedBox(width: 8),
                    Text(prettyDate(_date), style: AppText.label(p.textPrimary)),
                    Icon(Icons.expand_more_rounded, size: 18, color: p.textFaint),
                  ]),
                  const SizedBox(height: 4),
                  Text('Sleep will be recorded for ${prettyDate(_date)}',
                      style: AppText.tiny(p.textFaint)),
                ]),
              ),
              const SizedBox(height: 24),
              _question('1.  When did you sleep?'),
              const SizedBox(height: 10),
              _TimeField(
                icon: Icons.bedtime_rounded,
                value: _sleep,
                expanded: _open == _Open.sleep,
                onToggle: () => setState(() => _open = _open == _Open.sleep ? _Open.none : _Open.sleep),
                onChanged: (t) => setState(() => _sleep = t),
              ),
              const SizedBox(height: 22),
              _question('2.  When did you wake up?'),
              const SizedBox(height: 10),
              _TimeField(
                icon: Icons.wb_sunny_rounded,
                value: _wake,
                expanded: _open == _Open.wake,
                onToggle: () => setState(() => _open = _open == _Open.wake ? _Open.none : _Open.wake),
                onChanged: (t) => setState(() => _wake = t),
              ),
              const SizedBox(height: 12),
              // duration chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                    color: p.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.outline, width: 1.5)),
                child: Row(children: [
                  Icon(Icons.nightlight_round, size: 15, color: p.textSecondary),
                  const SizedBox(width: 8),
                  Text('Sleep duration: ${durationLabel(_durationMin)}',
                      style: AppText.label(p.textSecondary)),
                ]),
              ),
              const SizedBox(height: 24),
              _question('3.  Morning mood'),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var q = 1; q <= 5; q++) _qualityOption(q),
                ],
              ),
              const SizedBox(height: 28),
              Row(children: [
                if (widget.existing != null) ...[
                  _SquareButton(icon: Icons.delete_outline_rounded, onTap: _delete),
                  const SizedBox(width: 12),
                ],
                Expanded(child: _SaveButton(onTap: _save)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _question(String t) => Text(t, style: AppText.label(context.pal.textPrimary));

  Widget _qualityOption(int q) {
    final p = context.pal;
    final selected = _quality == q;
    return GestureDetector(
      onTap: () => setState(() => _quality = q),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: selected ? 1.0 : 0.9,
        duration: const Duration(milliseconds: 200),
        child: AnimatedOpacity(
          opacity: selected ? 1 : 0.55,
          duration: const Duration(milliseconds: 200),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? p.bandForScore(q.toDouble()).withValues(alpha: 0.16)
                    : Colors.transparent,
              ),
              child: QualityFace(quality: q.toDouble(), size: 42),
            ),
            const SizedBox(height: 6),
            Text(kQualityLabels[q],
                style: AppText.tiny(selected ? p.textPrimary : p.textFaint)),
          ]),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final IconData icon;
  final TimeOfDay value;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<TimeOfDay> onChanged;
  const _TimeField({
    required this.icon,
    required this.value,
    required this.expanded,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final parts = clockParts(value);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: expanded ? p.green : p.outline, width: 1.5),
      ),
      child: Column(children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: p.surfaceAlt, shape: BoxShape.circle),
                child: Icon(icon, size: 19, color: p.textSecondary),
              ),
              const SizedBox(width: 14),
              Text(parts.time, style: AppText.pillTime(p.textPrimary)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(parts.period, style: AppText.pillPeriod(p.textSecondary)),
              ),
              const Spacer(),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                child: Icon(Icons.expand_more_rounded, color: p.textFaint),
              ),
            ]),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: expanded
              ? _TimeWheel(value: value, onChanged: onChanged)
              : const SizedBox(width: double.infinity),
        ),
      ]),
    );
  }
}

class _TimeWheel extends StatefulWidget {
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;
  const _TimeWheel({required this.value, required this.onChanged});

  @override
  State<_TimeWheel> createState() => _TimeWheelState();
}

class _TimeWheelState extends State<_TimeWheel> {
  late int _h = (widget.value.hourOfPeriod == 0 ? 12 : widget.value.hourOfPeriod) - 1; // 0..11
  late int _m = widget.value.minute;
  late int _p = widget.value.period == DayPeriod.am ? 0 : 1;
  late final _hc = FixedExtentScrollController(initialItem: _h);
  late final _mc = FixedExtentScrollController(initialItem: _m);
  late final _pc = FixedExtentScrollController(initialItem: _p);

  void _emit() {
    final h12 = _h + 1;
    final hour = _p == 0 ? h12 % 12 : (h12 % 12) + 12;
    widget.onChanged(TimeOfDay(hour: hour, minute: _m));
  }

  @override
  void dispose() {
    _hc.dispose();
    _mc.dispose();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      height: 132,
      child: Stack(children: [
        Center(
          child: Container(
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
                color: p.surfaceAlt, borderRadius: BorderRadius.circular(12)),
          ),
        ),
        Row(children: [
          Expanded(
              child: _wheel(_hc, 12, (i) => (i + 1).toString().padLeft(2, '0'),
                  (i) => setState(() {
                        _h = i;
                        _emit();
                      }))),
          Text(':', style: AppText.pillTime(p.textFaint)),
          Expanded(
              child: _wheel(_mc, 60, (i) => i.toString().padLeft(2, '0'), (i) => setState(() {
                    _m = i;
                    _emit();
                  }))),
          Expanded(
              child: _wheel(_pc, 2, (i) => i == 0 ? 'AM' : 'PM', (i) => setState(() {
                    _p = i;
                    _emit();
                  }))),
        ]),
      ]),
    );
  }

  Widget _wheel(FixedExtentScrollController c, int count, String Function(int) label,
      ValueChanged<int> onChange) {
    final p = context.pal;
    return ListWheelScrollView.useDelegate(
      controller: c,
      itemExtent: 38,
      perspective: 0.005,
      diameterRatio: 1.5,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChange,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, i) =>
            Center(child: Text(label(i), style: AppText.pillTime(p.textPrimary).copyWith(fontSize: 24))),
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SaveButton({required this.onTap});
  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  double _s = 1;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GestureDetector(
      onTapDown: (_) => setState(() => _s = 0.97),
      onTapUp: (_) => setState(() => _s = 1),
      onTapCancel: () => setState(() => _s = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _s,
        duration: const Duration(milliseconds: 110),
        child: Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: p.island, borderRadius: BorderRadius.circular(29)),
          child: Text('Save Sleep', style: AppText.button(p.islandIcon)),
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.outline, width: 1.5),
        ),
        child: Icon(icon, color: p.red),
      ),
    );
  }
}
