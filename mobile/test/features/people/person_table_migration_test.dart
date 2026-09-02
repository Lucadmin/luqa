import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/core/storage/luqa_store.dart';
import 'package:luqa/features/money/data/money_local_store.dart';
import 'package:luqa/features/people/domain/person.dart';
import 'package:luqa/features/today/data/timeline_local_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Upgrading to the People release must not lose anybody.
///
/// The person table was renamed from `money_person` and grew eight columns.
/// A rename was chosen over a drop-and-refetch precisely so that pending
/// writes survive — a phone that has been offline for a week is holding rows
/// the server has never seen, and a migration that discarded them would be
/// deleting the user's work to save a schema step.
void main() {
  sqfliteFfiInit();

  /// A database as version 4 left it.
  ///
  /// Only the tables the migrations under test touch, so this stays readable —
  /// which means any future migration that alters a table has to add it here
  /// too, or it fails against this fixture rather than against a real phone.
  Future<void> seedVersion4(String path) async {
    // A real file, not :memory:, because the point is reopening it. Cleared
    // first so a leftover from the last run cannot make this pass or fail for
    // the wrong reason.
    await databaseFactoryFfi.deleteDatabase(path);
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
          await db.execute('''
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
          // Version 4 created this without `person_ids`; adding that column
          // is the other half of the upgrade being tested.
          await db.execute('''
            CREATE TABLE timeline_entry (
              namespace TEXT NOT NULL,
              id TEXT NOT NULL,
              description TEXT NOT NULL DEFAULT '',
              category_id TEXT,
              start_ms INTEGER NOT NULL,
              end_ms INTEGER,
              pending INTEGER NOT NULL DEFAULT 0,
              removed INTEGER NOT NULL DEFAULT 0,
              PRIMARY KEY (namespace, id)
            )
          ''');
          // Version 4 had the gym tables (they arrived at 3) but not the two
          // columns that say when a workout stopped. Present here so the
          // migration that adds them is exercised against a real table.
          await db.execute('''
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
          await db.insert('gym_session', {
            'namespace': 'user-a',
            'id': 'leg-day',
            'date_key': '2026-08-26',
            'location_id': null,
            'notes': '',
            'created_at': DateTime.utc(2026, 8, 26, 17).toIso8601String(),
            'pending': 0,
            'removed': 0,
          });
          await db.insert('timeline_entry', {
            'namespace': 'user-a',
            'id': 'dinner',
            'description': 'Dinner',
            'category_id': null,
            'start_ms': DateTime(2026, 8, 27, 19).millisecondsSinceEpoch,
            'end_ms': DateTime(2026, 8, 27, 21).millisecondsSinceEpoch,
            'pending': 0,
            'removed': 0,
          });
          await db.insert('money_person', {
            'namespace': 'user-a',
            'id': 'mira',
            'name': 'Mira Hensel',
            'color': 0xFFBE185D,
            'emoji': '🧡',
            'default_percent': 30,
            'ord': 2,
            'archived': 0,
            // Never sent. The whole reason this is a rename.
            'pending': 1,
            'removed': 0,
          });
        },
      ),
    );
    await db.close();
  }

  test('people survive the upgrade, pending writes included', () async {
    final path = 'person_migration_a.db';
    await seedVersion4(path);

    // Reopening through LuqaStore runs the upgrade to version 5.
    final store = LuqaStore(factory: databaseFactoryFfi, path: path);
    addTearDown(store.close);
    final local = MoneyLocalStore(namespace: 'user-a', store: store);

    final people = await local.people();
    expect(people, hasLength(1));

    final mira = people.single;
    expect(mira.name, 'Mira Hensel');
    expect(mira.emoji, '🧡');
    expect(mira.defaultPercent, 30);
    expect(mira.order, 2);

    // The profile columns are simply empty, which is a complete person.
    expect(mira.birthday, isNull);
    expect(mira.cadenceDays, isNull);
    expect(mira.notes, isEmpty);
    expect(mira.places, isEmpty);
  });

  test('the unsent flag survives, so the delta cannot overwrite the row',
      () async {
    final path = 'person_migration_b.db';
    await seedVersion4(path);

    final store = LuqaStore(factory: databaseFactoryFfi, path: path);
    addTearDown(store.close);
    final local = MoneyLocalStore(namespace: 'user-a', store: store);

    // A delta arriving with the server's older copy must leave the local row
    // alone while the write is still pending — that flag is what says so, and
    // losing it in the migration would silently revert the user's edit.
    await local.applyPeople([
      (await local.people()).single.copyWith(name: 'Stale Server Name'),
    ], const []);

    expect((await local.people()).single.name, 'Mira Hensel');
  });

  test('the profile tables are there to write into after the upgrade',
      () async {
    final path = 'person_migration_c.db';
    await seedVersion4(path);

    final store = LuqaStore(factory: databaseFactoryFfi, path: path);
    addTearDown(store.close);
    final local = MoneyLocalStore(namespace: 'user-a', store: store);

    final mira = (await local.people()).single;
    await local.putPerson(
      mira.copyWith(
        notes: [
          PersonNote(id: 'n1', body: 'Ceramics course', createdAt: DateTime(2026, 8, 27)),
        ],
      ),
    );

    expect((await local.people()).single.notes.single.body, 'Ceramics course');
  });

  test('blocks of time logged before tagging existed keep no tags', () async {
    final path = 'person_migration_d.db';
    await seedVersion4(path);

    final store = LuqaStore(factory: databaseFactoryFfi, path: path);
    addTearDown(store.close);
    final timeline = TimelineLocalStore(namespace: 'user-a', store: store);

    // Defaulted rather than backfilled: an entry logged before anyone could be
    // tagged genuinely has nobody on it, and inventing names would be worse
    // than the empty truth.
    final entry = await timeline.entryById('dinner');
    expect(entry, isNotNull);
    expect(entry!.description, 'Dinner');
    expect(entry.personIds, isEmpty);
  });
}
