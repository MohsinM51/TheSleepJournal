import 'package:flutter/material.dart';
import 'package:sleeptrack/logic/time_utils.dart';

/// One night of sleep, attributed to the day the user woke up (`wakeDate`).
/// Example: asleep 8 Jun 22:00, awake 9 Jun 08:00  ->  wakeDate = 2026-06-09.
@immutable
class SleepEntry {
  final String wakeDate; // ISO 'yyyy-MM-dd' — the tracking day (day of waking)
  final int sleepMin; // minutes from midnight when sleep began
  final int wakeMin; // minutes from midnight when the user woke up
  final int quality; // 1..5  (Very Poor .. Great)
  final int updatedAt; // epoch millis

  const SleepEntry({
    required this.wakeDate,
    required this.sleepMin,
    required this.wakeMin,
    required this.quality,
    this.updatedAt = 0,
  });

  TimeOfDay get sleepTime => timeOfMinutes(sleepMin);
  TimeOfDay get wakeTime => timeOfMinutes(wakeMin);
  int get durationMin => durationMinutes(sleepMin, wakeMin);
  double get durationHours => durationMin / 60.0;

  Map<String, Object?> toMap() => {
        'wake_date': wakeDate,
        'sleep_min': sleepMin,
        'wake_min': wakeMin,
        'quality': quality,
        'updated_at': updatedAt,
      };

  factory SleepEntry.fromMap(Map<String, Object?> m) => SleepEntry(
        wakeDate: m['wake_date'] as String,
        sleepMin: m['sleep_min'] as int,
        wakeMin: m['wake_min'] as int,
        quality: m['quality'] as int,
        updatedAt: (m['updated_at'] as int?) ?? 0,
      );

  SleepEntry copyWith({int? sleepMin, int? wakeMin, int? quality}) => SleepEntry(
        wakeDate: wakeDate,
        sleepMin: sleepMin ?? this.sleepMin,
        wakeMin: wakeMin ?? this.wakeMin,
        quality: quality ?? this.quality,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
}

/// User-configurable goals + identity, persisted in shared_preferences.
@immutable
class Settings {
  final String name;
  final int goalSleepMin; // default 22:00
  final int goalWakeMin; // default 06:00
  final ThemeMode themeMode;
  final int? birthYear; // null until the user sets it (drives the age-based range)

  const Settings({
    this.name = '',
    this.goalSleepMin = 22 * 60,
    this.goalWakeMin = 6 * 60,
    this.themeMode = ThemeMode.light,
    this.birthYear,
  });

  TimeOfDay get goalSleep => timeOfMinutes(goalSleepMin);
  TimeOfDay get goalWake => timeOfMinutes(goalWakeMin);

  Settings copyWith({
    String? name,
    int? goalSleepMin,
    int? goalWakeMin,
    ThemeMode? themeMode,
    int? birthYear,
  }) =>
      Settings(
        name: name ?? this.name,
        goalSleepMin: goalSleepMin ?? this.goalSleepMin,
        goalWakeMin: goalWakeMin ?? this.goalWakeMin,
        themeMode: themeMode ?? this.themeMode,
        birthYear: birthYear ?? this.birthYear,
      );
}

/// Window the dashboard aggregates over.
enum Period { week, month }

extension PeriodX on Period {
  int get days => this == Period.week ? 7 : 30;
  String get label => this == Period.week ? 'Week' : 'Month';
}
