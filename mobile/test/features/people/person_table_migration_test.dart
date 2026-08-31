import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/core/storage/luqa_store.dart';
import 'package:luqa/features/money/data/money_local_store.dart';
import 'package:luqa/features/people/domain/person.dart';
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

  /// A database as version 4 left it: `money_person` with the money columns
  /// only, and a row on it this device had not managed to send.
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
}
