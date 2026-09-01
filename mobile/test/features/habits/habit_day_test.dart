import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/habits/data/tracked_time.dart';
import 'package:luqa/features/habits/domain/habit.dart';
import 'package:luqa/features/habits/domain/habit_day.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

import 'habit_schedule_test.dart' show habit;

Habit named(
  String id, {
  HabitScheduleType scheduleType = HabitScheduleType.daily,
  int intervalDays = 2,
  bool intervalFromLastDone = false,
  String? anchorDate,
  HabitGoalType goalType = HabitGoalType.task,
  HabitGoalPeriod goalPeriod = HabitGoalPeriod.day,
  int targetCount = 1,
  int targetSeconds = 0,
  int timesPerPeriod = 3,
  String? categoryId,
  int order = 0,
  bool archived = false,
}) => Habit(
  id: id,
  name: id,
  icon: null,
  colorValue: 0xFFF5C451,
  order: order,
  goalType: goalType,
  goalPeriod: goalPeriod,
  targetCount: targetCount,
  targetSeconds: targetSeconds,
  categoryId: categoryId,
  scheduleType: scheduleType,
  weekdays: const [],
  weekInterval: 1,
  intervalDays: intervalDays,
  intervalFromLastDone: intervalFromLastDone,
  timesPerPeriod: timesPerPeriod,
  anchorDate: anchorDate,
  dates: const [],
  excludedDates: const [],
  archived: archived,
  createdAt: DateTime(2026, 1, 1),
);

HabitLog log(
  String habitId,
  String date, {
  int count = 0,
  int seconds = 0,
  DateTime? runningSince,
  DateTime? completedAt,
}) => HabitLog(
  habitId: habitId,
  date: date,
  count: count,
  seconds: seconds,
  runningSince: runningSince,
  completedAt: completedAt,
);

HabitDayFacts factsWith(List<HabitLog> logs) =>
    HabitDayFacts(logs: {for (final l in logs) '${l.habitId}|${l.date}': l});

