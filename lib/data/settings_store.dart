import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleeptrack/data/models.dart';

class SettingsStore {
  static const _kName = 'name';
  static const _kGoalSleep = 'goal_sleep_min';
  static const _kGoalWake = 'goal_wake_min';
  static const _kTheme = 'theme_mode';
  static const _kBirthYear = 'birth_year';
  static const _kOnboarded = 'onboarded';
  static const _kSeeded = 'seeded';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<Settings> load() async {
    final p = await _prefs;
    return Settings(
      name: p.getString(_kName) ?? '',
      goalSleepMin: p.getInt(_kGoalSleep) ?? 22 * 60,
      goalWakeMin: p.getInt(_kGoalWake) ?? 6 * 60,
      themeMode: (p.getString(_kTheme) ?? 'light') == 'dark' ? ThemeMode.dark : ThemeMode.light,
      birthYear: p.getInt(_kBirthYear),
    );
  }

  Future<void> save(Settings s) async {
    final p = await _prefs;
    await p.setString(_kName, s.name);
    await p.setInt(_kGoalSleep, s.goalSleepMin);
    await p.setInt(_kGoalWake, s.goalWakeMin);
    await p.setString(_kTheme, s.themeMode == ThemeMode.dark ? 'dark' : 'light');
    if (s.birthYear != null) await p.setInt(_kBirthYear, s.birthYear!);
  }

  Future<bool> get onboarded async => (await _prefs).getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded() async => (await _prefs).setBool(_kOnboarded, true);

  Future<bool> get seeded async => (await _prefs).getBool(_kSeeded) ?? false;
  Future<void> setSeeded() async => (await _prefs).setBool(_kSeeded, true);
}
