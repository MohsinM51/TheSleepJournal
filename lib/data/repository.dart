import 'package:sqflite/sqflite.dart';
import 'package:sleeptrack/data/database.dart';
import 'package:sleeptrack/data/models.dart';

class SleepRepository {
  Future<List<SleepEntry>> all() async {
    final db = await AppDatabase.instance.db;
    final rows = await db.query('entries', orderBy: 'wake_date ASC');
    return rows.map(SleepEntry.fromMap).toList();
  }

  Future<void> upsert(SleepEntry e) async {
    final db = await AppDatabase.instance.db;
    await db.insert('entries', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String wakeDate) async {
    final db = await AppDatabase.instance.db;
    await db.delete('entries', where: 'wake_date = ?', whereArgs: [wakeDate]);
  }

  Future<void> clear() async {
    final db = await AppDatabase.instance.db;
    await db.delete('entries');
  }

  Future<void> bulkInsert(List<SleepEntry> entries) async {
    final db = await AppDatabase.instance.db;
    final batch = db.batch();
    for (final e in entries) {
      batch.insert('entries', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
