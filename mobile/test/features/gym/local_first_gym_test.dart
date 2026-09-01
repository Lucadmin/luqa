import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/core/storage/luqa_store.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/gym/data/gym_local_store.dart';
import 'package:luqa/features/gym/data/gym_outbox.dart';
import 'package:luqa/features/gym/data/gym_repository.dart';
import 'package:luqa/features/gym/data/gym_sync_service.dart';
import 'package:luqa/features/gym/data/local_first_gym_repository.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/fake_gym_repository.dart';
import '../../helpers/test_store.dart';

class _TestQueue implements MutationQueue<GymMutation> {
  List<GymMutation> _queue = const [];

  @override
  Future<void> get ready async {}

  @override
  List<GymMutation> get pending => _queue;

  /// Nothing is ever sent in these tests; the queue is only here so a write
  /// has somewhere to go.
  @override
  Future<void> sync() async {}

  @override
  Future<void> enqueue(GymMutation mutation, {bool sendNow = true}) async {
    _queue = foldGym(_queue, mutation);
  }
}

/// A network that is never reached: every read in these tests is answered from
/// the device, which is the claim being tested.
class _UnreachableApi implements LuqaApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final _now = DateTime(2026, 8, 27, 18);

GymSessionWrite _write({
  required List<GymExerciseWrite> exercises,
  String dateKey = '2026-08-27',
  String? locationId,
  String notes = '',
}) => GymSessionWrite(
  dateKey: dateKey,
  locationId: locationId,
  notes: notes,
  exercises: exercises,
);

GymExerciseWrite _lift(
  String name, {
  required String exerciseId,
  required List<GymSetWrite> sets,
  String notes = '',
}) => GymExerciseWrite(
  exerciseId: exerciseId,
  name: name,
  sets: sets,
  notes: notes,
);

