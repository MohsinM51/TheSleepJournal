import 'package:flutter/material.dart';

/// Everything in this app is anchored to an 8 PM baseline so that a night
/// crossing midnight lives on a single continuous axis (20:00 -> 44:00).
/// This keeps "wake-date based" logic consistent: a sleep at 22:00 and a
/// sleep at 02:00 are comparable on the same timeline.
const int kAnchorHour = 20; // 8 PM
const double kAxisStartHour = 20; // 8 PM
const double kAxisEndHour = 36; // 12 PM next day -> 16 hour window
const int kDayMinutes = 24 * 60;

int minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

TimeOfDay timeOfMinutes(int minutes) {
  var m = minutes % kDayMinutes;
  if (m < 0) m += kDayMinutes;
  return TimeOfDay(hour: m ~/ 60, minute: m % 60);
}

/// Map minutes-from-midnight into the anchored window [1200, 2640).
int anchoredMinutes(int minutesFromMidnight) {
  var a = minutesFromMidnight;
  if (a < kAnchorHour * 60) a += kDayMinutes;
  return a;
}

double anchoredHours(int minutesFromMidnight) => anchoredMinutes(minutesFromMidnight) / 60.0;

/// Sleep duration in minutes from sleep-start to wake.
int durationMinutes(int sleepMin, int wakeMin) {
  final s = anchoredMinutes(sleepMin);
  var w = anchoredMinutes(wakeMin);
  if (w < s) w += kDayMinutes;
  return w - s;
}

/// Overlap (in minutes) between an actual sleep interval and the goal window,
/// both expressed in anchored space. Used for the alignment metric.
int goalOverlapMinutes(int sleepMin, int wakeMin, int goalSleepMin, int goalWakeMin) {
  final s = anchoredMinutes(sleepMin);
  var w = anchoredMinutes(wakeMin);
  if (w < s) w += kDayMinutes;
  final gs = anchoredMinutes(goalSleepMin);
  var gw = anchoredMinutes(goalWakeMin);
  if (gw < gs) gw += kDayMinutes;
  final start = s > gs ? s : gs;
  final end = w < gw ? w : gw;
  return end > start ? end - start : 0;
}

int goalWindowMinutes(int goalSleepMin, int goalWakeMin) {
  final gs = anchoredMinutes(goalSleepMin);
  var gw = anchoredMinutes(goalWakeMin);
  if (gw < gs) gw += kDayMinutes;
  return gw - gs;
}

String greetingForHour(int hour) {
  if (hour >= 5 && hour < 12) return 'Good Morning';
  if (hour >= 12 && hour < 17) return 'Good Afternoon';
  if (hour >= 17 && hour < 22) return 'Good Evening';
  return 'Good Night';
}

/// Returns the 12-hour clock split into the digits and the AM/PM suffix.
({String time, String period}) clockParts(TimeOfDay t) {
  final period = t.period == DayPeriod.am ? 'AM' : 'PM';
  var h = t.hourOfPeriod;
  if (h == 0) h = 12;
  final mm = t.minute.toString().padLeft(2, '0');
  return (time: '$h:$mm', period: period);
}

String formatHrs(double hours) => hours.toStringAsFixed(1);

String durationLabel(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

/// Format an anchored-hour value (20..44) as a short clock label, e.g.
/// 20 -> "8PM", 24 -> "12AM", 30 -> "6AM".
String clockLabelAnchored(double anchoredHour) {
  final h = anchoredHour.round() % 24;
  final am = h < 12;
  var hh = h % 12;
  if (hh == 0) hh = 12;
  return '$hh${am ? 'AM' : 'PM'}';
}

/// Evenly spaced integer ticks covering [lo, hi].
List<double> niceIntTicks(double lo, double hi, {int target = 4}) {
  if (hi <= lo) hi = lo + 1;
  var step = ((hi - lo) / target).ceil();
  if (step < 1) step = 1;
  final out = <double>[];
  for (var v = lo.floor(); v <= hi.ceil(); v += step) {
    out.add(v.toDouble());
  }
  return out;
}
