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

  static const _version = 2;

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
        _createMoneyTables(batch);
        await batch.commit();
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        final batch = db.batch();
        if (oldVersion < 2) _createMoneyTables(batch);
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
  static void _createMoneyTables(Batch batch) {
    batch.execute('''
      CREATE TABLE money_person (
        namespace TEXT NOT NULL,
        id TEXT NOT NULL,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        emoji TEXT,
        default_percent INTEGER,
        ord INTEGER NOT NULL DEFAULT 0,
        archived INTEGER NOT NULL DEFAULT 0,
        pending INTEGER NOT NULL DEFAULT 0,
        removed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (namespace, id)
      )
    ''');
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
