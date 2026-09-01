import 'dart:convert';

import 'package:luqa/core/storage/luqa_store.dart';
import 'package:luqa/features/habits/data/habit_json.dart';
import 'package:luqa/features/habits/domain/habit.dart';
import 'package:sqflite/sqflite.dart';

/// The habits, on the phone.
///
/// Habits are checked off in the moments a network is least likely to be
/// there — on a run, last thing at night, on the underground — so nothing the
/// strip or the habits screen needs is allowed to depend on one. The rules
/// live here; which days they mean is worked out in Dart from these rows.
class HabitsLocalStore {
  HabitsLocalStore({required this.namespace, LuqaStore? store})
    : _store = store ?? LuqaStore.shared;

  final String namespace;
  final LuqaStore _store;

  Future<Database> get _db => _store.database;

  // ---------------------------------------------------------------- reading

  /// Every habit this device knows about, in the order they are shown.
  ///
  /// Archived ones are included: the caller decides whether it is drawing a
  /// list to act on or a history to look back at, and the store should not
  /// have an opinion about which.
  Future<List<Habit>> habits() async {
    final db = await _db;
    final rows = await db.query(
      'habit',
      where: 'namespace = ? AND removed = 0',
      whereArgs: [namespace],
      orderBy: 'ord ASC, created_at ASC',
    );
    return [for (final row in rows) _habitFrom(row)];
  }

  Future<Habit?> habit(String id) async {
    final db = await _db;
    final rows = await db.query(
      'habit',
      where: 'namespace = ? AND id = ? AND removed = 0',
      whereArgs: [namespace, id],
      limit: 1,
    );
    return rows.isEmpty ? null : _habitFrom(rows.first);
  }

  /// Progress across an inclusive range of logical days.
  ///
  /// A range rather than a day because almost nothing wants one day on its
  /// own: a weekly quota counts across its week, the insights grid across a
  /// month, and the week strip needs all seven at once.
  Future<List<HabitLog>> logsBetween(String from, String to) async {
    final db = await _db;
    final rows = await db.query(
      'habit_log',
      where: 'namespace = ? AND date_key >= ? AND date_key <= ?',
      whereArgs: [namespace, from, to],
    );
    return [for (final row in rows) _logFrom(row)];
  }

  Future<HabitLog?> log(String habitId, String dateKey) async {
    final db = await _db;
    final rows = await db.query(
      'habit_log',
      where: 'namespace = ? AND habit_id = ? AND date_key = ?',
      whereArgs: [namespace, habitId, dateKey],
      limit: 1,
    );
    return rows.isEmpty ? null : _logFrom(rows.first);
  }

  // ------------------------------------------------------- local mutations

