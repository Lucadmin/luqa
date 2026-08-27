import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/auth/data/secure_credential_store.dart';
import 'package:luqa/features/today/data/remote_today_repository.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa_api/api.dart' as api;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test(
    'refresh maps API data, filters archived categories, and caches it',
    () async {
      final cache = MemoryTodayCache();
      final repository = RemoteTodayRepository(
        client: FakeLuqaApi(),
        cache: cache,
      );

      final snapshot = await repository.refresh(DateTime(2026, 8, 27, 14));

      expect(snapshot.day, DateTime(2026, 8, 27));
      expect(snapshot.categories.map((value) => value.name), ['Thesis']);
      expect(snapshot.categories.single.colorValue, 0xFF6543E8);
      expect(snapshot.entries.single.description, 'Writing');
      expect(snapshot.recentActivities.single.description, 'Writing');
      expect(snapshot.sleep, isNull);
      expect(cache.snapshot, same(snapshot));
    },
  );

  test('new entries update the cached timeline immediately', () async {
    final cache = MemoryTodayCache();
    final repository = RemoteTodayRepository(
      client: FakeLuqaApi(),
      cache: cache,
    );
    await repository.refresh(DateTime(2026, 8, 27));

    final created = await repository.addEntry(
      NewTimeEntry(
        description: 'Walk',
        categoryId: null,
        start: DateTime(2026, 8, 27, 18),
        end: DateTime(2026, 8, 27, 18, 30),
      ),
    );

    expect(created.description, 'Walk');
    expect(cache.snapshot?.entries.map((value) => value.description), [
      'Writing',
      'Walk',
    ]);
    expect(cache.writes, 2);
  });

  test('persistent read cache is isolated by user', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = null);
    final firstUser = SharedPreferencesTodayCache(namespace: 'user-a');
    final secondUser = SharedPreferencesTodayCache(namespace: 'user-b');
    final snapshot = TodaySnapshot(
      day: DateTime(2026, 8, 27),
      entries: [
        TimeEntry(
          id: 'entry-1',
          description: 'Private timeline',
          categoryId: null,
          start: DateTime(2026, 8, 27, 9),
          end: DateTime(2026, 8, 27, 10),
        ),
      ],
      categories: const [],
      recentActivities: const [],
      habits: const [],
      sleep: null,
    );

    await firstUser.write(snapshot);

    expect((await firstUser.read(snapshot.day))?.entries, hasLength(1));
    expect(await secondUser.read(snapshot.day), isNull);
  });
}

class MemoryTodayCache implements TodayCache {
  TodaySnapshot? snapshot;
  int writes = 0;

  @override
  Future<TodaySnapshot?> read(DateTime day) async => snapshot;

  @override
  Future<void> write(TodaySnapshot value) async {
    writes += 1;
    snapshot = value;
  }
}

class FakeLuqaApi implements LuqaApi {
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
  ) async => [
    api.TimeEntry(
      id: 'entry-1',
      description: 'Writing',
      categoryId: 'thesis',
      startTime: DateTime.utc(2026, 8, 27, 8),
      endTime: DateTime.utc(2026, 8, 27, 10),
      source_: api.EntrySource.APP,
    ),
  ];

  @override
  Future<api.TimeEntry> createTimeEntry({
    required String description,
    required String? categoryId,
    required DateTime start,
    required DateTime end,
  }) async => api.TimeEntry(
    id: 'entry-2',
    description: description,
    categoryId: categoryId,
    startTime: start,
    endTime: end,
    source_: api.EntrySource.APP,
  );

  @override
  Future<api.Category> createCategory(String name) =>
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
