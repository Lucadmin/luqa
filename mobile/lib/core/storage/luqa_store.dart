import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// The one place anything device-local is kept.
///
/// Everything the phone remembers between launches — the read caches, the
/// queues of unsent writes, the record of writes that were abandoned — lives
/// in a single SQLite file. That is the point: a queue and the cache it is
/// laid over can then be changed together or not at all, which a pile of
/// separate preference keys can never promise.
///
/// Two shapes cover every caller:
///
/// * a **document** is one addressable blob — the money overview, the cached
///   timeline window, one workout. Written by key, read by key.
/// * a **record** is a row in an ordered list — one queued mutation, one
///   abandoned write. Read back in the order it was written.
///
/// Values are JSON text throughout, so every existing `toJson`/`fromJson`
/// keeps working unchanged; this layer only decides where bytes live, not
/// what they mean.
class LuqaStore {
  LuqaStore({DatabaseFactory? factory, String? path})
    // ignore: prefer_initializing_formals
    : _injectedFactory = factory,
      // ignore: prefer_initializing_formals
      _path = path;

  /// The database every store in the running app shares. Built once, opened
  /// lazily: constructing a store must not require a platform channel, since
  /// providers build them eagerly and signed-out ones never read anything.
  static final LuqaStore shared = LuqaStore();

  static const _version = 6;

  final DatabaseFactory? _injectedFactory;
  final String? _path;

  Future<Database>? _database;

  // Resolved on use, never in the constructor: building a store is not the
  // same as needing the platform channel, and a provider for a signed-out
  // user builds one it will never read from.
  DatabaseFactory get _factory => _injectedFactory ?? databaseFactory;

  Future<Database> get _db => _database ??= _open();

  Future<Database> _open() async {
    final factory = _factory;
    final path = _path ?? p.join(await factory.getDatabasesPath(), 'luqa.db');
    try {
      return await _openAt(path);
    } on Object {
      // A database that will not open is not something the user can act on,
      // and refusing to start would be worse than starting empty: the app
      // still works against the network, it just has nothing older to show.
      // The same trade the JSON stores made when a blob would not parse.
      await factory.deleteDatabase(path);
      return _openAt(path);
    }
  }

