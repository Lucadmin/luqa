import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/gym/application/gym_overview_controller.dart';
import 'package:luqa/features/gym/application/gym_sync_engine.dart';
import 'package:luqa/features/gym/application/workout_controller.dart';
import 'package:luqa/features/gym/data/gym_cache.dart';
import 'package:luqa/features/gym/data/gym_outbox.dart';
import 'package:luqa/features/gym/data/gym_providers.dart';
import 'package:luqa/features/gym/data/gym_repository.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';
import 'package:luqa_api/api.dart' as api;

import '../../helpers/fake_gym_repository.dart';
import '../../helpers/pump_luqa.dart';

/// The whole gym stack minus the widget tree: real controllers over the real
/// local-first repository over the real sync engine, with only the network and
/// the disk faked.
class _Stack {
  _Stack({
    bool offline = false,
    _MemoryGymOutbox? outbox,
    _MemoryGymCache? cache,
  }) {
    remote = _FlakyGymRepository(FakeGymRepository.sample())..offline = offline;
    this.outbox = outbox ?? _MemoryGymOutbox();
    this.cache = cache ?? _MemoryGymCache();
    container = ProviderContainer(
      overrides: [
        remoteGymRepositoryProvider.overrideWithValue(remote),
        gymOutboxProvider.overrideWithValue(this.outbox),
        gymDiscardLogProvider.overrideWithValue(const NullDiscardLog()),
        gymCacheProvider.overrideWithValue(this.cache),
        gymNowProvider.overrideWithValue(DateTime(2026, 8, 27, 16)),
        authControllerProvider.overrideWith(FixedAuthController.new),
      ],
    );
  }

  late final _FlakyGymRepository remote;
  late final _MemoryGymOutbox outbox;
  late final _MemoryGymCache cache;
  late final ProviderContainer container;

  GymOverviewController get overview =>
      container.read(gymOverviewControllerProvider.notifier);

  GymOverviewState get overviewState =>
      container.read(gymOverviewControllerProvider);

  GymSyncEngine get engine => container.read(gymSyncEngineProvider.notifier);

  GymRepository get repository => container.read(gymRepositoryProvider);

  WorkoutController workout(String sessionId) =>
      container.read(workoutControllerProvider(sessionId).notifier);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  void dispose() => container.dispose();
}

void main() {
  test('a workout starts with no network and opens immediately', () async {
    final stack = _Stack(offline: true);
    addTearDown(stack.dispose);

    final session = await stack.overview.startWorkout();

    expect(session, isNotNull);
    expect(session!.id, isNotEmpty);
    expect(stack.engine.pending, hasLength(1));
    expect(stack.remote.created, isEmpty);
  });

  test('sets typed with no network survive being reopened', () async {
    final stack = _Stack(offline: true);
    addTearDown(stack.dispose);

    final session = await stack.overview.startWorkout();
    final controller = stack.workout(session!.id);
    await stack.settle();

    controller.addExercise(name: 'Lat pulldown');
    controller.updateSet(0, weight: '75', reps: '10');
    await controller.flush();

    // Read back through the repository, as reopening the screen would.
    final reopened = await stack.repository.loadSession(session.id);

    expect(reopened.exercises.single.name, 'Lat pulldown');
    expect(reopened.exercises.single.sets.single.weight, 75);
    expect(reopened.exercises.single.sets.single.reps, 10);
  });

  test('a workout logged offline is sent once the network returns', () async {
    final stack = _Stack(offline: true);
    addTearDown(stack.dispose);

    final session = await stack.overview.startWorkout();
    final controller = stack.workout(session!.id);
    await stack.settle();
    controller.addExercise(name: 'Lat pulldown');
    controller.updateSet(0, weight: '75', reps: '10');
    await controller.flush();
    await stack.engine.sync();

    stack.remote.offline = false;
    await stack.engine.sync();

    expect(stack.engine.pending, isEmpty);
    expect(stack.remote.created.single.id, session.id);
    // Create then save: the workout is made before it is filled in.
    expect(stack.remote.saved, [session.id]);
  });

  test(
    'a workout logged before a restart is sent on the next launch',
    () async {
      final outbox = _MemoryGymOutbox();
      final cache = _MemoryGymCache();
      final first = _Stack(offline: true, outbox: outbox, cache: cache);
      final session = await first.overview.startWorkout();
      await first.engine.sync();
      first.dispose();
      expect(outbox.stored, isNotEmpty);

      final second = _Stack(outbox: outbox, cache: cache);
      addTearDown(second.dispose);
      await second.engine.ready;
      await second.engine.sync();

      expect(second.remote.created.single.id, session!.id);
      expect(outbox.stored, isEmpty);
    },
  );

  test(
    'the gym screen paints from the cache when the network is gone',
    () async {
      final cache = _MemoryGymCache();
      final warm = _Stack(cache: cache);
      await warm.overview.load();
      warm.dispose();
      expect(cache.overview, isNotNull);

      final cold = _Stack(offline: true, cache: cache);
      addTearDown(cold.dispose);
      // Reading the controller starts its own cache-first load; let it finish
      // rather than racing it with a second one.
      cold.overview;
      await cold.settle();
      await cold.settle();

      expect(cold.overviewState.overview, isNotNull);
      expect(cold.overviewState.error, isNull);
    },
  );

  test(
    'a gym added offline is usable and later adopts the server id',
    () async {
      final stack = _Stack(offline: true);
      addTearDown(stack.dispose);
      stack.overview;
      await stack.settle();

      final added = await stack.overview.createLocation(
        name: 'Garage',
        code: 'GAR',
        colorValue: 0xFF112233,
      );
      expect(added, isTrue);

      final local = stack.engine.pending.whereType<CreateLocation>().single;
      await stack.overview.startWorkout(locationId: local.location.id);

      // Let the offline attempt finish before the network comes back, so the
      // sync below is a fresh drain rather than a wait on a doomed one.
      await stack.engine.sync();
      // The server already has a gym under that code, with an id of its own.
      stack.remote.locationIdForCode['GAR'] = 'server-gym';
      stack.remote.offline = false;
      await stack.engine.sync();

      expect(stack.engine.pending, isEmpty);
      expect(stack.remote.created.single.locationId, 'server-gym');
    },
  );

  test(
    'a refused write is dropped so the ones behind it can through',
    () async {
      final stack = _Stack();
      addTearDown(stack.dispose);
      stack.remote.rejectSaveOf = 'ghost';

      await stack.repository.saveSession(
        'ghost',
        const GymSessionWrite(
          dateKey: '2026-08-27',
          locationId: null,
          notes: '',
          exercises: [],
        ),
      );
      final session = await stack.overview.startWorkout();
      await stack.engine.sync();

      expect(stack.engine.pending, isEmpty);
      expect(stack.remote.created.single.id, session!.id);
    },
  );
}

