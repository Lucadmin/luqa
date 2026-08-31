import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/today/application/sync_engine.dart';
import 'package:luqa/features/today/data/local_first_today_repository.dart';
import 'package:luqa/features/today/data/outbox.dart';
import 'package:luqa/features/today/data/remote_today_repository.dart';
import 'package:luqa/features/today/data/today_providers.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

import 'package:luqa/core/sync/outbox.dart';

import 'sync_engine_harness.dart';

void main() {
  test(
    'a write is recorded and answered without touching the network',
    () async {
      final harness = _Harness()..api.offline = true;
      addTearDown(harness.dispose);

      final created = await harness.repository.addEntry(
        NewTimeEntry(
          description: 'Reading',
          categoryId: null,
          start: DateTime.utc(2026, 8, 31, 10),
          end: DateTime.utc(2026, 8, 31, 11),
        ),
      );

      expect(created.id, isNotEmpty);
      expect(created.pendingSync, isTrue);
      expect(harness.engine.pending, hasLength(1));
      expect(harness.api.created, isEmpty);
    },
  );

  test('the queue drains once the network comes back', () async {
    final harness = _Harness()..api.offline = true;
    addTearDown(harness.dispose);

    await harness.repository.addEntry(_draft('Reading'));
    await harness.engine.sync();
    expect(harness.engine.pending, hasLength(1));

    harness.api.offline = false;
    await harness.engine.sync();

    expect(harness.engine.pending, isEmpty);
    expect(harness.api.created.single.description, 'Reading');
    expect(harness.container.read(syncEngineProvider).pending, 0);
  });

  test(
    'the id the device minted is the id the server is told to use',
    () async {
      final harness = _Harness();
      addTearDown(harness.dispose);

      final created = await harness.repository.addEntry(_draft('Reading'));
      await harness.engine.sync();

      expect(harness.api.created.single.id, created.id);
    },
  );

  test('a write made before a restart is sent on the next launch', () async {
    final outbox = MemoryOutbox();
    final first = _Harness(outbox: outbox)..api.offline = true;
    await first.repository.addEntry(_draft('Reading'));
    await first.engine.sync();
    first.dispose();
    expect(outbox.stored, hasLength(1));

    final second = _Harness(outbox: outbox);
    addTearDown(second.dispose);
    await second.engine.ready;
    await second.engine.sync();

    expect(second.api.created.single.description, 'Reading');
    expect(outbox.stored, isEmpty);
  });

  test(
    'a refused write is dropped so the ones behind it can through',
    () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      // The server has never heard of this row, and never will.
      harness.api.rejectDeleteOf = 'ghost';

      await harness.repository.deleteEntry('ghost');
      await harness.repository.addEntry(_draft('Reading'));
      await harness.engine.sync();

      expect(harness.engine.pending, isEmpty);
      expect(harness.api.created.single.description, 'Reading');
    },
  );

  test(
    'a transport failure keeps the queue instead of discarding it',
    () async {
      final harness = _Harness()..api.offline = true;
      addTearDown(harness.dispose);

      await harness.repository.addEntry(_draft('Reading'));
      await harness.engine.sync();

      expect(harness.engine.pending, hasLength(1));
      expect(harness.container.read(syncEngineProvider).pending, 1);
    },
  );

  test(
    'a block drawn and undone offline is never mentioned to the server',
    () async {
      final harness = _Harness()..api.offline = true;
      addTearDown(harness.dispose);

      final created = await harness.repository.addEntry(_draft('Reading'));
      await harness.repository.deleteEntry(created.id);
      harness.api.offline = false;
      await harness.engine.sync();

      expect(harness.api.created, isEmpty);
      expect(harness.api.deleted, isEmpty);
      expect(harness.engine.pending, isEmpty);
    },
  );

  test('a delete of an already-sent block is still sent', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);

    final created = await harness.repository.addEntry(_draft('Reading'));
    await harness.engine.sync();
    await harness.repository.deleteEntry(created.id);
    await harness.engine.sync();

    expect(harness.api.created.single.id, created.id);
    expect(harness.api.deleted, [created.id]);
  });

  test('entries follow a category to whatever id the server gave it', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    // The name already exists server-side under a different id.
    harness.api.categoryIdForName['Admin'] = 'server-admin';

    final category = await harness.repository.addCategory('Admin');
    await harness.repository.addEntry(
      _draft('Invoices', categoryId: category.id),
    );
    await harness.engine.sync();

    expect(harness.api.created.single.categoryId, 'server-admin');
  });

  test(
    'a completed round is announced so screens can pull the truth down',
    () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      final before = harness.container.read(syncEngineProvider).rounds;

      await harness.repository.addEntry(_draft('Reading'));
      await harness.engine.sync();

      expect(
        harness.container.read(syncEngineProvider).rounds,
        greaterThan(before),
      );
    },
  );
}

NewTimeEntry _draft(String description, {String? categoryId}) => NewTimeEntry(
  description: description,
  categoryId: categoryId,
  start: DateTime.utc(2026, 8, 31, 10),
  end: DateTime.utc(2026, 8, 31, 11),
);

class _Harness {
  _Harness({Outbox<TimelineMutation>? outbox}) {
    final remote = RemoteTodayRepository(client: api, cache: MemoryCache());
    container = ProviderContainer(
      overrides: [
        remoteTodayRepositoryProvider.overrideWithValue(remote),
        outboxProvider.overrideWithValue(outbox ?? MemoryOutbox()),
        discardLogProvider.overrideWithValue(const NullDiscardLog()),
      ],
    );
    engine = container.read(syncEngineProvider.notifier);
    repository = LocalFirstTodayRepository(remote: remote, queue: engine);
  }

  final FakeApi api = FakeApi();
  late final ProviderContainer container;
  late final SyncEngine engine;
  late final LocalFirstTodayRepository repository;

  void dispose() => container.dispose();
}