void main() {
  const wednesday = '2026-03-11';

  group('resolveHabitDay', () {
    test('leaves out habits that are not due, and archived ones', () {
      final due = named('due');
      final notDue = named('notDue', scheduleType: HabitScheduleType.dates);
      final gone = named('gone', archived: true);

      final day = resolveHabitDay(
        habits: [due, notDue, gone],
        dateKey: wednesday,
        facts: const HabitDayFacts(),
      );

      expect(day.map((entry) => entry.id), ['due']);
    });

    test('reads a count from the day\'s own log', () {
      final water = named('water', goalType: HabitGoalType.count, targetCount: 4);
      final day = resolveHabitDay(
        habits: [water],
        dateKey: wednesday,
        facts: factsWith([log('water', wednesday, count: 3)]),
      ).single;

      expect(day.count, 3);
      expect(day.done, isFalse);
      expect(day.liveFraction(DateTime(2026, 3, 11, 9)), 0.75);
    });

    test('a running timer counts toward the goal as it runs', () {
      final focus = named(
        'focus',
        goalType: HabitGoalType.time,
        targetSeconds: 600,
      );
      final startedAt = DateTime(2026, 3, 11, 9);
      final day = resolveHabitDay(
        habits: [focus],
        dateKey: wednesday,
        facts: factsWith([log('focus', wednesday, runningSince: startedAt)]),
        now: startedAt.add(const Duration(minutes: 11)),
      ).single;

      // Nothing has been banked yet — the elapsed time is what completes it.
      expect(day.seconds, 0);
      expect(day.isRunning, isTrue);
      expect(day.done, isTrue);
      expect(day.liveSeconds(startedAt.add(const Duration(minutes: 11))), 660);
    });

    test('a weekly duration goal sums the whole week, not the day', () {
      final exercise = named(
        'exercise',
        goalType: HabitGoalType.time,
        goalPeriod: HabitGoalPeriod.week,
        targetSeconds: 3600,
      );
      final day = resolveHabitDay(
        habits: [exercise],
        dateKey: wednesday,
        facts: factsWith([
          // Monday and Tuesday of the same week.
          log('exercise', '2026-03-09', seconds: 1500),
          log('exercise', '2026-03-10', seconds: 2200),
          // The Sunday before, which is a different week.
          log('exercise', '2026-03-08', seconds: 9000),
        ]),
      ).single;

      expect(day.seconds, 3700);
      expect(day.done, isTrue);
    });

    test('a quota counts the days completed in its period', () {
      final gym = named(
        'gym',
        scheduleType: HabitScheduleType.timesPerWeek,
        timesPerPeriod: 3,
      );
      final day = resolveHabitDay(
        habits: [gym],
        dateKey: wednesday,
        facts: factsWith([
          log('gym', '2026-03-09', count: 1),
          log('gym', '2026-03-10', count: 1),
          // Last week — outside the period, and must not be counted.
          log('gym', '2026-03-06', count: 1),
        ]),
      ).single;

      expect(day.periodDone, 2);
      expect(day.periodTarget, 3);
      // Today itself is still open; the quota is about the week, not the day.
      expect(day.done, isFalse);
    });

    test('a category-linked habit reads tracked time, not its own log', () {
      final focus = named(
        'focus',
        goalType: HabitGoalType.time,
        targetSeconds: 1800,
        categoryId: 'deep-work',
      );
      final facts = habitDayFacts(
        logs: const [],
        entries: [
          TimeEntry(
            id: 'e1',
            description: 'Deep work',
            categoryId: 'deep-work',
            start: DateTime(2026, 3, 11, 9),
            end: DateTime(2026, 3, 11, 9, 40),
          ),
          // A different category, which this habit knows nothing about.
          TimeEntry(
            id: 'e2',
            description: 'Email',
            categoryId: 'admin',
            start: DateTime(2026, 3, 11, 10),
            end: DateTime(2026, 3, 11, 11),
          ),
        ],
        dayStartHour: 3,
      );

      final day = resolveHabitDay(
        habits: [focus],
        dateKey: wednesday,
        facts: facts,
      ).single;

      expect(day.seconds, 40 * 60);
      expect(day.done, isTrue);
    });

    test('a running block on the linked category keeps the ring live', () {
      final focus = named(
        'focus',
        goalType: HabitGoalType.time,
        targetSeconds: 1800,
        categoryId: 'deep-work',
      );
      final startedAt = DateTime(2026, 3, 11, 9);
      final facts = habitDayFacts(
        logs: const [],
        entries: [
          TimeEntry(
            id: 'e1',
            description: 'Deep work',
            categoryId: 'deep-work',
            start: startedAt,
            end: null,
          ),
        ],
        dayStartHour: 3,
      );

      final day = resolveHabitDay(
        habits: [focus],
        dateKey: wednesday,
        facts: facts,
        now: startedAt.add(const Duration(minutes: 31)),
      ).single;

      expect(day.isRunning, isTrue);
      expect(day.done, isTrue);
    });
  });

  group('a rolling interval, through the resolver', () {
    // Shave every second day, starting Monday the 9th.
    Habit shave() => named(
      'shave',
      scheduleType: HabitScheduleType.interval,
      intervalDays: 2,
      intervalFromLastDone: true,
      anchorDate: '2026-03-09',
    );

    List<String> dueOn(List<String> days, HabitDayFacts facts) => [
      for (final day in days)
        if (resolveHabitDay(
          habits: [shave()],
          dateKey: day,
          facts: facts,
        ).isNotEmpty)
          day,
    ];

    const week = [
      '2026-03-09',
      '2026-03-10',
      '2026-03-11',
      '2026-03-12',
      '2026-03-13',
      '2026-03-14',
    ];

    test('keeping up leaves every other day due', () {
      final facts = factsWith([
        log('shave', '2026-03-09', count: 1),
        log('shave', '2026-03-11', count: 1),
        log('shave', '2026-03-13', count: 1),
      ]);
      expect(dueOn(week, facts), [
        '2026-03-09',
        '2026-03-11',
        '2026-03-13',
      ]);
    });

    test('missing a turn shifts every turn after it', () {
      // Shaved Monday, missed Wednesday, shaved Thursday instead.
      final facts = factsWith([
        log('shave', '2026-03-09', count: 1),
        log('shave', '2026-03-12', count: 1),
      ]);
      expect(dueOn(week, facts), [
        '2026-03-09',
        // Wednesday was due and went by, and Thursday still asked.
        '2026-03-11',
        '2026-03-12',
        // From Thursday the cycle counts from Thursday: Friday off,
        // Saturday due. The original odd days are gone.
        '2026-03-14',
      ]);
    });

    test('the day it was done still shows, with its tick', () {
      final facts = factsWith([log('shave', '2026-03-12', count: 1)]);
      final day = resolveHabitDay(
        habits: [shave()],
        dateKey: '2026-03-12',
        facts: facts,
      ).single;
      expect(day.done, isTrue);
    });

    test('a streak survives the shift, and a missed turn breaks it', () {
      final kept = resolveHabitStats(
        habits: [shave()],
        from: '2026-03-09',
        to: '2026-03-13',
        facts: factsWith([
          log('shave', '2026-03-09', count: 1),
          log('shave', '2026-03-11', count: 1),
          log('shave', '2026-03-13', count: 1),
        ]),
      ).single;
      expect(kept.scheduled, 3);
      expect(kept.streak, 3);

      final missed = resolveHabitStats(
        habits: [shave()],
        from: '2026-03-09',
        to: '2026-03-14',
        facts: factsWith([
          log('shave', '2026-03-09', count: 1),
          log('shave', '2026-03-12', count: 1),
          log('shave', '2026-03-14', count: 1),
        ]),
      ).single;
      // Wednesday counts as a day it asked and was not done.
      expect(missed.scheduled, 4);
      expect(missed.completed, 3);
      expect(missed.streak, 2);
    });
  });

  group('trackedByCategory', () {
    test('buckets a late-night block into the day it began', () {
      final tracked = trackedByCategory(
        [
          TimeEntry(
            id: 'e1',
            description: 'Reading',
            categoryId: 'books',
            // 23:30 on the 11th, running into the 12th.
            start: DateTime(2026, 3, 11, 23, 30),
            end: DateTime(2026, 3, 12, 0, 30),
          ),
        ],
        dayStartHour: 3,
      );

      expect(tracked.seconds['books|2026-03-11'], 3600);
      expect(tracked.seconds.containsKey('books|2026-03-12'), isFalse);
    });

    test('ignores blocks with no category at all', () {
      final tracked = trackedByCategory(
        [
          TimeEntry(
            id: 'e1',
            description: 'Something',
            categoryId: null,
            start: DateTime(2026, 3, 11, 9),
            end: DateTime(2026, 3, 11, 10),
          ),
        ],
        dayStartHour: 3,
      );
      expect(tracked.seconds, isEmpty);
    });

    test('keeps a running block out of the banked total', () {
      final tracked = trackedByCategory(
        [
          TimeEntry(
            id: 'e1',
            description: 'Deep work',
            categoryId: 'deep-work',
            start: DateTime(2026, 3, 11, 9),
            end: null,
          ),
        ],
        dayStartHour: 3,
      );
      expect(tracked.seconds, isEmpty);
      expect(tracked.running['deep-work'], DateTime(2026, 3, 11, 9));
    });
  });

  group('resolveHabitStats', () {
    test('counts a streak back from today', () {
      final read = named('read');
      final stats = resolveHabitStats(
        habits: [read],
        from: '2026-03-08',
        to: '2026-03-11',
        facts: factsWith([
          log('read', '2026-03-09', count: 1),
          log('read', '2026-03-10', count: 1),
          log('read', '2026-03-11', count: 1),
        ]),
      ).single;

      expect(stats.streak, 3);
      expect(stats.completed, 3);
      expect(stats.scheduled, 4);
    });

    test('a day still pending does not break the streak', () {
      final read = named('read');
      final stats = resolveHabitStats(
        habits: [read],
        from: '2026-03-08',
        to: '2026-03-11',
        facts: factsWith([
          log('read', '2026-03-09', count: 1),
          log('read', '2026-03-10', count: 1),
          // Nothing yet today.
        ]),
      ).single;

      expect(stats.streak, 2);
    });

    test('a missed day does break it', () {
      final read = named('read');
      final stats = resolveHabitStats(
        habits: [read],
        from: '2026-03-08',
        to: '2026-03-11',
        facts: factsWith([
          log('read', '2026-03-08', count: 1),
          log('read', '2026-03-11', count: 1),
        ]),
      ).single;

      expect(stats.streak, 1);
      expect(stats.bestStreak, 1);
    });

    test('days the habit was not due are absent, not failed', () {
      final weekly = habit(
        scheduleType: HabitScheduleType.weekdays,
        weekdays: const [3],
      );
      final stats = resolveHabitStats(
        habits: [weekly],
        from: '2026-03-09',
        to: '2026-03-13',
        facts: const HabitDayFacts(),
      ).single;

      // Only Wednesday the 11th.
      expect(stats.scheduled, 1);
      expect(stats.fractions.keys, ['2026-03-11']);
    });
  });
}