void main() {
  sqfliteFfiInit();

  late LuqaStore store;
  late GymLocalStore local;
  late _TestQueue queue;
  late LocalFirstGymRepository repository;

  setUp(() {
    store = openTestStore();
    addTearDown(store.close);
    local = GymLocalStore(namespace: 'user-a', store: store);
    queue = _TestQueue();
    repository = LocalFirstGymRepository(
      store: local,
      sync: GymSyncService(client: _UnreachableApi(), store: local),
      remote: FakeGymRepository.sample(),
      queue: queue,
      now: () => _now,
    );
  });

  /// An exercise the device already knows about, as a sync would have left it.
  Future<void> givenExercise(String id, String name) => local.applyExercises([
    GymExercise(
      id: id,
      name: name,
      notes: '',
      archived: false,
      sessionCount: 0,
      lastPerformed: null,
      locationIds: const [],
    ),
  ], const []);

  group('logging a workout', () {
    test('starts with no network and opens immediately', () async {
      final session = await repository.createSession(
        dateKey: '2026-08-27',
        locationId: null,
      );

      expect((await repository.loadSession(session.id)).id, session.id);
      expect(queue.pending.whereType<CreateSession>(), hasLength(1));
    });

    test('sets typed with no network survive being reopened', () async {
      await givenExercise('bench', 'Bench press');
      final session = await repository.createSession(
        dateKey: '2026-08-27',
        locationId: null,
      );

      await repository.saveSession(
        session.id,
        _write(
          exercises: [
            _lift(
              'Bench press',
              exerciseId: 'bench',
              sets: const [
                GymSetWrite(weight: 70, reps: 8),
                GymSetWrite(weight: 72.5, reps: 6),
              ],
            ),
          ],
        ),
      );

      final reopened = await repository.loadSession(session.id);
      expect(reopened.exercises.single.name, 'Bench press');
      expect(reopened.exercises.single.sets, hasLength(2));
      expect(reopened.exercises.single.sets.last.weight, 72.5);
      expect(reopened.completedSetCount, 2);
    });

    test('a workout logged offline is on the overview at once', () async {
      await givenExercise('bench', 'Bench press');
      final session = await repository.createSession(
        dateKey: '2026-08-27',
        locationId: null,
      );
      await repository.saveSession(
        session.id,
        _write(
          exercises: [
            _lift(
              'Bench press',
              exerciseId: 'bench',
              sets: const [GymSetWrite(weight: 70, reps: 8)],
            ),
          ],
        ),
      );

      final overview = await repository.loadOverview();
      expect(overview.sessions.single.id, session.id);
      expect(overview.totalSessions, 1);
      // The counts the overview shows are derived here, not sent.
      expect(overview.exerciseById('bench')!.sessionCount, 1);
      expect(overview.exerciseById('bench')!.lastPerformed, '2026-08-27');
    });

    test('re-adding a gym the device knows is the same gym', () async {
      final first = await repository.createLocation(
        name: 'Home',
        code: 'HOM',
        colorValue: 0xFF112233,
      );
      final again = await repository.createLocation(
        name: 'Home again',
        code: 'hom',
        colorValue: 0xFF445566,
      );

      expect(again.id, first.id);
      expect((await local.locations()), hasLength(1));
    });
  });

  group('what the history sheet works out', () {
    /// Three sessions of the same lift, getting heavier.
    Future<void> givenProgression() async {
      await givenExercise('bench', 'Bench press');
      for (final (index, weight) in [60.0, 70.0, 65.0].indexed) {
        final session = await repository.createSession(
          dateKey: '2026-08-2${index + 1}',
          locationId: null,
        );
        await repository.saveSession(
          session.id,
          _write(
            dateKey: '2026-08-2${index + 1}',
            exercises: [
              _lift(
                'Bench press',
                exerciseId: 'bench',
                sets: [GymSetWrite(weight: weight, reps: 8)],
              ),
            ],
          ),
        );
      }
    }

    test('plots every session oldest first', () async {
      await givenProgression();

      final history = await repository.loadExerciseHistory('bench');
      expect(history.points, hasLength(3));
      expect(history.points.first.dateKey, '2026-08-21');
      expect(history.points.last.dateKey, '2026-08-23');
    });

    test('the heaviest and the best estimate come from the whole history',
        () async {
      await givenProgression();

      final history = await repository.loadExerciseHistory('bench');
      expect(history.heaviest, 70.0);
      // Epley on 70×8: 70 × (1 + 8/30).
      expect(history.bestEver, closeTo(70 * (1 + 8 / 30), 0.0001));
    });

    test('the first session is a baseline, not a record', () async {
      await givenProgression();

      final history = await repository.loadExerciseHistory('bench');
      expect(history.points[0].isPersonalRecord, isFalse, reason: 'baseline');
      expect(history.points[1].isPersonalRecord, isTrue, reason: 'beat 60');
      expect(history.points[2].isPersonalRecord, isFalse, reason: 'under 70');
    });

    test('"last time" means before the session being edited', () async {
      await givenProgression();
      final sessions = await repository.loadSessions();
      final newest = sessions.sessions.first;

      final history = await repository.loadExerciseHistory(
        'bench',
        beforeSessionId: newest.id,
      );

      expect(history.points, hasLength(2));
      expect(history.points.last.dateKey, '2026-08-22');
    });

    test('volume and reps are totalled per session', () async {
      await givenExercise('squat', 'Squat');
      final session = await repository.createSession(
        dateKey: '2026-08-27',
        locationId: null,
      );
      await repository.saveSession(
        session.id,
        _write(
          exercises: [
            _lift(
              'Squat',
              exerciseId: 'squat',
              sets: const [
                GymSetWrite(weight: 100, reps: 5),
                GymSetWrite(weight: 100, reps: 3),
              ],
            ),
          ],
        ),
      );

      final point = (await repository.loadExerciseHistory('squat')).points.single;
      expect(point.totalReps, 8);
      expect(point.volume, 800);
      expect(point.topWeight, 100);
    });
  });

  group('what the delta feed is allowed to touch', () {
    test('a synced workout is replaced by the server copy', () async {
      await local.applySessions([
        GymSession(
          id: 's1',
          dateKey: '2026-08-27',
          locationId: null,
          notes: 'from server',
          exercises: const [],
          createdAt: _now,
        ),
      ], const []);

      expect((await local.session('s1'))!.notes, 'from server');
    });

    test('a workout this device has changed is left alone', () async {
      final session = await repository.createSession(
        dateKey: '2026-08-27',
        locationId: null,
      );
      await repository.saveSession(
        session.id,
        _write(exercises: const [], notes: 'typed here'),
      );

      await local.applySessions([
        GymSession(
          id: session.id,
          dateKey: '2026-08-27',
          locationId: null,
          notes: 'stale server copy',
          exercises: const [],
          createdAt: _now,
        ),
      ], const []);

      expect((await local.session(session.id))!.notes, 'typed here');
    });

    test('a deleted workout takes its sets with it', () async {
      await givenExercise('bench', 'Bench press');
      final session = await repository.createSession(
        dateKey: '2026-08-27',
        locationId: null,
      );
      await repository.saveSession(
        session.id,
        _write(
          exercises: [
            _lift(
              'Bench press',
              exerciseId: 'bench',
              sets: const [GymSetWrite(weight: 70, reps: 8)],
            ),
          ],
        ),
      );
      await local.settle('gym_session', session.id);

      await local.applySessions(const [], [session.id]);

      expect(await local.session(session.id), isNull);
      // The history is gone with it rather than pointing at a workout that
      // no longer exists.
      expect((await repository.loadExerciseHistory('bench')).points, isEmpty);
    });
  });

  group('after two exercises are merged', () {
    /// What a merge leaves behind: both spellings' entries on one exercise,
    /// which can put the same exercise in a single workout twice.
    Future<void> givenMergedIntoOneSession() async {
      await givenExercise('lat', 'Lat pulldown');
      final session = await repository.createSession(
        dateKey: '2026-08-27',
        locationId: null,
      );
      await repository.saveSession(
        session.id,
        _write(
          exercises: [
            _lift(
              'Lat pulldown',
              exerciseId: 'lat',
              sets: const [GymSetWrite(weight: 67, reps: 11)],
            ),
            _lift(
              'Lat pulldown',
              exerciseId: 'lat',
              sets: const [GymSetWrite(weight: 17.5, reps: 15)],
            ),
          ],
        ),
      );
    }

    test('both performances are kept as their own points', () async {
      await givenMergedIntoOneSession();

      final history = await repository.loadExerciseHistory('lat');
      expect(history.points, hasLength(2));
    });

    test('they are ordered by position in the workout, not arbitrarily',
        () async {
      // The order decides which one carries the record badge, so it cannot be
      // left to whatever the database returns first.
      await givenMergedIntoOneSession();

      final history = await repository.loadExerciseHistory('lat');
      expect(history.points.first.topWeight, 67);
      expect(history.points.last.topWeight, 17.5);
      // The heavier one came first, so the lighter one never beat it.
      expect(history.points.last.isPersonalRecord, isFalse);
    });

    test('a workout saved against the retired id lands on the survivor',
        () async {
      await givenExercise('lat', 'Lat pulldown');
      await givenExercise('lat-typo', 'Lat puldown');
      await local.recordMerge('lat-typo', 'lat');

      final session = await repository.createSession(
        dateKey: '2026-08-28',
        locationId: null,
      );
      await repository.saveSession(
        session.id,
        _write(
          exercises: [
            _lift(
              'Lat puldown',
              exerciseId: 'lat-typo',
              sets: const [GymSetWrite(weight: 70, reps: 8)],
            ),
          ],
        ),
      );

      // Filed under the surviving exercise rather than the one just retired.
      expect((await repository.loadExerciseHistory('lat')).points, hasLength(1));
      expect(
        (await repository.loadSession(session.id)).exercises.single.exerciseId,
        'lat',
      );
    });
  });

  group('an id the server chose instead', () {
    test('workouts logged at that gym follow it', () async {
      final home = await repository.createLocation(
        name: 'Home',
        code: 'HOM',
        colorValue: 0xFF112233,
      );
      final session = await repository.createSession(
        dateKey: '2026-08-27',
        locationId: home.id,
      );

      await local.remapId('gym_location', home.id, 'server-home');

      expect((await local.locations()).single.id, 'server-home');
      expect((await repository.loadSession(session.id)).locationId,
          'server-home');
    });
  });
}
