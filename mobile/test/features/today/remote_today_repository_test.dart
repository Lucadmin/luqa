import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/auth/data/secure_credential_store.dart';
import 'package:luqa/features/today/data/remote_today_repository.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa_api/api.dart' as api;

void main() {
  final from = DateTime(2026, 8, 17);
  final to = DateTime(2026, 9, 7);

  test('loadWindow maps entries and sleep', () async {
    final api = FakeLuqaApi();
    final repository = RemoteTodayRepository(client: api);

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
  });

  test(
    'loadWindow reaches a day further back so blocks arrive whole',
    () async {
      final api = FakeLuqaApi();
      final repository = RemoteTodayRepository(client: api);

      await repository.loadWindow(from, to);

      // A block that began the evening before the window would otherwise be
      // missing its first half on the window's opening day.
      expect(api.entriesFrom, from.subtract(const Duration(days: 1)));
    },
  );

  test('loadCategories drops archived categories', () async {
    final repository = RemoteTodayRepository(client: FakeLuqaApi());

    final categories = await repository.loadCategories();

    expect(categories.map((value) => value.name), ['Thesis']);
    expect(categories.single.colorValue, 0xFF6543E8);
  });

  test('a patch only sends the fields it actually changes', () async {
    final api = FakeLuqaApi();
    final repository = RemoteTodayRepository(client: api);

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
    final repository = RemoteTodayRepository(client: api);

    await repository.updateEntryById(
      'entry-1',
      const EntryPatch(clearCategory: true),
    );

    final patch = api.lastPatch!;
    expect(patch.categoryId.isPresent, isTrue);
    expect(patch.categoryId.value, isNull);
  });

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
