import 'package:luqa/core/storage/luqa_store.dart';
import 'package:luqa/features/today/data/timeline_local_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/today/application/sync_engine.dart';
import 'package:luqa/features/today/application/timeline_controller.dart';
import 'package:luqa/features/today/data/remote_today_repository.dart';
import 'package:luqa/features/today/data/today_providers.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

import '../../helpers/pump_luqa.dart';
import 'sync_engine_harness.dart';
import '../../helpers/test_store.dart';

/// The whole stack, minus the widget tree: a real controller over a real
/// local-first repository over a real sync engine, with only the network faked.
class _Stack {
  _Stack({bool offline = false, List<TimeEntry> seed = const []}) {
    api.entries.addAll(seed);
    api.offline = offline;
    final remote = RemoteTodayRepository(client: api);
    store = openTestStore();
    local = TimelineLocalStore(namespace: 'user-a', store: store);
    // Seeded the way a completed sync would have left the device, since reads
    // come from here now rather than from the server.
    _seeded = local.applyEntries(seed, const []);
    container = ProviderContainer(
      overrides: [
        remoteTodayRepositoryProvider.overrideWithValue(remote),
        timelineLocalStoreProvider.overrideWithValue(local),
        outboxProvider.overrideWithValue(outbox),
        currentTimeProvider.overrideWithValue(fixedNow),
        authControllerProvider.overrideWith(FixedAuthController.new),
      ],
    );
    // autoDispose: without a listener the controller is thrown away between
    // reads and never finishes its first load.
    container.listen(timelineControllerProvider, (_, _) {});
  }

  final FakeApi api = FakeApi();
  final MemoryOutbox outbox = MemoryOutbox();
  late final LuqaStore store;
  late final TimelineLocalStore local;
  late final Future<void> _seeded;
  late final ProviderContainer container;

  TimelineController get controller =>
      container.read(timelineControllerProvider.notifier);

  TimelineState get state => container.read(timelineControllerProvider);

  /// Waits for the controller to finish whatever it is doing.
  ///
  /// Deliberately a condition rather than a fixed number of turns of the event
  /// loop. Eight turns happened to be enough on an idle machine and not enough
  /// on a busy one, which is how a suite ends up with one test in five failing
  /// for no reason anybody can reproduce.
  Future<void> settle() async {
    await _seeded;
    await pump(() => !state.isLoading && !state.isRefreshing);
  }

  /// Turns the event loop until [done], or gives up loudly.
  ///
  /// Giving up loudly matters: a silent timeout would turn "the controller
  /// never finished" into whatever assertion happened to come next, which is
  /// the hardest kind of failure to read.
  Future<void> pump(bool Function() done, {int limit = 200}) async {
    for (var turn = 0; turn < limit; turn++) {
      if (done()) return;
      await Future<void>.delayed(Duration.zero);
    }
    throw StateError('The timeline never settled after $limit turns');
  }

  /// Awaited rather than fired and forgotten: every stack opens the same
  /// in-memory database, so a close still in flight when the next test opens
  /// its own is the next test reading somebody else's rows.
  Future<void> dispose() async {
    container.dispose();
    await store.close();
  }
}

final _writing = TimeEntry(
  id: 'server-1',
  description: 'Writing',
  categoryId: null,
  start: DateTime(2026, 8, 27, 9),
  end: DateTime(2026, 8, 27, 10),
);

void main() {
  sqfliteFfiInit();

  test(
    'a block drawn with no network is on the timeline immediately',
    () async {
      final stack = _Stack(offline: true);
      addTearDown(stack.dispose);
      await stack.settle();

      stack.controller.beginDraft(
        DateTime(2026, 8, 27, 14),
        DateTime(2026, 8, 27, 15),
      );
      stack.controller.describeDraft('Reading');
      final saved = await stack.controller.commitDraft();

      expect(saved, isTrue);
      expect(stack.state.draft, isNull, reason: 'the composer should close');
      expect(stack.state.error, isNull);
      expect(
        stack.state.entries.map((entry) => entry.description),
        contains('Reading'),
      );
      expect(stack.state.pendingWrites, 1);
    },
  );

  test('a block drawn offline is still there after a reload', () async {
    final stack = _Stack(offline: true);
    addTearDown(stack.dispose);
    await stack.settle();

    stack.controller.beginDraft(
      DateTime(2026, 8, 27, 14),
      DateTime(2026, 8, 27, 15),
    );
    stack.controller.describeDraft('Reading');
    await stack.controller.commitDraft();

    await stack.controller.refresh();
    await stack.settle();

    expect(
      stack.state.entries.map((entry) => entry.description),
      contains('Reading'),
    );
  });

  test('the block reaches the server under the id it was given', () async {
    final stack = _Stack();
    addTearDown(stack.dispose);
    await stack.settle();

    stack.controller.beginDraft(
      DateTime(2026, 8, 27, 14),
      DateTime(2026, 8, 27, 15),
    );
    stack.controller.describeDraft('Reading');
    await stack.controller.commitDraft();
    await stack.container.read(syncEngineProvider.notifier).sync();

    final local = stack.state.entries.firstWhere(
      (entry) => entry.description == 'Reading',
    );
    expect(stack.api.created.single.id, local.id);
    expect(stack.state.pendingWrites, 0);
  });

  test('a timer starts without waiting for the server', () async {
    final stack = _Stack(offline: true);
    addTearDown(stack.dispose);
    await stack.settle();

    final started = await stack.controller.startTimer(description: 'Thesis');

    expect(started, isTrue);
    expect(stack.state.runningEntry?.description, 'Thesis');
    expect(stack.state.error, isNull);
  });

  test(
    'a category invented offline can be used on a block right away',
    () async {
      final stack = _Stack(offline: true);
      addTearDown(stack.dispose);
      await stack.settle();

      final category = await stack.controller.addCategory('Admin');

      expect(category, isNotNull);
      expect(stack.state.categoryById(category!.id)?.name, 'Admin');
    },
  );

  test('an edit made offline survives being reloaded', () async {
    final stack = _Stack(seed: [_writing]);
    addTearDown(stack.dispose);
    await stack.settle();
    expect(stack.state.entries, hasLength(1));

    stack.api.offline = true;
    await stack.controller.editEntry(
      'server-1',
      const EntryPatch(description: 'Editing'),
    );
    await stack.controller.refresh();
    await stack.settle();

    expect(stack.state.entries.single.description, 'Editing');
    expect(stack.state.entries.single.pendingSync, isTrue);
  });

  test('once the edit lands, the server copy is what is shown', () async {
    final stack = _Stack(seed: [_writing]);
    addTearDown(stack.dispose);
    await stack.settle();

    await stack.controller.editEntry(
      'server-1',
      const EntryPatch(description: 'Editing'),
    );
    await stack.controller.refresh();
    await stack.settle();

    expect(stack.state.entries.single.description, 'Editing');
    expect(stack.state.entries.single.pendingSync, isFalse);
    expect(stack.state.pendingWrites, 0);
  });

  test('categories offered to the picker include the unsent one', () async {
    final stack = _Stack(offline: true);
    addTearDown(stack.dispose);
    await stack.settle();

    await stack.controller.addCategory('Admin');
    await stack.controller.refresh();
    await stack.settle();

    expect(
      stack.state.categories.map((Category value) => value.name),
      contains('Admin'),
    );
  });
}
