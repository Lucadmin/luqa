import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/gym/data/gym_outbox.dart';
import 'package:luqa/features/gym/data/gym_repository.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

final _at = DateTime.utc(2026, 8, 31, 18);

GymSession _session(String id, {String? locationId}) => GymSession(
  id: id,
  dateKey: '2026-08-31',
  locationId: locationId,
  notes: '',
  exercises: const [],
  createdAt: _at,
);

GymSessionWrite _write({
  String notes = '',
  String? locationId,
  List<GymSetWrite> sets = const [],
}) => GymSessionWrite(
  dateKey: '2026-08-31',
  locationId: locationId,
  notes: notes,
  exercises: [
    GymExerciseWrite(
      exerciseId: null,
      name: 'Lat pulldown',
      sets: sets,
      notes: '',
    ),
  ],
);

void main() {
  group('folding', () {
    test('sets typed into an unsent workout stay a save of their own', () {
      var queue = foldGym(
        const [],
        CreateSession(session: _session('w1'), queuedAt: _at),
      );

      queue = foldGym(
        queue,
        SaveSession(
          sessionId: 'w1',
          write: _write(sets: const [GymSetWrite(weight: 75, reps: 10)]),
          queuedAt: _at,
        ),
      );

      // Folding them together would lose the sets: a create carries only the
      // date and the gym.
      expect(queue, hasLength(2));
      expect(queue.first, isA<CreateSession>());
      final write = (queue.last as SaveSession).write;
      expect(write.exercises.single.sets.single.weight, 75);
    });

    test('a whole set of keystrokes collapses to one request', () {
      var queue = <GymMutation>[];
      for (final reps in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) {
        queue = foldGym(
          queue,
          SaveSession(
            sessionId: 'server-1',
            write: _write(sets: [GymSetWrite(weight: 75, reps: reps)]),
            queuedAt: _at,
          ),
        );
      }

      expect(queue, hasLength(1));
      final write = (queue.single as SaveSession).write;
      expect(write.exercises.single.sets.single.reps, 10);
    });

    test('edits to a gym invented offline become part of its create', () {
      var queue = foldGym(
        const [],
        CreateLocation(
          location: const GymLocation(
            id: 'g1',
            code: 'HOME',
            name: 'Home',
            colorValue: 0xFF000000,
            order: 0,
            archived: false,
          ),
          queuedAt: _at,
        ),
      );

      queue = foldGym(
        queue,
        UpdateLocation(
          locationId: 'g1',
          name: 'Garage',
          code: null,
          colorValue: null,
          archived: null,
          queuedAt: _at,
        ),
      );

      expect(queue, hasLength(1));
      expect((queue.single as CreateLocation).location.name, 'Garage');
      expect((queue.single as CreateLocation).location.code, 'HOME');
    });

    test('workouts and gyms stay in the order they were made', () {
      var queue = foldGym(
        const [],
        CreateSession(session: _session('w1'), queuedAt: _at),
      );
      queue = foldGym(
        queue,
        SaveSession(sessionId: 'other', write: _write(), queuedAt: _at),
      );
      queue = foldGym(
        queue,
        CreateSession(session: _session('w2'), queuedAt: _at),
      );

      expect(queue.map((pending) => pending.subjectId), ['w1', 'other', 'w2']);
    });
  });

  group('gym remapping', () {
    test('queued workouts follow the id the server actually chose', () {
      final queue = <GymMutation>[
        CreateSession(
          session: _session('w1', locationId: 'g1'),
          queuedAt: _at,
        ),
        SaveSession(
          sessionId: 'w2',
          write: _write(locationId: 'g1'),
          queuedAt: _at,
        ),
      ];

      final remapped = remapLocationId(queue, 'g1', 'server-gym');

      expect((remapped[0] as CreateSession).session.locationId, 'server-gym');
      expect((remapped[1] as SaveSession).write.locationId, 'server-gym');
    });
  });

  group('persistence', () {
    test('every kind of mutation survives a round trip', () {
      final queue = <GymMutation>[
        CreateSession(
          session: _session('w1', locationId: 'g1'),
          queuedAt: _at,
        ),
        SaveSession(
          sessionId: 'w1',
          write: _write(
            notes: 'Felt strong',
            sets: const [GymSetWrite(weight: 75, reps: 10, note: 'lf')],
          ),
          queuedAt: _at,
        ),
        CreateLocation(
          location: const GymLocation(
            id: 'g1',
            code: 'HOME',
            name: 'Home',
            colorValue: 0xFF123456,
            order: 2,
            archived: false,
          ),
          queuedAt: _at,
        ),
        UpdateLocation(
          locationId: 'g1',
          name: 'Garage',
          code: null,
          colorValue: null,
          archived: true,
          queuedAt: _at,
        ),
      ];

      final restored = [
        for (final pending in queue) GymMutation.fromJson(pending.toJson())!,
      ];

      expect(restored.map((pending) => pending.subjectId), [
        'w1',
        'w1',
        'g1',
        'g1',
      ]);
      final write = (restored[1] as SaveSession).write;
      expect(write.notes, 'Felt strong');
      expect(write.exercises.single.sets.single.note, 'lf');
      expect((restored[2] as CreateLocation).location.colorValue, 0xFF123456);
      expect((restored[3] as UpdateLocation).archived, isTrue);
    });

    test('an op written by a newer build is skipped rather than fatal', () {
      expect(
        GymMutation.fromJson({
          'op': 'benchPressThePhone',
          'queuedAt': _at.toIso8601String(),
        }),
        isNull,
      );
    });
  });
}
