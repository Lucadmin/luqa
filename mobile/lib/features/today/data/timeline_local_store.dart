import 'dart:convert';

import 'package:luqa/core/storage/luqa_store.dart';
import 'package:luqa/features/today/data/remote_today_repository.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:sqflite/sqflite.dart';

/// The timeline, on the phone.
///
/// The blocks and the categories are the device's own rows rather than a
/// cached copy of one window the server was asked about, so scrolling back
/// through last month works with no signal at all.
class TimelineLocalStore {
  TimelineLocalStore({required this.namespace, LuqaStore? store})
    : _store = store ?? LuqaStore.shared;

  final String namespace;
  final LuqaStore _store;

  Future<Database> get _db => _store.database;

  // ---------------------------------------------------------------- reading

  Future<List<Category>> categories() async {
    final db = await _db;
    final rows = await db.query(
      'timeline_category',
      where: 'namespace = ? AND removed = 0 AND archived = 0',
      whereArgs: [namespace],
      orderBy: 'name ASC',
    );
    return [
      for (final row in rows)
        Category(
          id: row['id']! as String,
          name: row['name']! as String,
          colorValue: row['color']! as int,
        ),
    ];
  }

  /// Everything overlapping [from, to).
  ///
  /// Overlapping rather than starting inside it: a block that began the
  /// evening before would otherwise lose its first half on the window's
  /// opening day, and a running timer has no end to compare at all.
  Future<TimelineWindow> window(DateTime from, DateTime to) async {
    final db = await _db;
    final fromMs = from.millisecondsSinceEpoch;
    final toMs = to.millisecondsSinceEpoch;

    final entryRows = await db.rawQuery(
      'SELECT * FROM timeline_entry WHERE namespace = ? AND removed = 0 '
      'AND start_ms < ? AND (end_ms IS NULL OR end_ms > ?) '
      'ORDER BY start_ms ASC',
      [namespace, toMs, fromMs],
    );
    final sleepRows = await db.rawQuery(
      'SELECT value FROM timeline_sleep WHERE namespace = ? AND removed = 0 '
      'AND start_ms < ? AND end_ms > ? ORDER BY start_ms ASC',
      [namespace, toMs, fromMs],
    );

    return TimelineWindow(
      from: from,
      to: to,
      entries: [for (final row in entryRows) _entryFromRow(row)],
      sleep: [
        for (final row in sleepRows)
          sleepFromJson(
            jsonDecode(row['value']! as String) as Map<String, Object?>,
          ),
      ],
    );
  }

