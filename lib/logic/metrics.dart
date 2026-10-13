import 'package:flutter/material.dart';
import 'package:sleeptrack/data/models.dart';
import 'package:sleeptrack/logic/time_utils.dart';

/// quality 1..5 -> label (index 0 is a placeholder for "no data").
/// These are the "Morning Mood" faces shown when logging a night.
const List<String> kQualityLabels = ['—', 'Very Poor', 'Poor', 'Okay', 'Good', 'Great'];

// --- Sleep Health model ------------------------------------------------------
// "Sleep Health" (1..5) blends, in order of influence:
//   • Duration vs your age's recommended range — under- AND over-sleeping cost
//     points (the sleep–mortality curve is U-shaped).
//   • Regularity — how consistent this night's timing is vs your recent nights
//     (day-to-day regularity is the strongest mortality signal in the research).
//   • Morning mood — kept light: a groggy morning can't sink a good schedule.
// …all scaled by a circadian factor: how well the night's midpoint lined up with
// your goal's midpoint, so sleeping the right hours at the wrong time still drops
// hard. Grounded in NSF age norms, the UK-Biobank sleep-regularity findings, and
// the social-jetlag / circadian-misalignment literature.

/// Base-term weights (sum = 1.0). Duration leads, regularity strong, mood light.
const double kwHealthDuration = 0.60;
const double kwHealthRegularity = 0.25;
const double kwHealthMood = 0.15;

/// Circadian alignment scales the whole score between this floor and 1.0.
/// 0.40 keeps a badly out-of-phase night in Poor territory even when it is
/// otherwise long and perfectly regular — so a habitual 4am–noon schedule can't
/// hide behind its own consistency. (Lower = timing matters more.)
const double kCircadianFloor = 0.40;

/// Hours of midpoint drift (vs goal) at which circadian alignment hits zero.
const double kCircadianSpanHours = 4.0;

/// Hours over/under the recommended range at which the duration term hits zero.
const double kDurationSpanHours = 3.0;

/// Mean timing deviation (hours, vs recent nights) at which regularity hits zero.
const double kRegularitySpanHours = 2.5;

/// Trailing logged nights used as the regularity baseline.
const int kRegularityWindow = 14;

/// Minimum prior nights before regularity is judged (else treated as neutral).
const int kRegularityMinNights = 3;

/// NSF recommended nightly sleep range (whole hours) for an age in years.
({int lo, int hi}) recommendedSleepRange(int age) {
  if (age <= 2) return (lo: 11, hi: 14); // toddler
  if (age <= 5) return (lo: 10, hi: 13); // preschool
  if (age <= 13) return (lo: 9, hi: 11); // school-age
  if (age <= 17) return (lo: 8, hi: 10); // teen
  if (age <= 64) return (lo: 7, hi: 9); // adult
  return (lo: 7, hi: 8); // 65+
}

/// Default range when the user hasn't set a birth year yet (adult band).
const ({int lo, int hi}) kDefaultSleepRange = (lo: 7, hi: 9);

class Metrics {
  static double? avgDurationHours(List<SleepEntry> entries) {
    if (entries.isEmpty) return null;
    final total = entries.fold<int>(0, (s, e) => s + e.durationMin);
    return total / entries.length / 60.0;
  }

  static double? avgQuality(List<SleepEntry> entries) {
    if (entries.isEmpty) return null;
    final total = entries.fold<int>(0, (s, e) => s + e.quality);
    return total / entries.length;
  }

  /// Mean fraction of the goal window actually slept, as a percentage (0..100).
  static double? alignmentPercent(List<SleepEntry> entries, int goalSleepMin, int goalWakeMin) {
    if (entries.isEmpty) return null;
    final window = goalWindowMinutes(goalSleepMin, goalWakeMin);
    if (window <= 0) return null;
    double sum = 0;
    for (final e in entries) {
      final overlap = goalOverlapMinutes(e.sleepMin, e.wakeMin, goalSleepMin, goalWakeMin);
      sum += (overlap / window).clamp(0.0, 1.0);
    }
    return sum / entries.length * 100.0;
  }

  // --- Sleep Health sub-parts (each 0..1) -----------------------------------

  /// Morning mood 1..5 -> 0..1 (a "Very Poor" morning contributes nothing, so
  /// the light mood weight is the full available swing — roughly ±0.6 of a point).
  static double moodScore01(int quality) => ((quality - 1) / 4.0).clamp(0.0, 1.0);

