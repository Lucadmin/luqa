import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/auth/data/secure_credential_store.dart';
import 'package:luqa/features/today/data/remote_today_repository.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa_api/api.dart' as api;
import 'package:luqa/core/storage/luqa_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  final from = DateTime(2026, 8, 17);
  final to = DateTime(2026, 9, 7);

  sqfliteFfiInit();

  /// A database per test, held only in memory, so the persistent caches can be
  /// exercised for real without a device or a file to clean up.
  LuqaStore freshStore() {
    final store = LuqaStore(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    addTearDown(store.close);
    return store;
  }

  test('loadWindow maps entries and sleep, then caches the window', () async {
    final cache = MemoryTimelineCache();
    final api = FakeLuqaApi();
    final repository = RemoteTodayRepository(client: api, cache: cache);

    final window = await repository.loadWindow(from, to);

    expect(window.entries.single.description, 'Writing');
    expect(window.entries.single.start, DateTime.utc(2026, 8, 27, 8).toLocal());
    expect(window.sleep.single.asleep, const Duration(minutes: 400));
    expect(window.sleep.single.attribution, 'Pixel Watch');
    expect(window.sleep.single.awakeningCount, 3);
    expect(window.sleep.single.latencyMinutes, 14);
    expect(window.sleep.single.stages, hasLength(2));
    expect(window.sleep.single.stages.first.kind, SleepStageKind.light);
    expect(window.sleep.single.stages.last.kind, SleepStageKind.deep);
    expect(cache.window?.entries, hasLength(1));
  });

  test(
    'loadWindow reaches a day further back so blocks arrive whole',
    () async {
      final api = FakeLuqaApi();
      final repository = RemoteTodayRepository(
        client: api,
        cache: MemoryTimelineCache(),
      );

      await repository.loadWindow(from, to);

      // A block that began the evening before the window would otherwise be
      // missing its first half on the window's opening day.
      expect(api.entriesFrom, from.subtract(const Duration(days: 1)));
    },
  );

  test('loadCategories drops archived categories and caches them', () async {
    final cache = MemoryTimelineCache();
    final repository = RemoteTodayRepository(
      client: FakeLuqaApi(),
      cache: cache,
    );

    final categories = await repository.loadCategories();

    expect(categories.map((value) => value.name), ['Thesis']);
    expect(categories.single.colorValue, 0xFF6543E8);
    expect(cache.categories, hasLength(1));
  });

  test('a patch only sends the fields it actually changes', () async {
    final api = FakeLuqaApi();
    final repository = RemoteTodayRepository(
      client: api,
      cache: MemoryTimelineCache(),
    );

    await repository.updateEntryById(
      'entry-1',
      EntryPatch(end: DateTime.utc(2026, 8, 27, 12)),
    );

    final patch = api.lastPatch!;
    expect(patch.endTime.isPresent, isTrue);
    expect(patch.description.isPresent, isFalse);
    expect(patch.startTime.isPresent, isFalse);
    expect(patch.categoryId.isPresent, isFalse);
  });

  test('clearing a category sends an explicit null', () async {
    final api = FakeLuqaApi();
    final repository = RemoteTodayRepository(
      client: api,
      cache: MemoryTimelineCache(),
    );

    await repository.updateEntryById(
      'entry-1',
      const EntryPatch(clearCategory: true),
    );

    final patch = api.lastPatch!;
    expect(patch.categoryId.isPresent, isTrue);
    expect(patch.categoryId.value, isNull);
  });

  test('the persistent read cache is isolated by user', () async {
    // One database, two users: the isolation has to come from the namespace
    // rather than from them happening to be kept apart.
    final store = freshStore();
    final firstUser = SqliteTimelineCache(namespace: 'user-a', store: store);
    final secondUser = SqliteTimelineCache(namespace: 'user-b', store: store);
    final window = TimelineWindow(
      from: from,
      to: to,
      entries: [
        TimeEntry(
          id: 'entry-1',
          description: 'Private timeline',
          categoryId: null,
          start: DateTime(2026, 8, 27, 9),
          end: DateTime(2026, 8, 27, 10),
        ),
      ],
      sleep: const [],
    );

    await firstUser.writeWindow(window);

    expect((await firstUser.readWindow(from, to))?.entries, hasLength(1));
    expect(await secondUser.readWindow(from, to), isNull);
  });

  test('a cached window for another range is not reused', () async {
    final cache = SqliteTimelineCache(namespace: 'user-a', store: freshStore());
    await cache.writeWindow(
      TimelineWindow(from: from, to: to, entries: const [], sleep: const []),
    );

    expect(await cache.readWindow(from, to), isNotNull);
    expect(
      await cache.readWindow(from, to.add(const Duration(days: 7))),
      isNull,
    );
  });
}