/// The sample gym repository, plus a network that can be taken away.
class _FlakyGymRepository implements GymRepository {
  _FlakyGymRepository(this.inner);

  final FakeGymRepository inner;
  bool offline = false;
  String? rejectSaveOf;
  final Map<String, String> locationIdForCode = {};
  final List<GymSession> created = [];
  final List<String> saved = [];

  void _check() {
    if (offline) {
      throw api.ApiException.withInner(
        400,
        'Connection refused',
        const _Unreachable(),
        StackTrace.current,
      );
    }
  }

  @override
  Future<GymOverview> loadOverview({int limit = 30}) async {
    _check();
    return inner.loadOverview(limit: limit);
  }

  @override
  Future<GymSession> createSession({
    String? id,
    required String dateKey,
    required String? locationId,
  }) async {
    _check();
    final session = await inner.createSession(
      id: id,
      dateKey: dateKey,
      locationId: locationId,
    );
    created.add(session);
    return session;
  }

  @override
  Future<GymSession> loadSession(String id) async {
    _check();
    return inner.loadSession(id);
  }

  @override
  Future<GymSession> saveSession(String id, GymSessionWrite write) async {
    _check();
    if (id == rejectSaveOf) throw api.ApiException(404, 'Not found');
    saved.add(id);
    return inner.saveSession(id, write);
  }

  @override
  Future<GymSessionPage> loadSessions({String? cursor, int limit = 20}) async {
    _check();
    return inner.loadSessions(cursor: cursor, limit: limit);
  }

  @override
  Future<GymExerciseHistory> loadExerciseHistory(
    String exerciseId, {
    String? locationId,
    String? beforeSessionId,
  }) async {
    _check();
    return inner.loadExerciseHistory(
      exerciseId,
      locationId: locationId,
      beforeSessionId: beforeSessionId,
    );
  }

  @override
  Future<GymLocation> createLocation({
    String? id,
    required String name,
    required String code,
    required int colorValue,
  }) async {
    _check();
    return inner.createLocation(
      id: locationIdForCode[code] ?? id,
      name: name,
      code: code,
      colorValue: colorValue,
    );
  }

  @override
  Future<GymLocation> updateLocation({
    required String id,
    String? name,
    String? code,
    int? colorValue,
    bool? archived,
  }) async {
    _check();
    return inner.updateLocation(
      id: id,
      name: name,
      code: code,
      colorValue: colorValue,
      archived: archived,
    );
  }
}

class _MemoryGymOutbox implements Outbox<GymMutation> {
  List<GymMutation> stored = const [];

  @override
  Future<List<GymMutation>> read() async => [
    // Round-tripped deliberately: this is what a real launch reads back.
    for (final pending in stored) GymMutation.fromJson(pending.toJson())!,
  ];

  @override
  Future<void> write(List<GymMutation> queue) async {
    stored = List.of(queue);
  }
}

class _MemoryGymCache implements GymCache {
  GymOverview? overview;
  final Map<String, GymSession> sessions = {};

  @override
  Future<GymOverview?> readOverview() async => overview;

  @override
  Future<void> writeOverview(GymOverview value) async {
    overview = value;
  }

  @override
  Future<GymSession?> readSession(String id) async => sessions[id];

  @override
  Future<void> writeSession(GymSession session) async {
    sessions[session.id] = session;
  }
}

/// Any non-null inner exception is what marks an ApiException as a transport
/// failure rather than a considered refusal.
class _Unreachable implements Exception {
  const _Unreachable();
}
