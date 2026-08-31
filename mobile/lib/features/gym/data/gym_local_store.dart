import 'package:luqa/core/storage/luqa_store.dart';
import 'package:luqa/features/gym/domain/gym_math.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';
import 'package:sqflite/sqflite.dart';

/// The gym log, on the phone.
///
/// A gym is the worst place on earth for a network, so nothing a workout
/// screen needs is allowed to depend on one. Every figure the overview and the
/// history sheet show — how often an exercise was done, what was lifted last
/// time, which sessions were records — is derived here from the rows this
/// device holds.
class GymLocalStore {
  GymLocalStore({required this.namespace, LuqaStore? store})
    : _store = store ?? LuqaStore.shared;

  final String namespace;
  final LuqaStore _store;

  Future<Database> get _db => _store.database;

  // ---------------------------------------------------------------- reading

  Future<GymOverview> overview({int limit = 30}) async {
    final db = await _db;
    final locations = await _locations(db);
    final exercises = await _exercises(db);
    final usage = await _usage(db);
    final sessions = await _sessions(db, limit: limit);
    final total = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM gym_session WHERE namespace = ? AND removed = 0',
        [namespace],
      ),
    );

    return GymOverview(
      locations: locations,
      exercises: [
        for (final exercise in exercises)
          GymExercise(
            id: exercise.id,
            name: exercise.name,
            notes: exercise.notes,
            archived: exercise.archived,
            sessionCount: usage[exercise.id]?.sessionCount ?? 0,
            lastPerformed: usage[exercise.id]?.lastPerformed,
            locationIds: usage[exercise.id]?.locationIds.toList() ?? const [],
          ),
      ],
      recentReferences: await _recentReferences(db),
      sessions: sessions,
      totalSessions: total ?? 0,
    );
  }

  Future<GymSession?> session(String id) async {
    final db = await _db;
    final rows = await db.query(
      'gym_session',
      where: 'namespace = ? AND id = ? AND removed = 0',
      whereArgs: [namespace, id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (await _hydrate(db, rows)).single;
  }

  Future<GymSessionPage> sessions({String? cursor, int limit = 20}) async {
    final db = await _db;
    final where = <String>['namespace = ?', 'removed = 0'];
    final args = <Object?>[namespace];

    final after = _decodeCursor(cursor);
    if (after != null) {
      where.add(
        '(date_key < ? OR (date_key = ? AND (created_at < ? OR '
        '(created_at = ? AND id < ?))))',
      );
      args
        ..add(after.dateKey)
        ..add(after.dateKey)
        ..add(after.createdAt)
        ..add(after.createdAt)
        ..add(after.id);
    }

    final rows = await db.query(
      'gym_session',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'date_key DESC, created_at DESC, id DESC',
      limit: limit + 1,
    );
    final hasMore = rows.length > limit;
    final page = hasMore ? rows.sublist(0, limit) : rows;
    final last = page.isEmpty ? null : page.last;

    return GymSessionPage(
      sessions: await _hydrate(db, page),
      nextCursor: hasMore && last != null
          ? _encodeCursor(
              last['date_key']! as String,
              last['created_at']! as String,
              last['id']! as String,
            )
          : null,
    );
  }

  /// Every time this exercise was done, oldest first, with the derived numbers
  /// the history sheet plots.
  ///
  /// [beforeSessionId] makes "last time" mean the workout before the one being
  /// edited, so reopening an old session shows what preceded it rather than
  /// what has happened since.
  Future<GymExerciseHistory?> exerciseHistory(
    String exerciseId, {
    String? locationId,
    String? beforeSessionId,
  }) async {
    final db = await _db;
    final exerciseRows = await db.query(
      'gym_exercise',
      where: 'namespace = ? AND id = ? AND removed = 0',
      whereArgs: [namespace, exerciseId],
      limit: 1,
    );
    if (exerciseRows.isEmpty) return null;

    final where = <String>[
      'se.namespace = ?',
      'se.exercise_id = ?',
      's.removed = 0',
    ];
    final args = <Object?>[namespace, exerciseId];
    if (locationId != null) {
      where.add('s.location_id = ?');
      args.add(locationId);
    }
    if (beforeSessionId != null) {
      final before = await db.query(
        'gym_session',
        columns: ['date_key', 'created_at'],
        where: 'namespace = ? AND id = ?',
        whereArgs: [namespace, beforeSessionId],
        limit: 1,
      );
      if (before.isNotEmpty) {
        where.add(
          '(s.date_key < ? OR (s.date_key = ? AND s.created_at < ?))',
        );
        args
          ..add(before.first['date_key'])
          ..add(before.first['date_key'])
          ..add(before.first['created_at']);
      }
    }

    final rows = await db.rawQuery(
      'SELECT se.id, se.raw, se.notes, se.ord, s.id AS session_id, s.date_key, '
      's.location_id FROM gym_session_exercise se '
      'JOIN gym_session s ON s.namespace = se.namespace AND s.id = se.session_id '
      'WHERE ${where.join(' AND ')} '
      // Fully ordered, not just by day. Two workouts can share a date and —
      // since merging two spellings folds their entries together — one workout
      // can hold the same exercise twice. Without the last two keys the order
      // of those is arbitrary, which decides where the record badge lands.
      'ORDER BY s.date_key ASC, s.created_at ASC, se.ord ASC LIMIT 400',
      args,
    );
    final sets = await _setsFor(db, [
      for (final row in rows) row['id']! as String,
    ]);

    final points = markPersonalRecords([
      for (final row in rows)
        _pointFrom(row, sets[row['id']] ?? const <GymSet>[]),
    ]);

    final usage = await _usage(db);
    final stats = usage[exerciseId];

    double? best;
    double? heaviest;
    for (final point in points) {
      final oneRepMax = point.bestOneRepMax;
      if (oneRepMax != null && (best == null || oneRepMax > best)) {
        best = oneRepMax;
      }
      final weight = point.topWeight;
      if (weight != null && (heaviest == null || weight > heaviest)) {
        heaviest = weight;
      }
    }

    final exercise = exerciseRows.first;
    return GymExerciseHistory(
      exercise: GymExercise(
        id: exercise['id']! as String,
        name: exercise['name']! as String,
        notes: exercise['notes']! as String,
        archived: (exercise['archived']! as int) == 1,
        sessionCount: stats?.sessionCount ?? 0,
        lastPerformed: stats?.lastPerformed,
        locationIds: stats?.locationIds.toList() ?? const [],
      ),
      points: points,
      bestEver: best,
      heaviest: heaviest,
    );
  }

  Future<List<GymLocation>> locations() async => _locations(await _db);

  // ------------------------------------------------------- local mutations

  Future<void> putLocation(
    GymLocation location, {
    bool pending = true,
    DatabaseExecutor? txn,
  }) async {
    final db = txn ?? await _db;
    await db.insert('gym_location', {
      'namespace': namespace,
      'id': location.id,
      'code': location.code,
      'name': location.name,
      'color': location.colorValue,
      'ord': location.order,
      'archived': location.archived ? 1 : 0,
      'pending': pending ? 1 : 0,
      'removed': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> putExercise(
    GymExercise exercise, {
    bool pending = true,
    DatabaseExecutor? txn,
  }) async {
    final db = txn ?? await _db;
    await db.insert('gym_exercise', {
      'namespace': namespace,
      'id': exercise.id,
      'name': exercise.name,
      'notes': exercise.notes,
      'archived': exercise.archived ? 1 : 0,
      'pending': pending ? 1 : 0,
      'removed': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Writes a workout and everything in it.
  ///
  /// The exercises and sets are replaced wholesale, because that is what
  /// saving a workout means: the editor sends the whole thing every time, and
  /// a set that is no longer in it is a set that was deleted.
  Future<void> putSession(
    GymSession session, {
    bool pending = true,
    DatabaseExecutor? txn,
  }) async {
    Future<void> write(DatabaseExecutor db) async {
      await db.insert('gym_session', {
        'namespace': namespace,
        'id': session.id,
        'date_key': session.dateKey,
        'location_id': session.locationId,
        'notes': session.notes,
        'created_at': session.createdAt.toUtc().toIso8601String(),
        'pending': pending ? 1 : 0,
        'removed': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      final existing = await db.query(
        'gym_session_exercise',
        columns: ['id'],
        where: 'namespace = ? AND session_id = ?',
        whereArgs: [namespace, session.id],
      );
      for (final row in existing) {
        await db.delete(
          'gym_set',
          where: 'namespace = ? AND session_exercise_id = ?',
          whereArgs: [namespace, row['id']],
        );
      }
      await db.delete(
        'gym_session_exercise',
        where: 'namespace = ? AND session_id = ?',
        whereArgs: [namespace, session.id],
      );

      for (final exercise in session.exercises) {
        await db.insert('gym_session_exercise', {
          'namespace': namespace,
          'id': exercise.id,
          'session_id': session.id,
          'exercise_id': exercise.exerciseId,
          'name': exercise.name,
          'ord': exercise.order,
          'raw': exercise.raw,
          'notes': exercise.notes,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        for (final (index, set) in exercise.sets.indexed) {
          await db.insert('gym_set', {
            'namespace': namespace,
            'session_exercise_id': exercise.id,
            'ord': index,
            'weight': set.weight,
            'reps': set.reps,
            'note': set.note,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    }

    if (txn != null) return write(txn);
    return (await _db).transaction(write);
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

  Future<void> settle(String table, String id) async {
    final db = await _db;
    await db.update(
      table,
      {'pending': 0},
      where: 'namespace = ? AND id = ?',
      whereArgs: [namespace, id],
    );
  }

  /// Renames a row the server gave a different id to. Everything pointing at
  /// the id this device invented follows it.
  Future<void> remapId(String table, String from, String to) async {
    await _store.recordRemap(
      namespace: namespace,
      kind: table,
      from: from,
      to: to,
    );
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(
        table,
        {'id': to},
        where: 'namespace = ? AND id = ?',
        whereArgs: [namespace, from],
      );
      if (table == 'gym_location') {
        await txn.update(
          'gym_session',
          {'location_id': to},
          where: 'namespace = ? AND location_id = ?',
          whereArgs: [namespace, from],
        );
      }
      if (table == 'gym_exercise') {
        await txn.update(
          'gym_session_exercise',
          {'exercise_id': to},
          where: 'namespace = ? AND exercise_id = ?',
          whereArgs: [namespace, from],
        );
      }
      if (table == 'gym_session') {
        await txn.update(
          'gym_session_exercise',
          {'session_id': to},
          where: 'namespace = ? AND session_id = ?',
          whereArgs: [namespace, from],
        );
      }
    });
  }

  /// Remembers that one exercise was folded into another, so a screen still
  /// holding the retired id keeps working.
  Future<void> recordMerge(String source, String target) => _store.recordRemap(
    namespace: namespace,
    kind: 'gym_exercise',
    from: source,
    to: target,
  );

  /// The id [id] became, if the server renamed it while a screen was still
  /// holding the one this device invented.
  Future<String?> resolve(String table, String? id) async => id == null
      ? null
      : _store.resolveId(namespace: namespace, kind: table, id: id);

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

  Future<void> applyLocations(
    List<GymLocation> rows,
    List<String> deleted,
  ) async {
    final db = await _db;
    await db.transaction((txn) async {
      final pending = await _pendingIds(txn, 'gym_location');
      for (final location in rows) {
        if (pending.contains(location.id)) continue;
        await putLocation(location, pending: false, txn: txn);
      }
      await _deleteAll(txn, 'gym_location', deleted, pending);
    });
  }

  Future<void> applyExercises(
    List<GymExercise> rows,
    List<String> deleted,
  ) async {
    final db = await _db;
    await db.transaction((txn) async {
      final pending = await _pendingIds(txn, 'gym_exercise');
      for (final exercise in rows) {
        if (pending.contains(exercise.id)) continue;
        await putExercise(exercise, pending: false, txn: txn);
      }
      await _deleteAll(txn, 'gym_exercise', deleted, pending);
    });
  }

  Future<void> applySessions(
    List<GymSession> rows,
    List<String> deleted,
  ) async {
    final db = await _db;
    await db.transaction((txn) async {
      final pending = await _pendingIds(txn, 'gym_session');
      for (final session in rows) {
        if (pending.contains(session.id)) continue;
        await putSession(session, pending: false, txn: txn);
      }
      await _deleteAll(txn, 'gym_session', deleted, pending);
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
      if (table == 'gym_session') {
        final children = await txn.query(
          'gym_session_exercise',
          columns: ['id'],
          where: 'namespace = ? AND session_id = ?',
          whereArgs: [namespace, id],
        );
        for (final child in children) {
          await txn.delete(
            'gym_set',
            where: 'namespace = ? AND session_exercise_id = ?',
            whereArgs: [namespace, child['id']],
          );
        }
        await txn.delete(
          'gym_session_exercise',
          where: 'namespace = ? AND session_id = ?',
          whereArgs: [namespace, id],
        );
      }
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

  Future<List<GymLocation>> _locations(DatabaseExecutor db) async {
    final rows = await db.query(
      'gym_location',
      where: 'namespace = ? AND removed = 0',
      whereArgs: [namespace],
      orderBy: 'ord ASC, code ASC',
    );
    return [
      for (final row in rows)
        GymLocation(
          id: row['id']! as String,
          code: row['code']! as String,
          name: row['name']! as String,
          colorValue: row['color']! as int,
          order: row['ord']! as int,
          archived: (row['archived']! as int) == 1,
        ),
    ];
  }

  Future<List<GymExercise>> _exercises(DatabaseExecutor db) async {
    final rows = await db.query(
      'gym_exercise',
      where: 'namespace = ? AND removed = 0',
      whereArgs: [namespace],
      orderBy: 'name ASC',
    );
    return [
      for (final row in rows)
        GymExercise(
          id: row['id']! as String,
          name: row['name']! as String,
          notes: row['notes']! as String,
          archived: (row['archived']! as int) == 1,
          sessionCount: 0,
          lastPerformed: null,
          locationIds: const [],
        ),
    ];
  }

  /// How often each exercise was done, when last, and where.
  Future<Map<String, _Usage>> _usage(DatabaseExecutor db) async {
    final rows = await db.rawQuery(
      'SELECT se.exercise_id, s.date_key, s.location_id '
      'FROM gym_session_exercise se '
      'JOIN gym_session s ON s.namespace = se.namespace AND s.id = se.session_id '
      'WHERE se.namespace = ? AND s.removed = 0',
      [namespace],
    );
    final usage = <String, _Usage>{};
    for (final row in rows) {
      final entry = usage.putIfAbsent(
        row['exercise_id']! as String,
        _Usage.new,
      );
      entry.sessionCount += 1;
      final dateKey = row['date_key']! as String;
      if (entry.lastPerformed == null ||
          dateKey.compareTo(entry.lastPerformed!) > 0) {
        entry.lastPerformed = dateKey;
      }
      final locationId = row['location_id'] as String?;
      if (locationId != null) entry.locationIds.add(locationId);
    }
    return usage;
  }

  /// One true latest performance per exercise and location — what the picker
  /// shows as a placeholder when you start the same lift again.
  Future<List<GymExerciseReference>> _recentReferences(
    DatabaseExecutor db,
  ) async {
    final rows = await db.rawQuery(
      'SELECT se.id, se.exercise_id, se.raw, se.notes, s.id AS session_id, '
      's.date_key, s.location_id FROM gym_session_exercise se '
      'JOIN gym_session s ON s.namespace = se.namespace AND s.id = se.session_id '
      'WHERE se.namespace = ? AND s.removed = 0 '
      'ORDER BY s.date_key DESC, s.created_at DESC, se.ord DESC',
      [namespace],
    );
    final sets = await _setsFor(db, [
      for (final row in rows) row['id']! as String,
    ]);

    final seen = <String>{};
    final references = <GymExerciseReference>[];
    for (final row in rows) {
      final key =
          '${row['exercise_id']}:${row['location_id'] ?? 'none'}';
      if (!seen.add(key)) continue;
      references.add(
        GymExerciseReference(
          exerciseId: row['exercise_id']! as String,
          sessionId: row['session_id']! as String,
          dateKey: row['date_key']! as String,
          locationId: row['location_id'] as String?,
          raw: row['raw']! as String,
          notes: row['notes']! as String,
          sets: sets[row['id']] ?? const [],
        ),
      );
    }
    return references;
  }

  Future<List<GymSession>> _sessions(
    DatabaseExecutor db, {
    required int limit,
  }) async => _hydrate(
    db,
    await db.query(
      'gym_session',
      where: 'namespace = ? AND removed = 0',
      whereArgs: [namespace],
      orderBy: 'date_key DESC, created_at DESC, id DESC',
      limit: limit,
    ),
  );

  /// Fills workouts out with their exercises and sets, in two queries rather
  /// than two per workout.
  Future<List<GymSession>> _hydrate(
    DatabaseExecutor db,
    List<Map<String, Object?>> sessionRows,
  ) async {
    if (sessionRows.isEmpty) return const [];
    final ids = [for (final row in sessionRows) row['id']! as String];
    final placeholders = List.filled(ids.length, '?').join(',');

    final exerciseRows = await db.rawQuery(
      'SELECT * FROM gym_session_exercise WHERE namespace = ? '
      'AND session_id IN ($placeholders) ORDER BY ord ASC',
      [namespace, ...ids],
    );
    final sets = await _setsFor(db, [
      for (final row in exerciseRows) row['id']! as String,
    ]);

    final bySession = <String, List<GymSessionExercise>>{};
    for (final row in exerciseRows) {
      bySession.putIfAbsent(row['session_id']! as String, () => []).add(
        GymSessionExercise(
          id: row['id']! as String,
          exerciseId: row['exercise_id']! as String,
          name: row['name']! as String,
          order: row['ord']! as int,
          raw: row['raw']! as String,
          notes: row['notes']! as String,
          sets: sets[row['id']] ?? const [],
        ),
      );
    }

    return [
      for (final row in sessionRows)
        GymSession(
          id: row['id']! as String,
          dateKey: row['date_key']! as String,
          locationId: row['location_id'] as String?,
          notes: row['notes']! as String,
          exercises: bySession[row['id']] ?? const [],
          createdAt: DateTime.parse(row['created_at']! as String).toLocal(),
        ),
    ];
  }

  Future<Map<String, List<GymSet>>> _setsFor(
    DatabaseExecutor db,
    List<String> sessionExerciseIds,
  ) async {
    if (sessionExerciseIds.isEmpty) return const {};
    final placeholders = List.filled(sessionExerciseIds.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT * FROM gym_set WHERE namespace = ? '
      'AND session_exercise_id IN ($placeholders) ORDER BY ord ASC',
      [namespace, ...sessionExerciseIds],
    );
    final byExercise = <String, List<GymSet>>{};
    for (final row in rows) {
      byExercise
          .putIfAbsent(row['session_exercise_id']! as String, () => [])
          .add(
            GymSet(
              weight: (row['weight'] as num?)?.toDouble(),
              reps: row['reps'] as int?,
              note: row['note'] as String?,
            ),
          );
    }
    return byExercise;
  }

  GymExercisePoint _pointFrom(Map<String, Object?> row, List<GymSet> sets) =>
      GymExercisePoint(
        sessionId: row['session_id']! as String,
        dateKey: row['date_key']! as String,
        locationId: row['location_id'] as String?,
        raw: row['raw']! as String,
        notes: row['notes']! as String,
        sets: sets,
        topWeight: topWeight(sets),
        bestOneRepMax: bestOneRepMax(sets),
        totalReps: totalReps(sets),
        volume: totalVolume(sets),
        isPersonalRecord: false,
      );

  static String _encodeCursor(String dateKey, String createdAt, String id) =>
      '$dateKey|$createdAt|$id';

  static ({String dateKey, String createdAt, String id})? _decodeCursor(
    String? value,
  ) {
    if (value == null) return null;
    final parts = value.split('|');
    if (parts.length != 3) return null;
    return (dateKey: parts[0], createdAt: parts[1], id: parts[2]);
  }
}

class _Usage {
  int sessionCount = 0;
  String? lastPerformed;
  final Set<String> locationIds = {};
}
