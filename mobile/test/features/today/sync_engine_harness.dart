import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/auth/data/secure_credential_store.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/today/data/outbox.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa_api/api.dart' as api;

class MemoryOutbox implements Outbox<TimelineMutation> {
  List<TimelineMutation> stored = const [];

  @override
  Future<List<TimelineMutation>> read() async => [
    // Round-tripped deliberately: this is what a real launch reads back.
    for (final pending in stored) TimelineMutation.fromJson(pending.toJson())!,
  ];

  @override
  Future<void> write(List<TimelineMutation> queue) async {
    stored = List.of(queue);
  }
}

/// Stands in for the server. Offline is modelled the way the generated client
/// reports it: a synthetic 400 carrying the real cause.
class FakeApi implements LuqaApi {
  bool offline = false;
  String? rejectDeleteOf;
  final Map<String, String> categoryIdForName = {};

  /// Rows the server already holds, as a test chooses to seed them.
  final List<TimeEntry> entries = [];

  final List<api.TimeEntry> created = [];
  final List<String> deleted = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();

  void _check() {
    if (offline) {
      throw api.ApiException.withInner(
        400,
        'Connection refused',
        const SocketExceptionStub(),
        StackTrace.current,
      );
    }
  }

  @override
  Future<api.TimeEntry> createTimeEntry({
    String? id,
    required String description,
    required String? categoryId,
    required DateTime start,
    required DateTime? end,
  }) async {
    _check();
    final entry = api.TimeEntry(
      id: id ?? 'server-${created.length}',
      description: description,
      categoryId: categoryId,
      startTime: start,
      endTime: end,
      source_: api.EntrySource.APP,
    );
    created.add(entry);
    entries.add(
      TimeEntry(
        id: entry.id,
        description: entry.description,
        categoryId: entry.categoryId,
        start: entry.startTime.toLocal(),
        end: entry.endTime?.toLocal(),
      ),
    );
    return entry;
  }

  @override
  Future<void> deleteTimeEntry(String id) async {
    _check();
    if (id == rejectDeleteOf) throw api.ApiException(404, 'Not found');
    deleted.add(id);
    entries.removeWhere((entry) => entry.id == id);
  }

  @override
  Future<api.Category> createCategory(String name, {String? id}) async {
    _check();
    return api.Category(
      id: categoryIdForName[name] ?? id ?? 'server-category',
      name: name,
      color: '#6366f1',
      archived: false,
    );
  }

  @override
  Future<api.TimeEntry> updateTimeEntry(
    String id,
    api.UpdateTimeEntryRequest patch,
  ) async {
    _check();
    final index = entries.indexWhere((entry) => entry.id == id);
    final existing = index == -1 ? null : entries[index];
    final updated = TimeEntry(
      id: id,
      description:
          patch.description.orElse(null) ?? existing?.description ?? '',
      categoryId: patch.categoryId.isPresent
          ? patch.categoryId.value
          : existing?.categoryId,
      start:
          patch.startTime.orElse(null)?.toLocal() ??
          existing?.start ??
          DateTime.utc(2026, 8, 31, 10),
      end: patch.endTime.isPresent
          ? patch.endTime.value?.toLocal()
          : existing?.end,
    );
    if (index != -1) entries[index] = updated;
    return api.TimeEntry(
      id: updated.id,
      description: updated.description,
      categoryId: updated.categoryId,
      startTime: updated.start.toUtc(),
      endTime: updated.end?.toUtc(),
      source_: api.EntrySource.APP,
    );
  }

  @override
  Future<List<api.Category>> listCategories() async => const [];

  @override
  Future<List<api.TimeEntry>> listTimeEntries(
    DateTime from,
    DateTime to,
  ) async {
    _check();
    return [
      for (final entry in entries)
        api.TimeEntry(
          id: entry.id,
          description: entry.description,
          categoryId: entry.categoryId,
          startTime: entry.start.toUtc(),
          endTime: entry.end?.toUtc(),
          source_: api.EntrySource.APP,
        ),
    ];
  }

  @override
  Future<List<api.SleepEntry>> listSleepEntries(
    DateTime from,
    DateTime to,
  ) async => const [];

  @override
  Future<api.HealthSyncResponse> pushHealthSync(
    api.HealthSyncRequest request,
  ) => throw UnimplementedError();

  @override
  Future<List<api.HealthSyncState>> healthSyncStates() =>
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

/// Any non-null inner exception is what marks an ApiException as a transport
/// failure rather than a considered refusal.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
