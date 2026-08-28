import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/health/data/health_connect_reader.dart';
import 'package:luqa/features/health/data/health_sync_store.dart';
import 'package:luqa_api/api.dart' as api;

class FakeHealthReader implements HealthReader {
  FakeHealthReader({
    this.available = HealthAvailability.available,
    this.granted = true,
  });

  HealthAvailability available;
  bool granted;
  int reads = 0;
  int permissionRequests = 0;
  Object? readError;

  @override
  Future<HealthAvailability> availability() async => available;

  @override
  Future<bool> hasPermissions() async => granted;

  @override
  Future<bool> requestPermissions() async {
    permissionRequests += 1;
    return granted;
  }

  @override
  Future<void> openInstall() async {}

  @override
  Future<HealthReadResult> read({
    required DateTime from,
    required DateTime to,
  }) async {
    reads += 1;
    final error = readError;
    if (error != null) throw error;
    return HealthReadResult(
      sleep: const [],
      samples: const [],
      from: from,
      to: to,
    );
  }
}

class InMemoryHealthSyncStore implements HealthSyncStore {
  DateTime? _lastSynced;
  DateTime? _lastAttempted;
  DateTime? _backfilled;

  @override
  Future<DateTime?> lastSyncedAt() async => _lastSynced;

  @override
  Future<void> setLastSyncedAt(DateTime value) async => _lastSynced = value;

  @override
  Future<DateTime?> lastAttemptedAt() async => _lastAttempted;

  @override
  Future<void> setLastAttemptedAt(DateTime value) async =>
      _lastAttempted = value;

  @override
  Future<DateTime?> backfilledThrough() async => _backfilled;

  @override
  Future<void> setBackfilledThrough(DateTime value) async => _backfilled = value;

  @override
  Future<void> clear() async {
    _lastSynced = null;
    _lastAttempted = null;
    _backfilled = null;
  }
}

class FakeHealthApi implements LuqaApi {
  int pushes = 0;
  final List<api.HealthSyncRequest> requests = [];
  Object? pushError;

  @override
  Future<api.HealthSyncResponse> pushHealthSync(
    api.HealthSyncRequest request,
  ) async {
    pushes += 1;
    requests.add(request);
    final error = pushError;
    if (error != null) throw error;
    return api.HealthSyncResponse(
      sleep: api.HealthSyncCounts(imported: 1, deleted: 0),
      samples: api.HealthSyncCounts(imported: 0, deleted: 0),
    );
  }

  @override
  Future<List<api.HealthSyncState>> healthSyncStates() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
