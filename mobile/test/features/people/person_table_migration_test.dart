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

  test(
    'the unsent flag survives, so the delta cannot overwrite the row',
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
    },
  );

  test(
    'the profile tables are there to write into after the upgrade',
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
            PersonNote(
              id: 'n1',
              body: 'Ceramics course',
              createdAt: DateTime(2026, 8, 27),
            ),
          ],
        ),
      );

      expect(
        (await local.people()).single.notes.single.body,
        'Ceramics course',
      );
    },
  );

  /// A database as version 9 left it: `person_place` exists, and its rows are
  /// cities that were typed rather than chosen.
  ///
  /// Only the one table, and only the columns the migration under test cares
  /// about — a version-4 fixture cannot exercise this path at all, because on
  /// the way up from 4 the table is created fresh with the new columns already
  /// on it.
  Future<void> seedVersion9(String path) async {
    await databaseFactoryFfi.deleteDatabase(path);
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 9,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE person (
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
              nickname TEXT,
              photo_url TEXT,
              birthday_year INTEGER,
              birthday_month INTEGER,
              birthday_day INTEGER,
              cadence_days INTEGER,
              last_seen_at INTEGER,
              google_resource_name TEXT,
              PRIMARY KEY (namespace, id)
            )
          ''');
          // Version 9's shape: no city_id, no timezone.
          await db.execute('''
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
          for (final table in const [
            'person_channel',
            'person_note',
            'person_gift',
          ]) {
            await db.execute('''
              CREATE TABLE $table (
                namespace TEXT NOT NULL,
                id TEXT NOT NULL,
                person_id TEXT NOT NULL,
                ord INTEGER NOT NULL DEFAULT 0,
                PRIMARY KEY (namespace, id)
              )
            ''');
          }
          await db.insert('person', {
            'namespace': 'user-a',
            'id': 'jonas',
            'name': 'Jonas Weber',
            'color': 0xFF6366F1,
            'ord': 0,
            'archived': 0,
            'pending': 0,
            'removed': 0,
          });
          await db.insert('person_place', {
            'namespace': 'user-a',
            'id': 'p1',
            'person_id': 'jonas',
            'label': 'Home',
            'city': 'Hamburg',
            'country': 'DE',
            'latitude': 53.55,
            'longitude': 9.99,
            'is_primary': 1,
            'source': 'MANUAL',
            'ord': 0,
          });
        },
      ),
    );
    await db.close();
  }

  test('a city typed before anyone could choose one keeps its pin', () async {
    final path = 'person_migration_e.db';
    await seedVersion9(path);

    final store = LuqaStore(factory: databaseFactoryFfi, path: path);
    addTearDown(store.close);
    final local = MoneyLocalStore(namespace: 'user-a', store: store);

    final place = (await local.people()).single.places.single;
    expect(place.city, 'Hamburg');
    expect(place.latitude, 53.55);
    // Null rather than guessed: nothing already on this device was picked from
    // a list, and saying otherwise would claim a choice nobody made.
    expect(place.cityId, isNull);
    expect(place.timezone, isNull);
    // Which means it still groups by name, as it did before.
    expect(place.cityKey, 'name:hamburg');
  });

  test(
    'an existing person upgrades with no invented relationship data',
    () async {
      final path = 'person_migration_connections.db';
      await seedVersion9(path);

      final store = LuqaStore(factory: databaseFactoryFfi, path: path);
      addTearDown(store.close);
      final local = MoneyLocalStore(namespace: 'user-a', store: store);

      final person = (await local.people()).single;
      expect(person.closeness, isNull);
      expect(person.connections, isEmpty);

      await local.putPerson(
        person.copyWith(
          closeness: Closeness.close,
          connections: const [
            PersonConnection(personId: 'mira', closeness: Closeness.inMyLife),
          ],
        ),
      );
      final written = (await local.people()).single;
      expect(written.closeness, Closeness.close);
      expect(written.connections.single.personId, 'mira');
    },
  );

  test('a chosen city can be written into the upgraded table', () async {
    final path = 'person_migration_f.db';
    await seedVersion9(path);

    final store = LuqaStore(factory: databaseFactoryFfi, path: path);
    addTearDown(store.close);
    final local = MoneyLocalStore(namespace: 'user-a', store: store);

    final jonas = (await local.people()).single;
    await local.putPerson(
      jonas.copyWith(
        places: [
          const PersonPlace(
            id: 'p2',
            label: 'Parents',
            city: 'Cambridge',
            region: 'Massachusetts',
            country: 'US',
            cityId: 4931972,
            timezone: 'America/New_York',
            latitude: 42.3751,
            longitude: -71.1056,
          ),
        ],
      ),
    );

    final place = (await local.people()).single.places.single;
    expect(place.cityId, 4931972);
    expect(place.timezone, 'America/New_York');
    expect(place.cityKey, 'id:4931972');
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