  Future<void> putHabit(
    Habit habit, {
    bool pending = true,
    DatabaseExecutor? txn,
  }) async {
    final db = txn ?? await _db;
    await db.insert('habit', {
      'namespace': namespace,
      'id': habit.id,
      'name': habit.name,
      'icon': habit.icon,
      'color': habit.colorValue,
      'ord': habit.order,
      'goal_type': goalTypeName(habit.goalType),
      'goal_period': goalPeriodName(habit.goalPeriod),
      'target_count': habit.targetCount,
      'target_seconds': habit.targetSeconds,
      'category_id': habit.categoryId,
      'schedule_type': scheduleTypeName(habit.scheduleType),
      'weekdays': jsonEncode(habit.weekdays),
      'week_interval': habit.weekInterval,
      'interval_days': habit.intervalDays,
      'times_per_period': habit.timesPerPeriod,
      'anchor_date': habit.anchorDate,
      'dates': jsonEncode(habit.dates),
      'excluded_dates': jsonEncode(habit.excludedDates),
      'archived': habit.archived ? 1 : 0,
      'created_at': habit.createdAt.toUtc().millisecondsSinceEpoch,
      'pending': pending ? 1 : 0,
      'removed': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> putLog(
    HabitLog log, {
    bool pending = true,
    DatabaseExecutor? txn,
  }) async {
    final db = txn ?? await _db;
    await db.insert('habit_log', {
      'namespace': namespace,
      'habit_id': log.habitId,
      'date_key': log.date,
      'count': log.count,
      'seconds': log.seconds,
      'running_since': log.runningSince?.toUtc().millisecondsSinceEpoch,
      'completed_at': log.completedAt?.toUtc().millisecondsSinceEpoch,
      'pending': pending ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Writes a new ordering. Every habit named is marked pending, since the
  /// order it now has is this device's opinion until the server agrees.
  Future<void> putOrder(List<String> ids) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (var index = 0; index < ids.length; index++) {
        await txn.update(
          'habit',
          {'ord': index, 'pending': 1},
          where: 'namespace = ? AND id = ?',
          whereArgs: [namespace, ids[index]],
        );
      }
    });
  }

  // -------------------------------------------------------- applying deltas

  /// Habits as the server has them.
  ///
  /// A row this device has changed and not yet sent is left alone: the local
  /// copy is the newer of the two, and letting the delta win would undo an
  /// edit in front of the person who made it.
  Future<void> applyHabits(List<Habit> rows) async {
    final db = await _db;
    await db.transaction((txn) async {
      final pending = await _pendingHabitIds(txn);
      for (final habit in rows) {
        if (pending.contains(habit.id)) continue;
        await putHabit(habit, pending: false, txn: txn);
      }
    });
  }

  Future<void> applyLogs(List<HabitLog> rows) async {
    final db = await _db;
    await db.transaction((txn) async {
      final pending = await _pendingLogKeys(txn);
      for (final log in rows) {
        if (pending.contains('${log.habitId}|${log.date}')) continue;
        await putLog(log, pending: false, txn: txn);
      }
    });
  }

  /// Clears the pending flag once the server has acknowledged the write.
  Future<void> settleHabit(String id) async {
    final db = await _db;
    await db.update(
      'habit',
      {'pending': 0},
      where: 'namespace = ? AND id = ?',
      whereArgs: [namespace, id],
    );
  }

  Future<void> settleLog(String habitId, String dateKey) async {
    final db = await _db;
    await db.update(
      'habit_log',
      {'pending': 0},
      where: 'namespace = ? AND habit_id = ? AND date_key = ?',
      whereArgs: [namespace, habitId, dateKey],
    );
  }

  /// Repoints everything stored under an id this device invented at the id the
  /// server chose instead.
  Future<void> remapHabit(String from, String to) async {
    if (from == to) return;
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(
        'habit',
        {'id': to},
        where: 'namespace = ? AND id = ?',
        whereArgs: [namespace, from],
      );
      await txn.update(
        'habit_log',
        {'habit_id': to},
        where: 'namespace = ? AND habit_id = ?',
        whereArgs: [namespace, from],
      );
      await _store.recordRemap(
        namespace: namespace,
        kind: 'habit',
        from: from,
        to: to,
        txn: txn,
      );
    });
  }

  Future<String?> cursor(String collection) async {
    final db = await _db;
    final rows = await db.query(
      'sync_cursor',
      columns: ['cursor'],
      where: 'namespace = ? AND collection = ?',
      whereArgs: [namespace, collection],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['cursor'] as String;
  }

  Future<void> setCursor(String collection, String cursor) async {
    final db = await _db;
    await db.insert('sync_cursor', {
      'namespace': namespace,
      'collection': collection,
      'cursor': cursor,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ---------------------------------------------------------------- private

  Future<Set<String>> _pendingHabitIds(DatabaseExecutor txn) async {
    final rows = await txn.query(
      'habit',
      columns: ['id'],
      where: 'namespace = ? AND pending = 1',
      whereArgs: [namespace],
    );
    return {for (final row in rows) row['id']! as String};
  }

  Future<Set<String>> _pendingLogKeys(DatabaseExecutor txn) async {
    final rows = await txn.query(
      'habit_log',
      columns: ['habit_id', 'date_key'],
      where: 'namespace = ? AND pending = 1',
      whereArgs: [namespace],
    );
    return {
      for (final row in rows)
        '${row['habit_id']! as String}|${row['date_key']! as String}',
    };
  }

  Habit _habitFrom(Map<String, Object?> row) => Habit(
    id: row['id']! as String,
    name: row['name']! as String,
    icon: row['icon'] as String?,
    colorValue: row['color']! as int,
    order: row['ord']! as int,
    goalType: goalTypeFromName(row['goal_type'] as String?),
    goalPeriod: goalPeriodFromName(row['goal_period'] as String?),
    targetCount: row['target_count']! as int,
    targetSeconds: row['target_seconds']! as int,
    categoryId: row['category_id'] as String?,
    scheduleType: scheduleTypeFromName(row['schedule_type'] as String?),
    weekdays: _intList(row['weekdays']),
    weekInterval: row['week_interval']! as int,
    intervalDays: row['interval_days']! as int,
    timesPerPeriod: row['times_per_period']! as int,
    anchorDate: row['anchor_date'] as String?,
    dates: _stringList(row['dates']),
    excludedDates: _stringList(row['excluded_dates']),
    archived: (row['archived']! as int) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row['created_at']! as int,
      isUtc: true,
    ).toLocal(),
  );

  HabitLog _logFrom(Map<String, Object?> row) => HabitLog(
    habitId: row['habit_id']! as String,
    date: row['date_key']! as String,
    count: row['count']! as int,
    seconds: row['seconds']! as int,
    runningSince: _instant(row['running_since']),
    completedAt: _instant(row['completed_at']),
  );

  static DateTime? _instant(Object? value) => value == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(
          value as int,
          isUtc: true,
        ).toLocal();

  // A column that will not decode is treated as empty rather than fatal: the
  // habit still draws, it simply loses the part of its schedule nobody can
  // read any more.
  static List<int> _intList(Object? value) {
    try {
      return [for (final item in jsonDecode(value! as String) as List) item as int];
    } on Object {
      return const [];
    }
  }

  static List<String> _stringList(Object? value) {
    try {
      return [
        for (final item in jsonDecode(value! as String) as List) item as String,
      ];
    } on Object {
      return const [];
    }
  }
}