  Future<TimeEntry?> entryById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'timeline_entry',
      where: 'namespace = ? AND id = ? AND removed = 0',
      whereArgs: [namespace, id],
      limit: 1,
    );
    return rows.isEmpty ? null : _entryFromRow(rows.first);
  }

  /// The timer that is running, if one is. Stopping it is part of starting
  /// the next, so it has to be findable without a window.
  Future<TimeEntry?> runningEntry() async {
    final db = await _db;
    final rows = await db.query(
      'timeline_entry',
      where: 'namespace = ? AND removed = 0 AND end_ms IS NULL',
      whereArgs: [namespace],
      orderBy: 'start_ms DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : _entryFromRow(rows.first);
  }

  Future<bool> get isEmpty async {
    final db = await _db;
    final rows = await db.query(
      'sync_cursor',
      columns: ['collection'],
      where: 'namespace = ?',
      whereArgs: [namespace],
      limit: 1,
    );
    return rows.isEmpty;
  }

  // ------------------------------------------------------- local mutations

  Future<void> putCategory(
    Category category, {
    bool pending = true,
    bool archived = false,
    DatabaseExecutor? txn,
  }) async {
    final db = txn ?? await _db;
    await db.insert('timeline_category', {
      'namespace': namespace,
      'id': category.id,
      'name': category.name,
      'color': category.colorValue,
      'archived': archived ? 1 : 0,
      'pending': pending ? 1 : 0,
      'removed': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> putEntry(
    TimeEntry entry, {
    bool pending = true,
    DatabaseExecutor? txn,
  }) async {
    final db = txn ?? await _db;
    await db.insert('timeline_entry', {
      'namespace': namespace,
      'id': entry.id,
      'description': entry.description,
      'category_id': entry.categoryId,
      'start_ms': entry.start.millisecondsSinceEpoch,
      'end_ms': entry.end?.millisecondsSinceEpoch,
      'person_ids': jsonEncode(entry.personIds),
      'pending': pending ? 1 : 0,
      'removed': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> putSleep(
    SleepEntry sleep, {
    DatabaseExecutor? txn,
  }) async {
    final db = txn ?? await _db;
    await db.insert('timeline_sleep', {
      'namespace': namespace,
      'id': sleep.id,
      'start_ms': sleep.start.millisecondsSinceEpoch,
      'end_ms': sleep.end.millisecondsSinceEpoch,
      'value': jsonEncode(sleepToJson(sleep)),
      'removed': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> remove(String table, String id) async {
    final db = await _db;
    await db.update(
      table,
      {'removed': 1, 'pending': 1},
      where: 'namespace = ? AND id = ?',
      whereArgs: [namespace, id],
    );
  }

  Future<void> forget(String table, String id) async {
    final db = await _db;
    await db.delete(
      table,
      where: 'namespace = ? AND id = ?',
      whereArgs: [namespace, id],
    );
  }

  Future<void> settle(String table, String id) async {
    final db = await _db;
    await db.update(
      table,
      {'pending': 0},
      where: 'namespace = ? AND id = ?',
      whereArgs: [namespace, id],
    );
  }

  /// The server matched a category by name and kept its own id. Every block
  /// filed under the one this device invented follows it.
  Future<void> remapCategory(String from, String to) async {
    await _store.recordRemap(
      namespace: namespace,
      kind: 'category',
      from: from,
      to: to,
    );
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(
        'timeline_category',
        {'id': to},
        where: 'namespace = ? AND id = ?',
        whereArgs: [namespace, from],
      );
      await txn.update(
        'timeline_entry',
        {'category_id': to},
        where: 'namespace = ? AND category_id = ?',
        whereArgs: [namespace, from],
      );
    });
  }

  /// The id [id] became, if the server renamed it while a screen was still
  /// holding the one this device invented.
  Future<String?> resolveCategoryId(String? id) async => id == null
      ? null
      : _store.resolveId(namespace: namespace, kind: 'category', id: id);

  // ------------------------------------------------------------ delta sync

  Future<Set<String>> _pendingIds(DatabaseExecutor db, String table) async {
    final rows = await db.query(
      table,
      columns: ['id'],
      where: 'namespace = ? AND pending = 1',
      whereArgs: [namespace],
    );
    return {for (final row in rows) row['id']! as String};
  }

  Future<void> applyCategories(
    List<Category> rows,
    List<String> deleted, {
    Set<String> archived = const {},
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      final pending = await _pendingIds(txn, 'timeline_category');
      for (final category in rows) {
        if (pending.contains(category.id)) continue;
        await putCategory(
          category,
          pending: false,
          archived: archived.contains(category.id),
          txn: txn,
        );
      }
      await _deleteAll(txn, 'timeline_category', deleted, pending);
    });
  }

  Future<void> applyEntries(List<TimeEntry> rows, List<String> deleted) async {
    final db = await _db;
    await db.transaction((txn) async {
      final pending = await _pendingIds(txn, 'timeline_entry');
      for (final entry in rows) {
        if (pending.contains(entry.id)) continue;
        await putEntry(entry, pending: false, txn: txn);
      }
      await _deleteAll(txn, 'timeline_entry', deleted, pending);
    });
  }

  /// Sleep is never written here, so nothing local can be in the way.
  Future<void> applySleep(List<SleepEntry> rows, List<String> deleted) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (final sleep in rows) {
        await putSleep(sleep, txn: txn);
      }
      for (final id in deleted) {
        await txn.delete(
          'timeline_sleep',
          where: 'namespace = ? AND id = ?',
          whereArgs: [namespace, id],
        );
      }
    });
  }

  Future<void> _deleteAll(
    DatabaseExecutor txn,
    String table,
    List<String> deleted,
    Set<String> pending,
  ) async {
    for (final id in deleted) {
      if (pending.contains(id)) continue;
      await txn.delete(
        table,
        where: 'namespace = ? AND id = ?',
        whereArgs: [namespace, id],
      );
    }
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

  // ------------------------------------------------------------- internals

  TimeEntry _entryFromRow(Map<String, Object?> row) => TimeEntry(
    id: row['id']! as String,
    description: row['description']! as String,
    categoryId: row['category_id'] as String?,
    start: DateTime.fromMillisecondsSinceEpoch(row['start_ms']! as int),
    end: row['end_ms'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row['end_ms']! as int),
    // What the timeline draws a dashed outline for.
    pendingSync: (row['pending']! as int) == 1,
    personIds: _personIds(row['person_ids']),
  );

  /// Unreadable tags are dropped rather than fatal. Who was at a dinner is
  /// worth showing when it is known; it is not worth losing the dinner over.
  static List<String> _personIds(Object? value) {
    if (value is! String || value.isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return const [];
      return [
        for (final id in decoded)
          if (id is String) id,
      ];
    } on FormatException {
      return const [];
    }
  }
}