class MemoryTimelineCache implements TimelineCache {
  TimelineWindow? window;
  List<Category>? categories;

  @override
  Future<List<Category>?> readCategories() async => categories;

  @override
  Future<void> writeCategories(List<Category> value) async {
    categories = value;
  }

  @override
  Future<TimelineWindow?> readWindow(DateTime from, DateTime to) async =>
      window;

  @override
  Future<void> writeWindow(TimelineWindow value) async {
    window = value;
  }
}

class FakeLuqaApi implements LuqaApi {
  DateTime? entriesFrom;
  api.UpdateTimeEntryRequest? lastPatch;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();

  // Health sync is exercised in test/features/health; this fake only needs to
  // satisfy the interface for the timeline repository.
  @override
  Future<api.HealthSyncResponse> pushHealthSync(
    api.HealthSyncRequest request,
  ) => throw UnimplementedError();

  @override
  Future<List<api.HealthSyncState>> healthSyncStates() async => const [];

  @override
  Future<List<api.Category>> listCategories() async => [
    api.Category(
      id: 'thesis',
      name: 'Thesis',
      color: '#6543E8',
      archived: false,
    ),
    api.Category(id: 'old', name: 'Old', color: '#000000', archived: true),
  ];

  @override
  Future<List<api.TimeEntry>> listTimeEntries(
    DateTime from,
    DateTime to,
  ) async {
    entriesFrom = from;
    return [
      api.TimeEntry(
        id: 'entry-1',
        description: 'Writing',
        categoryId: 'thesis',
        startTime: DateTime.utc(2026, 8, 27, 8),
        endTime: DateTime.utc(2026, 8, 27, 10),
        source_: api.EntrySource.APP,
      ),
    ];
  }

  @override
  Future<List<api.SleepEntry>> listSleepEntries(
    DateTime from,
    DateTime to,
  ) async => [
    api.SleepEntry(
      id: 'sleep-1',
      source_: api.SleepSource.HEALTH_CONNECT,
      title: null,
      sourceApp: 'Pixel Watch',
      startTime: DateTime.utc(2026, 8, 26, 22),
      endTime: DateTime.utc(2026, 8, 27, 6),
      sleepMinutes: 400,
      awakeMinutes: 20,
      awakeInBedMinutes: 12,
      outOfBedMinutes: 8,
      lightMinutes: 200,
      deepMinutes: 100,
      remMinutes: 100,
      unknownMinutes: null,
      inBedMinutes: 480,
      efficiencyPercent: 83.3,
      latencyMinutes: 14,
      wasoMinutes: 20,
      awakeningCount: 3,
      midpoint: DateTime.utc(2026, 8, 27, 2),
      isNap: false,
      recordingMethod: 'AUTOMATICALLY_RECORDED',
      deviceModel: 'Pixel Watch 3',
      stages: [
        api.SleepStage(
          stage: 'LIGHT',
          startTime: DateTime.utc(2026, 8, 26, 22),
          endTime: DateTime.utc(2026, 8, 27, 0),
        ),
        api.SleepStage(
          stage: 'DEEP',
          startTime: DateTime.utc(2026, 8, 27, 0),
          endTime: DateTime.utc(2026, 8, 27, 2),
        ),
      ],
    ),
  ];

  @override
  Future<api.TimeEntry> createTimeEntry({
    String? id,
    required String description,
    required String? categoryId,
    required DateTime start,
    required DateTime? end,
  }) async => api.TimeEntry(
    id: id ?? 'entry-2',
    description: description,
    categoryId: categoryId,
    startTime: start,
    endTime: end,
    source_: api.EntrySource.APP,
  );

  @override
  Future<api.TimeEntry> updateTimeEntry(
    String id,
    api.UpdateTimeEntryRequest patch,
  ) async {
    lastPatch = patch;
    return api.TimeEntry(
      id: id,
      description: patch.description.orElse(null) ?? 'Writing',
      categoryId: patch.categoryId.orElse(null),
      startTime: DateTime.utc(2026, 8, 27, 8),
      endTime: patch.endTime.orElse(null),
      source_: api.EntrySource.APP,
    );
  }

  @override
  Future<void> deleteTimeEntry(String id) async {}

  @override
  Future<api.Category> createCategory(String name, {String? id}) =>
      throw UnimplementedError();

  @override
  Future<StoredMobileSession?> restoreSession() => throw UnimplementedError();

  @override
  Future<StoredMobileSession> signIn({
    required String email,
    required String password,
    required String deviceName,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();
}