  /// Full credit inside the age-recommended range; tapers linearly to 0 by
  /// [kDurationSpanHours] beyond either edge — penalising both under- and
  /// over-sleeping.
  static double durationScore01(double hours, ({int lo, int hi}) range) {
    if (hours >= range.lo && hours <= range.hi) return 1.0;
    final dist = hours < range.lo ? range.lo - hours : hours - range.hi;
    return (1 - dist / kDurationSpanHours).clamp(0.0, 1.0);
  }

  /// Sleep midpoint in 8pm-anchored minutes.
  static double _midAnchored(int sleepMin, int wakeMin) {
    final s = anchoredMinutes(sleepMin);
    var w = anchoredMinutes(wakeMin);
    if (w < s) w += kDayMinutes;
    return (s + w) / 2.0;
  }

  /// 1.0 when the night's midpoint matches the goal's; 0 once it drifts
  /// [kCircadianSpanHours] away. This is the circadian-alignment signal.
  static double midpointAlignment01(SleepEntry e, int goalSleepMin, int goalWakeMin) {
    final drift =
        (_midAnchored(e.sleepMin, e.wakeMin) - _midAnchored(goalSleepMin, goalWakeMin)).abs() /
            60.0;
    return (1 - drift / kCircadianSpanHours).clamp(0.0, 1.0);
  }

  /// Consistency of this night's onset & wake vs the recent baseline nights.
  /// Neutral (1.0) until there are enough prior nights to judge.
  static double regularityScore01(SleepEntry e, List<SleepEntry> baseline) {
    if (baseline.length < kRegularityMinNights) return 1.0;
    double meanAnchored(int Function(SleepEntry) f) {
      final a = baseline.map((b) => anchoredMinutes(f(b))).toList();
      return a.reduce((x, y) => x + y) / a.length;
    }

    final devSleep = (anchoredMinutes(e.sleepMin) - meanAnchored((b) => b.sleepMin)).abs();
    final devWake = (anchoredMinutes(e.wakeMin) - meanAnchored((b) => b.wakeMin)).abs();
    final avgDevHours = (devSleep + devWake) / 2.0 / 60.0;
    return (1 - avgDevHours / kRegularitySpanHours).clamp(0.0, 1.0);
  }

  /// Composite "Sleep Health" on a 1..5 scale (drives the heatmap + trio + graph).
  /// [regularity01] is supplied by the caller, which holds the night's history.
  static double sleepHealth(
    SleepEntry e, {
    required int goalSleepMin,
    required int goalWakeMin,
    required ({int lo, int hi}) range,
    required double regularity01,
  }) {
    final base = kwHealthDuration * durationScore01(e.durationHours, range) +
        kwHealthRegularity * regularity01 +
        kwHealthMood * moodScore01(e.quality);
    final circadian = kCircadianFloor +
        (1 - kCircadianFloor) * midpointAlignment01(e, goalSleepMin, goalWakeMin);
    return 1 + 4 * (circadian * base);
  }

  /// Circular mean of times (minutes from midnight) computed in 8pm-anchored
  /// space, so 23:30 and 00:30 average to 00:00 rather than noon.
  static TimeOfDay? meanTime(Iterable<int> minutesFromMidnight) {
    final list = minutesFromMidnight.toList();
    if (list.isEmpty) return null;
    final total = list.fold<int>(0, (s, m) => s + anchoredMinutes(m));
    return timeOfMinutes((total / list.length).round() % kDayMinutes);
  }

  static TimeOfDay? avgSleepTime(List<SleepEntry> entries) =>
      meanTime(entries.map((e) => e.sleepMin));
  static TimeOfDay? avgWakeTime(List<SleepEntry> entries) =>
      meanTime(entries.map((e) => e.wakeMin));
}

String qualityLabel(num quality) => kQualityLabels[quality.round().clamp(1, 5)];

const List<String> kScoreRanges = ['Very Poor', 'Poor', 'Average', 'Good', 'Excellent'];

/// Maps a 1..5 Sleep Health score to its band label (thresholds match
/// AppPalette.bandForScore).
String scoreLabel(double score5) {
  if (score5 >= 4.5) return kScoreRanges[4];
  if (score5 >= 3.5) return kScoreRanges[3];
  if (score5 >= 2.5) return kScoreRanges[2];
  if (score5 >= 1.5) return kScoreRanges[1];
  return kScoreRanges[0];
}

/// Recommended-range helpers for the goal vs. age comparison shown in the UI.
String recommendedRangeLabel(({int lo, int hi}) range) => '${range.lo}–${range.hi} h';

/// Short note comparing a goal-window length (hours) to the recommended range.
String goalVsRecommendation(double goalHours, ({int lo, int hi}) range) {
  if (goalHours > range.hi + 0.08) return 'longer than recommended';
  if (goalHours < range.lo - 0.08) return 'shorter than recommended';
  return 'within the recommended range';
}
