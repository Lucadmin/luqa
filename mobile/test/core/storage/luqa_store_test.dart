import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/core/storage/luqa_store.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/today/data/outbox.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _at = DateTime.utc(2026, 8, 31, 9);

TimeEntry _entry(String id) => TimeEntry(
  id: id,
  description: 'Writing',
  categoryId: null,
  start: DateTime.utc(2026, 8, 31, 10),
  end: DateTime.utc(2026, 8, 31, 11),
);

void main() {
  sqfliteFfiInit();

  LuqaStore freshStore() {
    final store = LuqaStore(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    addTearDown(store.close);
    return store;
  }

  group('documents', () {
    test('round-trip, and absence reads as null', () async {
      final store = freshStore();

      expect(
        await store.readDocument(namespace: 'a', collection: 'c', key: 'k'),
        isNull,
      );

      await store.writeDocument(
        namespace: 'a',
        collection: 'c',
        key: 'k',
        value: '{"n":1}',
      );

      expect(
        await store.readDocument(namespace: 'a', collection: 'c', key: 'k'),
        '{"n":1}',
      );
    });

    test('a write replaces rather than duplicating', () async {
      final store = freshStore();
      for (final value in ['first', 'second']) {
        await store.writeDocument(
          namespace: 'a',
          collection: 'c',
          key: 'k',
          value: value,
        );
      }

      expect(
        await store.readDocument(namespace: 'a', collection: 'c', key: 'k'),
        'second',
      );
    });

    test('one user cannot read another user', () async {
      final store = freshStore();
      await store.writeDocument(
        namespace: 'user-a',
        collection: 'money',
        key: 'overview',
        value: 'private',
      );

      expect(
        await store.readDocument(
          namespace: 'user-b',
          collection: 'money',
          key: 'overview',
        ),
        isNull,
      );
    });

    test('the same key in two collections is two documents', () async {
      final store = freshStore();
      await store.writeDocument(
        namespace: 'a',
        collection: 'gym',
        key: 'overview',
        value: 'gym',
      );
      await store.writeDocument(
        namespace: 'a',
        collection: 'money',
        key: 'overview',
        value: 'money',
      );

      expect(
        await store.readDocument(
          namespace: 'a',
          collection: 'gym',
          key: 'overview',
        ),
        'gym',
      );
    });

    test('trimming keeps the most recently written', () async {
      final store = freshStore();
      for (final key in ['one', 'two', 'three']) {
        await store.writeDocument(
          namespace: 'a',
          collection: 'gym.sessions',
          key: key,
          value: key,
        );
      }

      await store.trimDocuments(
        namespace: 'a',
        collection: 'gym.sessions',
        keep: 2,
      );

      expect(
        await store.readDocument(
          namespace: 'a',
          collection: 'gym.sessions',
          key: 'one',
        ),
        isNull,
      );
      expect(
        await store.readDocument(
          namespace: 'a',
          collection: 'gym.sessions',
          key: 'three',
        ),
        'three',
      );
    });
  });

  group('records', () {
    test('come back in the order they were written', () async {
      final store = freshStore();
      await store.replaceRecords(
        namespace: 'a',
        collection: 'outbox.timeline',
        values: ['one', 'two', 'three'],
      );

      expect(
        await store.readRecords(
          namespace: 'a',
          collection: 'outbox.timeline',
        ),
        ['one', 'two', 'three'],
      );
    });

    test('a replace leaves nothing of the list it replaced', () async {
      final store = freshStore();
      await store.replaceRecords(
        namespace: 'a',
        collection: 'outbox.timeline',
        values: ['one', 'two', 'three'],
      );
      await store.replaceRecords(
        namespace: 'a',
        collection: 'outbox.timeline',
        values: ['only'],
      );

      expect(
        await store.readRecords(
          namespace: 'a',
          collection: 'outbox.timeline',
        ),
        ['only'],
      );
    });

    test('emptying a queue empties only that queue', () async {
      final store = freshStore();
      await store.replaceRecords(
        namespace: 'a',
        collection: 'outbox.timeline',
        values: ['timeline'],
      );
      await store.replaceRecords(
        namespace: 'a',
        collection: 'outbox.money',
        values: ['money'],
      );

      await store.replaceRecords(
        namespace: 'a',
        collection: 'outbox.timeline',
        values: const [],
      );

      expect(
        await store.readRecords(namespace: 'a', collection: 'outbox.money'),
        ['money'],
      );
    });
  });

  group('the outbox on top of it', () {
    test('a queued write survives being read back', () async {
      final store = freshStore();
      final outbox = SqliteOutbox<TimelineMutation>(
        key: 'timeline',
        namespace: 'user-a',
        decode: TimelineMutation.fromJson,
        store: store,
      );

      await outbox.write([
        CreateEntry(entry: _entry('one'), queuedAt: _at),
        DeleteEntry(entryId: 'two', queuedAt: _at),
      ]);

      final restored = await outbox.read();
      expect(restored, hasLength(2));
      expect((restored.first as CreateEntry).entry.id, 'one');
      expect((restored.last as DeleteEntry).entryId, 'two');
    });

    test('one unreadable row costs one write, not the queue', () async {
      final store = freshStore();
      // What a torn or half-migrated row would look like. Under a single JSON
      // blob this took every queued write with it.
      await store.replaceRecords(
        namespace: 'user-a',
        collection: 'outbox.timeline',
        values: [
          'not json at all',
          jsonEncode(CreateEntry(entry: _entry('kept'), queuedAt: _at).toJson()),
        ],
      );

      final outbox = SqliteOutbox<TimelineMutation>(
        key: 'timeline',
        namespace: 'user-a',
        decode: TimelineMutation.fromJson,
        store: store,
      );

      final restored = await outbox.read();
      expect(restored, hasLength(1));
      expect((restored.single as CreateEntry).entry.id, 'kept');
    });

    test('one user never drains another user queue', () async {
      final store = freshStore();
      SqliteOutbox<TimelineMutation> outboxFor(String namespace) =>
          SqliteOutbox<TimelineMutation>(
            key: 'timeline',
            namespace: namespace,
            decode: TimelineMutation.fromJson,
            store: store,
          );

      await outboxFor(
        'user-a',
      ).write([CreateEntry(entry: _entry('a'), queuedAt: _at)]);

      expect(await outboxFor('user-b').read(), isEmpty);
    });
  });

  group('the discard log', () {
    test('keeps at most twenty notices, newest first', () async {
      final log = SqliteDiscardLog(
        key: 'timeline',
        namespace: 'user-a',
        store: freshStore(),
      );

      await log.write([
        for (var i = 0; i < 25; i++)
          DiscardedWrite(
            description: 'write $i',
            reason: 'refused',
            discardedAt: _at,
          ),
      ]);

      final kept = await log.read();
      expect(kept, hasLength(20));
      expect(kept.first.description, 'write 0');
    });
  });

  group('what earlier builds left in shared preferences', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });
    tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

    test('a queue is carried across rather than lost', () async {
      // A namespace of its own per test: the migration runs once per
      // namespace per launch, by design.
      const namespace = 'legacy-user';
      final legacyKey =
          'luqa.outbox.timeline.v1.'
          '${base64Url.encode(utf8.encode(namespace))}';
      await SharedPreferencesAsync().setString(
        legacyKey,
        jsonEncode([
          CreateEntry(entry: _entry('queued-offline'), queuedAt: _at).toJson(),
        ]),
      );

      final restored = await SqliteOutbox<TimelineMutation>(
        key: 'timeline',
        namespace: namespace,
        decode: TimelineMutation.fromJson,
        store: freshStore(),
      ).read();

      expect(restored, hasLength(1));
      expect((restored.single as CreateEntry).entry.id, 'queued-offline');
      // Carried, not copied: a second launch must not resurrect it.
      expect(await SharedPreferencesAsync().getString(legacyKey), isNull);
    });

    test('a legacy blob that will not parse is simply dropped', () async {
      const namespace = 'legacy-corrupt';
      await SharedPreferencesAsync().setString(
        'luqa.outbox.timeline.v1.'
        '${base64Url.encode(utf8.encode(namespace))}',
        'not json at all',
      );

      final restored = await SqliteOutbox<TimelineMutation>(
        key: 'timeline',
        namespace: namespace,
        decode: TimelineMutation.fromJson,
        store: freshStore(),
      ).read();

      expect(restored, isEmpty);
    });
  });
}