  Future<Database> _openAt(String path) => _factory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: _version,
      onCreate: (db, version) async {
        final batch = db.batch();
        batch.execute('''
          CREATE TABLE documents (
            namespace TEXT NOT NULL,
            collection TEXT NOT NULL,
            key TEXT NOT NULL,
            value TEXT NOT NULL,
            updated_at INTEGER NOT NULL,
            PRIMARY KEY (namespace, collection, key)
          )
        ''');
        batch.execute('''
          CREATE TABLE records (
            seq INTEGER PRIMARY KEY AUTOINCREMENT,
            namespace TEXT NOT NULL,
            collection TEXT NOT NULL,
            value TEXT NOT NULL
          )
        ''');
        // Every record read is "this user's queue, oldest first".
        batch.execute('''
          CREATE INDEX records_by_queue
            ON records (namespace, collection, seq)
        ''');
        _createPeopleTables(batch);
        _createMoneyTables(batch);
        _createGymTables(batch);
        _createTimelineTables(batch);
        _createRemapTable(batch);
        await batch.commit();
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        final batch = db.batch();
        if (oldVersion < 2) {
          _createPeopleTables(batch);
          _createMoneyTables(batch);
        }
        if (oldVersion < 3) _createGymTables(batch);
        if (oldVersion < 4) _createTimelineTables(batch);
        if (oldVersion < 5) _promotePersonTable(batch, oldVersion);
        if (oldVersion < 6) _addEntryPeople(batch, oldVersion);
        if (oldVersion < 5) _createRemapTable(batch);
        await batch.commit();
      },
      // Going backwards means an older build opened a newer file. There is
      // nothing to salvage and the caches refill themselves.
      onDowngrade: onDatabaseDowngradeDelete,
    ),
  );

  /// The money feature's own rows, rather than a cached copy of the server's
  /// answers about them.
  ///
  /// Holding the raw data is what lets a balance be a sum over what is here —
  /// true before a write has synced and after it, with nothing to replay and
  /// nothing to reverse.
  ///
  /// Two columns carry the sync state every row needs:
  ///
  /// * `pending` — this device has changed the row and the server has not
  ///   confirmed it. A delta must not overwrite it; the local copy is newer.
  /// * `removed` — deleted here, not yet tombstoned there. Filtered out of
  ///   every read, and dropped for real when the delta confirms it.

  /// The person, and the record hanging off them.
  ///
  /// Not `person` any more: the same friend appears on a bill, in the
  /// People tab, and on a map, and one row has to serve all three. Money still
  /// reads the identity columns for its balances; the profile columns and the
  /// four child tables belong to People.
  ///
  /// The children are written whole rather than merged. The server sends a
  /// person as one row with its notes, gifts, places and channels inside it —
  /// one row is one profile — so applying a delta replaces a person's children
  /// outright, and a partial write is not a state that can occur.
  static void _createPeopleTables(Batch batch) {
    batch.execute('''
      CREATE TABLE person (
        namespace TEXT NOT NULL,
        id TEXT NOT NULL,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        emoji TEXT,
        default_percent INTEGER,
        ord INTEGER NOT NULL DEFAULT 0,
        archived INTEGER NOT NULL DEFAULT 0,
        nickname TEXT,
        photo_url TEXT,
        birthday_year INTEGER,
        birthday_month INTEGER,
        birthday_day INTEGER,
        cadence_days INTEGER,
        last_seen_at INTEGER,
        google_resource_name TEXT,
        pending INTEGER NOT NULL DEFAULT 0,
        removed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (namespace, id)
      )
    ''');
    _createPersonChildTables(batch);
  }

  static void _createPersonChildTables(Batch batch) {
    batch.execute('''
      CREATE TABLE person_place (
        namespace TEXT NOT NULL,
        id TEXT NOT NULL,
        person_id TEXT NOT NULL,
        label TEXT NOT NULL,
        city TEXT NOT NULL,
        region TEXT,
        country TEXT,
        address TEXT,
        latitude REAL,
        longitude REAL,
        is_primary INTEGER NOT NULL DEFAULT 0,
        source TEXT NOT NULL DEFAULT 'MANUAL',
        ord INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (namespace, id)
      )
    ''');
    batch.execute('''
      CREATE TABLE person_channel (
        namespace TEXT NOT NULL,
        id TEXT NOT NULL,
        person_id TEXT NOT NULL,
        kind TEXT NOT NULL,
        label TEXT,
        value TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'MANUAL',
        ord INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (namespace, id)
      )
    ''');
    batch.execute('''
      CREATE TABLE person_note (
        namespace TEXT NOT NULL,
        id TEXT NOT NULL,
        person_id TEXT NOT NULL,
        body TEXT NOT NULL,
        pinned INTEGER NOT NULL DEFAULT 0,
        happened_on TEXT,
        created_at INTEGER NOT NULL,
        ord INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (namespace, id)
      )
    ''');
    batch.execute('''
      CREATE TABLE person_gift (
        namespace TEXT NOT NULL,
        id TEXT NOT NULL,
        person_id TEXT NOT NULL,
        idea TEXT NOT NULL,
        url TEXT,
        given_at INTEGER,
        ord INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (namespace, id)
      )
    ''');
    for (final table in const [
      'person_place',
      'person_channel',
      'person_note',
      'person_gift',
    ]) {
      // Every child read is "this person's rows, in order".
      batch.execute('''
        CREATE INDEX ${table}_by_person
          ON $table (namespace, person_id, ord)
      ''');
    }
  }

  /// Promotes `person` to `person`.
  ///
  /// A rename rather than a new table and a copy: the row already holds the
  /// identity, and every pending write and remap recorded against it has to
  /// survive the upgrade. Dropping and refetching would be simpler and would
  /// silently discard writes a phone had not managed to send yet.
  static void _promotePersonTable(Batch batch, int oldVersion) {
    // A database this new was created by `_createPeopleTables` above, which
    // already made `person` and its children. There is nothing to promote.
    if (oldVersion < 2) return;

    batch.execute('ALTER TABLE money_person RENAME TO person');
    for (final column in const [
      'nickname TEXT',
      'photo_url TEXT',
      'birthday_year INTEGER',
      'birthday_month INTEGER',
      'birthday_day INTEGER',
      'cadence_days INTEGER',
      'last_seen_at INTEGER',
      'google_resource_name TEXT',
    ]) {
      batch.execute('ALTER TABLE person ADD COLUMN $column');
    }
    _createPersonChildTables(batch);
  }

  /// Adds who-was-there to blocks of time already on the device.
  ///
  /// Defaulted rather than backfilled: an entry logged before tagging existed
  /// genuinely has nobody recorded on it, and inventing tags would be worse
  /// than the empty truth.
  static void _addEntryPeople(Batch batch, int oldVersion) {
    // A database this new was created with the column already present.
    if (oldVersion < 4) return;
    batch.execute(
      "ALTER TABLE timeline_entry ADD COLUMN person_ids TEXT NOT NULL DEFAULT '[]'",
    );
  }

  static void _createMoneyTables(Batch batch) {
    batch.execute('''
      CREATE TABLE money_group (
        namespace TEXT NOT NULL,
        id TEXT NOT NULL,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        emoji TEXT,
        ord INTEGER NOT NULL DEFAULT 0,
        archived INTEGER NOT NULL DEFAULT 0,
        pending INTEGER NOT NULL DEFAULT 0,
        removed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (namespace, id)
      )
    ''');
    batch.execute('''
      CREATE TABLE money_group_member (
        namespace TEXT NOT NULL,
        group_id TEXT NOT NULL,
        person_id TEXT NOT NULL,
        PRIMARY KEY (namespace, group_id, person_id)
      )
    ''');
    batch.execute('''
      CREATE TABLE money_expense (
        namespace TEXT NOT NULL,
        id TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        amount_cents INTEGER NOT NULL DEFAULT 0,
        date_key TEXT NOT NULL,
        paid_by TEXT,
        group_id TEXT,
        split_mode TEXT NOT NULL DEFAULT 'EQUAL',
        my_share_cents INTEGER NOT NULL DEFAULT 0,
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        pending INTEGER NOT NULL DEFAULT 0,
        removed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (namespace, id)
      )
    ''');
    // Ordered the way the feed reads: newest bill first.
    batch.execute('''
      CREATE INDEX money_expense_by_date
        ON money_expense (namespace, date_key DESC, created_at DESC, id DESC)
    ''');
    batch.execute('''
      CREATE TABLE money_expense_share (
        namespace TEXT NOT NULL,
        expense_id TEXT NOT NULL,
        person_id TEXT NOT NULL,
        amount_cents INTEGER NOT NULL DEFAULT 0,
        percent_bp INTEGER,
        gifted INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (namespace, expense_id, person_id)
      )
    ''');
    batch.execute('''
      CREATE INDEX money_share_by_person
        ON money_expense_share (namespace, person_id)
    ''');
    batch.execute('''
      CREATE TABLE money_settlement (
        namespace TEXT NOT NULL,
        id TEXT NOT NULL,
        person_id TEXT NOT NULL,
        amount_cents INTEGER NOT NULL DEFAULT 0,
        direction TEXT NOT NULL DEFAULT 'TO_ME',
        date_key TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        pending INTEGER NOT NULL DEFAULT 0,
        removed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (namespace, id)
      )
    ''');
    batch.execute('''
      CREATE INDEX money_settlement_by_person
        ON money_settlement (namespace, person_id)
    ''');
    // Where each collection got to, so a sync resumes rather than restarts.
    batch.execute('''
      CREATE TABLE sync_cursor (
        namespace TEXT NOT NULL,
        collection TEXT NOT NULL,
        cursor TEXT NOT NULL,
        PRIMARY KEY (namespace, collection)
      )
    ''');
  }

  /// The gym log's own rows. Same two sync flags as the money tables.
  ///
  /// A workout's exercises and sets are children of the session and are
  /// replaced with it — there is no such thing as a set that outlives the
  /// workout it was done in, so they carry no flags of their own.
  static void _createGymTables(Batch batch) {
    batch.execute('''
      CREATE TABLE gym_location (
        namespace TEXT NOT NULL,
        id TEXT NOT NULL,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        ord INTEGER NOT NULL DEFAULT 0,
        archived INTEGER NOT NULL DEFAULT 0,
        pending INTEGER NOT NULL DEFAULT 0,
        removed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (namespace, id)
      )
    ''');
    batch.execute('''
      CREATE TABLE gym_exercise (
        namespace TEXT NOT NULL,
        id TEXT NOT NULL,
        name TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        archived INTEGER NOT NULL DEFAULT 0,
        pending INTEGER NOT NULL DEFAULT 0,
        removed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (namespace, id)
      )
    ''');
    batch.execute('''
      CREATE TABLE gym_session (
        namespace TEXT NOT NULL,
        id TEXT NOT NULL,
        date_key TEXT NOT NULL,
        location_id TEXT,
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        pending INTEGER NOT NULL DEFAULT 0,
        removed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (namespace, id)
      )
    ''');
    // Newest workout first, which is how every screen reads them.
    batch.execute('''
      CREATE INDEX gym_session_by_date
        ON gym_session (namespace, date_key DESC, created_at DESC, id DESC)
    ''');
    batch.execute('''
      CREATE TABLE gym_session_exercise (
        namespace TEXT NOT NULL,
        id TEXT NOT NULL,
        session_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        name TEXT NOT NULL,
        ord INTEGER NOT NULL DEFAULT 0,
        raw TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        PRIMARY KEY (namespace, id)
      )
    ''');
    batch.execute('''
      CREATE INDEX gym_session_exercise_by_session
        ON gym_session_exercise (namespace, session_id, ord)
    ''');
    // The history sheet asks "every time I did this", across all workouts.
    batch.execute('''
      CREATE INDEX gym_session_exercise_by_exercise
        ON gym_session_exercise (namespace, exercise_id)
    ''');
    batch.execute('''
      CREATE TABLE gym_set (
        namespace TEXT NOT NULL,
        session_exercise_id TEXT NOT NULL,
        ord INTEGER NOT NULL,
        weight REAL,
        reps INTEGER,
        note TEXT,
        PRIMARY KEY (namespace, session_exercise_id, ord)
      )
    ''');
  }

  /// The timeline's own rows.
  ///
  /// Sleep is kept as the JSON it arrived as, with only the columns a range
  /// query needs pulled out alongside. It has twenty-odd fields, is never
  /// edited on the phone, and is only ever asked for one way — "what happened
  /// between these two days" — so columns for the rest would buy nothing.
  static void _createTimelineTables(Batch batch) {
    batch.execute('''
      CREATE TABLE timeline_category (
        namespace TEXT NOT NULL,
        id TEXT NOT NULL,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        archived INTEGER NOT NULL DEFAULT 0,
        pending INTEGER NOT NULL DEFAULT 0,
        removed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (namespace, id)
      )
    ''');
    batch.execute('''
      CREATE TABLE timeline_entry (
        namespace TEXT NOT NULL,
        id TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        category_id TEXT,
        start_ms INTEGER NOT NULL,
        -- Null is a running timer, not a missing value.
        end_ms INTEGER,
        -- Who was there, as a json array of person ids. A column rather than a
        -- join table: it is read only ever with its entry, it is a handful of
        -- ids, and the server sends it inside the row anyway.
        person_ids TEXT NOT NULL DEFAULT '[]',
        pending INTEGER NOT NULL DEFAULT 0,
        removed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (namespace, id)
      )
    ''');
    // Every read is "the blocks overlapping this stretch of days".
    batch.execute('''
      CREATE INDEX timeline_entry_by_start
        ON timeline_entry (namespace, start_ms)
    ''');
    batch.execute('''
      CREATE TABLE timeline_sleep (
        namespace TEXT NOT NULL,
        id TEXT NOT NULL,
        start_ms INTEGER NOT NULL,
        end_ms INTEGER NOT NULL,
        value TEXT NOT NULL,
        removed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (namespace, id)
      )
    ''');
    batch.execute('''
      CREATE INDEX timeline_sleep_by_start
        ON timeline_sleep (namespace, start_ms)
    ''');
  }

  /// Ids this device invented that the server replaced with its own.
  ///
  /// The server identifies some rows by name rather than by id — a person, a
  /// category, a gym — so creating one it already has answers with the row it
  /// already has, under a different id. Everything queued and everything
  /// stored is repointed when that happens, but a screen may still be holding
  /// the id it was handed a moment earlier. This is how that id is still
  /// understood afterwards.
  static void _createRemapTable(Batch batch) {
    batch.execute('''
      CREATE TABLE id_remap (
        namespace TEXT NOT NULL,
        kind TEXT NOT NULL,
        from_id TEXT NOT NULL,
        to_id TEXT NOT NULL,
        PRIMARY KEY (namespace, kind, from_id)
      )
    ''');
  }

  Future<void> recordRemap({
    required String namespace,
    required String kind,
    required String from,
    required String to,
    DatabaseExecutor? txn,
  }) async {
    final db = txn ?? await _db;
    // Anything that already pointed at the old id now points at the new one,
    // so a chain never grows longer than one link.
    await db.update(
      'id_remap',
      {'to_id': to},
      where: 'namespace = ? AND kind = ? AND to_id = ?',
      whereArgs: [namespace, kind, from],
    );
    await db.insert('id_remap', {
      'namespace': namespace,
      'kind': kind,
      'from_id': from,
      'to_id': to,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// What [id] became, or [id] itself when nothing renamed it.
  Future<String> resolveId({
    required String namespace,
    required String kind,
    required String id,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'id_remap',
      columns: ['to_id'],
      where: 'namespace = ? AND kind = ? AND from_id = ?',
      whereArgs: [namespace, kind, id],
      limit: 1,
    );
    return rows.isEmpty ? id : rows.first['to_id']! as String;
  }

  /// Runs [work] against the database in one transaction.
  ///
  /// The reason the whole store is one file: a write applies to the money
  /// tables and lands in the outbox together, or neither happens.
  Future<T> transaction<T>(Future<T> Function(Transaction txn) work) async =>
      (await _db).transaction(work);

  Future<Database> get database => _db;

  Future<String?> readDocument({
    required String namespace,
    required String collection,
    required String key,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'documents',
      columns: ['value'],
      where: 'namespace = ? AND collection = ? AND key = ?',
      whereArgs: [namespace, collection, key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> writeDocument({
    required String namespace,
    required String collection,
    required String key,
    required String value,
  }) async {
    final db = await _db;
    await db.insert('documents', {
      'namespace': namespace,
      'collection': collection,
      'key': key,
      'value': value,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeDocument({
    required String namespace,
    required String collection,
    required String key,
  }) async {
    final db = await _db;
    await db.delete(
      'documents',
      where: 'namespace = ? AND collection = ? AND key = ?',
      whereArgs: [namespace, collection, key],
    );
  }

  /// Drops all but the [keep] most recently written documents in a collection.
  ///
  /// This is what stops a cache of individually addressed things — workouts
  /// opened one after another — from growing for ever.
  Future<void> trimDocuments({
    required String namespace,
    required String collection,
    required int keep,
  }) async {
    final db = await _db;
    await db.rawDelete(
      '''
      DELETE FROM documents
       WHERE namespace = ? AND collection = ?
         AND key NOT IN (
           SELECT key FROM documents
            WHERE namespace = ? AND collection = ?
            ORDER BY updated_at DESC, rowid DESC
            LIMIT ?
         )
      ''',
      [namespace, collection, namespace, collection, keep],
    );
  }

  /// The collection's rows, oldest first.
  Future<List<String>> readRecords({
    required String namespace,
    required String collection,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'records',
      columns: ['value'],
      where: 'namespace = ? AND collection = ?',
      whereArgs: [namespace, collection],
      orderBy: 'seq ASC',
    );
    return [for (final row in rows) row['value'] as String];
  }

  /// Replaces a collection wholesale, in one transaction.
  ///
  /// Whole-list rather than append-only because folding a queue rewrites what
  /// is already in it: an edit to an unsent row changes that row rather than
  /// adding to it. Doing it in a transaction is what makes that safe — the
  /// queue on disk is either the old one or the new one, never a torn mixture
  /// of the two, which is precisely what a single rewritten JSON blob could
  /// not guarantee.
  Future<void> replaceRecords({
    required String namespace,
    required String collection,
    required List<String> values,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'records',
        where: 'namespace = ? AND collection = ?',
        whereArgs: [namespace, collection],
      );
      final batch = txn.batch();
      for (final value in values) {
        batch.insert('records', {
          'namespace': namespace,
          'collection': collection,
          'value': value,
        });
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> close() async {
    final opened = _database;
    _database = null;
    if (opened != null) await (await opened).close();
  }
}
