import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Tiny single-table store. One row per wake-date, so the schema itself
/// enforces the "one night, attributed to the day of waking" rule.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;
  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'sleeptrack.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE entries(
          wake_date  TEXT    PRIMARY KEY,   -- ISO yyyy-MM-dd, day of waking
          sleep_min  INTEGER NOT NULL,      -- minutes from midnight
          wake_min   INTEGER NOT NULL,
          quality    INTEGER NOT NULL,      -- 1..5
          updated_at INTEGER NOT NULL
        )
      '''),
    );
  }
}
