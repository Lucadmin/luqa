import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/habits/data/habits_outbox.dart';

import 'habit_day_test.dart' show named, log;

final _at = DateTime(2026, 3, 11, 9);

List<HabitMutation> fold(List<HabitMutation> mutations) {
  var queue = <HabitMutation>[];
  for (final mutation in mutations) {
    queue = foldHabits(queue, mutation);
  }
  return queue;
}

void main() {
  group('foldHabits', () {
    test('four taps on one habit leave one request', () {
      final queue = fold([
        for (var count = 1; count <= 4; count++)
          WriteHabitLog(
            log: log('water', '2026-03-11', count: count),
            queuedAt: _at.add(Duration(seconds: count)),
          ),
      ]);

      expect(queue, hasLength(1));
      expect((queue.single as WriteHabitLog).log.count, 4);
      // Folded in place, so a check-in cannot overtake the create it needs.
      expect(queue.single.queuedAt, _at.add(const Duration(seconds: 1)));
    });

    test('two habits ticked on the same day stay two requests', () {
      final queue = fold([
        WriteHabitLog(
          log: log('water', '2026-03-11', count: 1),
          queuedAt: _at,
        ),
        WriteHabitLog(log: log('read', '2026-03-11', count: 1), queuedAt: _at),
      ]);
      expect(queue, hasLength(2));
    });

    test('the same habit on two days stays two requests', () {
      final queue = fold([
        WriteHabitLog(
          log: log('water', '2026-03-10', count: 1),
          queuedAt: _at,
        ),
        WriteHabitLog(
          log: log('water', '2026-03-11', count: 1),
          queuedAt: _at,
        ),
      ]);
      expect(queue, hasLength(2));
    });

    test('editing a habit that has not been created folds into the create', () {
      final created = named('h1');
      final queue = fold([
        CreateHabit(habit: created, queuedAt: _at),
        UpdateHabit(
          habit: created.copyWith(name: 'Read more'),
          name: 'Read more',
          queuedAt: _at,
        ),
      ]);

      expect(queue, hasLength(1));
      expect(queue.single, isA<CreateHabit>());
      expect((queue.single as CreateHabit).habit.name, 'Read more');
    });

    test('two edits to the same habit leave only the newest', () {
      final existing = named('h1');
      final queue = fold([
        UpdateHabit(
          habit: existing.copyWith(name: 'One'),
          name: 'One',
          queuedAt: _at,
        ),
        UpdateHabit(
          habit: existing.copyWith(name: 'Two'),
          name: 'Two',
          queuedAt: _at.add(const Duration(seconds: 5)),
        ),
      ]);

      expect(queue, hasLength(1));
      expect((queue.single as UpdateHabit).habit.name, 'Two');
    });

    test('archiving an unsent habit drops the create rather than sending it', () {
      final queue = fold([
        CreateHabit(habit: named('h1'), queuedAt: _at),
        ArchiveHabit(habitId: 'h1', name: 'h1', queuedAt: _at),
      ]);
      expect(queue, isEmpty);
    });

    test('archiving a habit the server has still sends the archive', () {
      final queue = fold([
        ArchiveHabit(habitId: 'h1', name: 'h1', queuedAt: _at),
      ]);
      expect(queue, hasLength(1));
      expect(queue.single, isA<ArchiveHabit>());
    });

    test('only the latest ordering is kept', () {
      final queue = fold([
        ReorderHabits(ids: const ['a', 'b'], queuedAt: _at),
        ReorderHabits(ids: const ['b', 'a'], queuedAt: _at),
      ]);
      expect(queue, hasLength(1));
      expect((queue.single as ReorderHabits).ids, ['b', 'a']);
    });
  });

  group('remapHabitId', () {
    test('repoints every queued write at the id the server chose', () {
      final queue = remapHabitId(
        fold([
          CreateHabit(habit: named('local'), queuedAt: _at),
          WriteHabitLog(
            log: log('local', '2026-03-11', count: 1),
            queuedAt: _at,
          ),
          ReorderHabits(ids: const ['local', 'other'], queuedAt: _at),
        ]),
        'local',
        'server',
      );

      expect((queue[0] as CreateHabit).habit.id, 'server');
      expect((queue[1] as WriteHabitLog).log.habitId, 'server');
      expect((queue[2] as ReorderHabits).ids, ['server', 'other']);
    });

    test('leaves everything else alone', () {
      final queue = remapHabitId(
        fold([
          WriteHabitLog(
            log: log('other', '2026-03-11', count: 1),
            queuedAt: _at,
          ),
        ]),
        'local',
        'server',
      );
      expect((queue.single as WriteHabitLog).log.habitId, 'other');
    });
  });

  group('round trips', () {
    test('every mutation survives being written and read back', () {
      final mutations = <HabitMutation>[
        CreateHabit(habit: named('h1'), queuedAt: _at),
        UpdateHabit(habit: named('h1'), name: 'h1', queuedAt: _at),
        ArchiveHabit(habitId: 'h1', name: 'h1', queuedAt: _at),
        ReorderHabits(ids: const ['h1', 'h2'], queuedAt: _at),
        WriteHabitLog(
          log: log('h1', '2026-03-11', count: 2, seconds: 60),
          queuedAt: _at,
        ),
      ];

      for (final mutation in mutations) {
        final restored = HabitMutation.fromJson(mutation.toJson());
        expect(restored, isNotNull, reason: '${mutation.runtimeType}');
        expect(restored!.runtimeType, mutation.runtimeType);
        expect(restored.subjectId, mutation.subjectId);
        // Read back in UTC, as every other queue does; the instant is what
        // the replay order is decided on, not the zone it is spelled in.
        expect(
          restored.queuedAt.isAtSameMomentAs(mutation.queuedAt),
          isTrue,
          reason: '${mutation.runtimeType}',
        );
      }
    });

    test('an op from a newer build is skipped rather than crashing', () {
      expect(
        HabitMutation.fromJson({
          'op': 'somethingNew',
          'queuedAt': _at.toIso8601String(),
        }),
        isNull,
      );
    });

    test('describes a write in the user\'s own terms', () {
      expect(
        CreateHabit(habit: named('Read'), queuedAt: _at).describe(),
        'the habit Read',
      );
      expect(
        WriteHabitLog(
          log: log('h1', '2026-03-11'),
          queuedAt: _at,
        ).describe(),
        "2026-03-11's progress",
      );
    });
  });
}
