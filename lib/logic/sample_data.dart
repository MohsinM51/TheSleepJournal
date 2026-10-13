import 'dart:math';
import 'package:sleeptrack/data/models.dart';
import 'package:sleeptrack/logic/date_utils.dart';

/// A few weeks of plausible nights so the dashboard, graphs and calendar are
/// alive on first launch. Deterministic (fixed seed) and removable any time
/// from Settings → Clear all data.
List<SleepEntry> buildSampleData({int days = 38}) {
  final rnd = Random(7);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final out = <SleepEntry>[];
  for (var i = 0; i < days; i++) {
    final d = today.subtract(Duration(days: i));
    if (i != 0 && rnd.nextDouble() < 0.12) continue; // the odd un-logged night
    final sleepMin = 22 * 60 + 30 + (rnd.nextInt(160) - 80); // ~21:10–23:50
    final wakeMin = 6 * 60 + 45 + (rnd.nextInt(140) - 70); // ~05:35–07:55
    final quality = (2 + rnd.nextInt(4)).clamp(1, 5); // mostly 2..5
    out.add(SleepEntry(
      wakeDate: dateKey(d),
      sleepMin: sleepMin % (24 * 60),
      wakeMin: wakeMin % (24 * 60),
      quality: quality,
    ));
  }
  return out;
}
