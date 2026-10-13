import 'package:flutter/material.dart';
import 'package:sleeptrack/data/models.dart';
import 'package:sleeptrack/data/repository.dart';
import 'package:sleeptrack/data/settings_store.dart';
import 'package:sleeptrack/logic/date_utils.dart';
import 'package:sleeptrack/logic/metrics.dart';

/// One calendar day plus the entry attributed to it (null = no data logged).
typedef DaySlot = ({DateTime date, SleepEntry? entry});

/// Single source of truth. All entries live in memory (one tiny row per day,
/// so even years of history is trivial) and are mirrored to sqflite on write.
class AppState extends ChangeNotifier {
  final _repo = SleepRepository();
  final _settingsStore = SettingsStore();
  final Map<String, SleepEntry> _entries = {};

  Settings settings = const Settings();
  Period period = Period.week;
  int pageIndex = 0; // 0 = home, 1 = calendar
  bool ready = false;
  bool onboarded = false;

  Future<void> init() async {
    settings = await _settingsStore.load();
    onboarded = await _settingsStore.onboarded;
    for (final e in await _repo.all()) {
      _entries[e.wakeDate] = e;
    }
    ready = true;
    notifyListeners();
  }

  // --- queries --------------------------------------------------------------
  DateTime get today => dateOnly(DateTime.now());

  SleepEntry? entryOn(DateTime date) => _entries[dateKey(date)];

  /// Current age in whole years (null until a birth year is set).
  int? get age {
    final by = settings.birthYear;
    if (by == null) return null;
    final a = today.year - by;
    return (a < 0 || a > 120) ? null : a;
  }

  /// Age-recommended nightly sleep range; falls back to the adult band.
  ({int lo, int hi}) get sleepRange {
    final a = age;
    return a == null ? kDefaultSleepRange : recommendedSleepRange(a);
  }

  /// Up to [kRegularityWindow] logged nights immediately before [e], used as
  /// the regularity baseline.
  List<SleepEntry> _priorEntries(SleepEntry e) {
    final prior = _entries.values.where((x) => x.wakeDate.compareTo(e.wakeDate) < 0).toList()
      ..sort((a, b) => a.wakeDate.compareTo(b.wakeDate));
    return prior.length > kRegularityWindow
        ? prior.sublist(prior.length - kRegularityWindow)
        : prior;
  }

  /// Sleep Health (1..5) for a single night, using the current goals, the
  /// age-based range, and this night's recent history for regularity.
  double sleepHealthFor(SleepEntry e) => Metrics.sleepHealth(
        e,
        goalSleepMin: settings.goalSleepMin,
        goalWakeMin: settings.goalWakeMin,
        range: sleepRange,
        regularity01: Metrics.regularityScore01(e, _priorEntries(e)),
      );

  double? avgSleepHealth(List<SleepEntry> entries) {
    if (entries.isEmpty) return null;
    final total = entries.fold<double>(0, (s, e) => s + sleepHealthFor(e));
    return total / entries.length;
  }

  List<SleepEntry> get allEntries {
    final list = _entries.values.toList();
    list.sort((a, b) => a.wakeDate.compareTo(b.wakeDate));
    return list;
  }

  DateTime? get earliestDate {
    if (_entries.isEmpty) return null;
    final keys = _entries.keys.toList()..sort();
    return DateTime.parse(keys.first);
  }

  /// Rolling window of N days ending today; one slot per day.
  List<DaySlot> windowSlots([Period? p]) {
    final days = (p ?? period).days;
    final end = today;
    return List.generate(days, (i) {
      final d = end.subtract(Duration(days: days - 1 - i));
      return (date: d, entry: _entries[dateKey(d)]);
    });
  }

  List<SleepEntry> windowEntries([Period? p]) =>
      windowSlots(p).where((s) => s.entry != null).map((s) => s.entry!).toList();

  /// Mon–Sun week, offset by [weekOffset] from the week containing today.
  List<DaySlot> weekSlots(int weekOffset) {
    final base = today.add(Duration(days: 7 * weekOffset));
    final monday = base.subtract(Duration(days: base.weekday - 1));
    return List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      return (date: d, entry: _entries[dateKey(d)]);
    });
  }

  List<DaySlot> monthSlots(int year, int month) {
    final count = DateTime(year, month + 1, 0).day;
    return List.generate(count, (i) {
      final d = DateTime(year, month, i + 1);
      return (date: d, entry: _entries[dateKey(d)]);
    });
  }

  // --- mutations ------------------------------------------------------------
  Future<void> saveEntry(SleepEntry e) async {
    _entries[e.wakeDate] = e;
    notifyListeners();
    await _repo.upsert(e);
  }

  Future<void> deleteEntry(String wakeDate) async {
    _entries.remove(wakeDate);
    notifyListeners();
    await _repo.delete(wakeDate);
  }

  Future<void> clearAll() async {
    _entries.clear();
    notifyListeners();
    await _repo.clear();
  }

  void setPeriod(Period p) {
    if (p == period) return;
    period = p;
    notifyListeners();
  }

  void setPage(int i) {
    if (i == pageIndex) return;
    pageIndex = i;
    notifyListeners();
  }

  Future<void> completeOnboarding(
      String name, int? birthYear, int goalSleepMin, int goalWakeMin) async {
    final clean = name.trim();
    settings = settings.copyWith(
      name: clean.isEmpty ? 'Friend' : clean,
      birthYear: birthYear,
      goalSleepMin: goalSleepMin,
      goalWakeMin: goalWakeMin,
    );
    onboarded = true;
    notifyListeners();
    await _settingsStore.save(settings);
    await _settingsStore.setOnboarded();
  }

  Future<void> setName(String name) async {
    settings = settings.copyWith(name: name.trim());
    notifyListeners();
    await _settingsStore.save(settings);
  }

  Future<void> setBirthYear(int year) async {
    settings = settings.copyWith(birthYear: year);
    notifyListeners();
    await _settingsStore.save(settings);
  }

  Future<void> setGoals(int sleepMin, int wakeMin) async {
    settings = settings.copyWith(goalSleepMin: sleepMin, goalWakeMin: wakeMin);
    notifyListeners();
    await _settingsStore.save(settings);
  }

  Future<void> toggleTheme() async {
    settings = settings.copyWith(
      themeMode: settings.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
    notifyListeners();
    await _settingsStore.save(settings);
  }
}
