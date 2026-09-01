import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/habits/domain/habit.dart';
import 'package:luqa/features/habits/domain/habit_schedule.dart';

Habit habit({
  HabitScheduleType scheduleType = HabitScheduleType.daily,
  List<int> weekdays = const [],
  int weekInterval = 1,
  int intervalDays = 2,
  int timesPerPeriod = 3,
  String? anchorDate,
  List<String> dates = const [],
  List<String> excludedDates = const [],
  HabitGoalType goalType = HabitGoalType.task,
  HabitGoalPeriod goalPeriod = HabitGoalPeriod.day,
  int targetCount = 1,
  int targetSeconds = 0,
  String? categoryId,
  DateTime? createdAt,
}) => Habit(
  id: 'h1',
  name: 'Read',
  icon: null,
  colorValue: 0xFFF5C451,
  order: 0,
  goalType: goalType,
  goalPeriod: goalPeriod,
  targetCount: targetCount,
  targetSeconds: targetSeconds,
  categoryId: categoryId,
  scheduleType: scheduleType,
  weekdays: weekdays,
  weekInterval: weekInterval,
  intervalDays: intervalDays,
  timesPerPeriod: timesPerPeriod,
  anchorDate: anchorDate,
  dates: dates,
  excludedDates: excludedDates,
  archived: false,
  createdAt: createdAt ?? DateTime(2026, 1, 1),
);

void main() {
  group('date keys', () {
    test('formats and parses a day without touching the clock', () {
      expect(dateKeyOf(DateTime(2026, 3, 7)), '2026-03-07');
      expect(parseDateKey('2026-03-07'), DateTime(2026, 3, 7));
    });

    test('counts whole days across a daylight saving boundary', () {
      // Europe loses an hour on 29 March 2026. Two dates a day apart are one
      // day apart whatever the clocks did in between.
      expect(daysBetweenKeys('2026-03-28', '2026-03-30'), 2);
      expect(daysBetweenKeys('2026-03-30', '2026-03-28'), -2);
    });

    test('adds days across a month and a year boundary', () {
      expect(addDaysToKey('2026-01-31', 1), '2026-02-01');
      expect(addDaysToKey('2026-12-31', 1), '2027-01-01');
      expect(addDaysToKey('2026-03-01', -1), '2026-02-28');
    });

    test('a late-evening instant belongs to the day that has not ended', () {
      // 01:30 with a 3am day start is still the night before.
      expect(logicalDateKey(DateTime(2026, 3, 8, 1, 30), 3), '2026-03-07');
      expect(logicalDateKey(DateTime(2026, 3, 8, 3, 30), 3), '2026-03-08');
    });
  });

  group('isScheduledOn', () {
    test('daily is due every day', () {
      expect(isScheduledOn(habit(), '2026-03-07'), isTrue);
    });

    test('an excluded date is skipped whatever the schedule says', () {
      final skipped = habit(excludedDates: const ['2026-03-07']);
      expect(isScheduledOn(skipped, '2026-03-07'), isFalse);
      expect(isScheduledOn(skipped, '2026-03-08'), isTrue);
    });

    test('weekdays uses Sunday-zero indices', () {
      // 2026-03-07 is a Saturday, 2026-03-09 a Monday.
      final weekly = habit(
        scheduleType: HabitScheduleType.weekdays,
        weekdays: const [1],
      );
      expect(isScheduledOn(weekly, '2026-03-07'), isFalse);
      expect(isScheduledOn(weekly, '2026-03-09'), isTrue);
    });

    test('a fortnightly habit skips the weeks in between', () {
      final fortnightly = habit(
        scheduleType: HabitScheduleType.weekdays,
        weekdays: const [1],
        weekInterval: 2,
        anchorDate: '2026-03-09',
      );
      expect(isScheduledOn(fortnightly, '2026-03-09'), isTrue);
      expect(isScheduledOn(fortnightly, '2026-03-16'), isFalse);
      expect(isScheduledOn(fortnightly, '2026-03-23'), isTrue);
    });

    test('interval counts forward from the anchor and never before it', () {
      final every3 = habit(
        scheduleType: HabitScheduleType.interval,
        intervalDays: 3,
        anchorDate: '2026-03-07',
      );
      expect(isScheduledOn(every3, '2026-03-06'), isFalse);
      expect(isScheduledOn(every3, '2026-03-07'), isTrue);
      expect(isScheduledOn(every3, '2026-03-09'), isFalse);
      expect(isScheduledOn(every3, '2026-03-10'), isTrue);
    });

    test('interval falls back to the day the habit was created', () {
      final every2 = habit(
        scheduleType: HabitScheduleType.interval,
        intervalDays: 2,
        createdAt: DateTime(2026, 3, 7, 21),
      );
      expect(isScheduledOn(every2, '2026-03-07'), isTrue);
      expect(isScheduledOn(every2, '2026-03-08'), isFalse);
      expect(isScheduledOn(every2, '2026-03-09'), isTrue);
    });

    test('a quota schedule is available every day', () {
      final quota = habit(scheduleType: HabitScheduleType.timesPerWeek);
      expect(isScheduledOn(quota, '2026-03-07'), isTrue);
      expect(isScheduledOn(quota, '2026-03-08'), isTrue);
    });

    test('dates are due only on the days listed', () {
      final onDates = habit(
        scheduleType: HabitScheduleType.dates,
        dates: const ['2026-03-07'],
      );
      expect(isScheduledOn(onDates, '2026-03-07'), isTrue);
      expect(isScheduledOn(onDates, '2026-03-08'), isFalse);
    });
  });

  group('periodRange', () {
    test('a week starts on the account\'s own first day', () {
      // 2026-03-11 is a Wednesday.
      final monday = periodRange(
        HabitScheduleType.timesPerWeek,
        '2026-03-11',
      );
      expect(monday.from, '2026-03-09');
      expect(monday.to, '2026-03-15');

      final sunday = periodRange(
        HabitScheduleType.timesPerWeek,
        '2026-03-11',
        weekStartsOn: 0,
      );
      expect(sunday.from, '2026-03-08');
      expect(sunday.to, '2026-03-14');
    });

    test('a month range covers a short month exactly', () {
      final february = periodRange(
        HabitScheduleType.timesPerMonth,
        '2026-02-14',
      );
      expect(february.from, '2026-02-01');
      expect(february.to, '2026-02-28');
    });

    test('a leap February gets its extra day', () {
      final leap = periodRange(HabitScheduleType.timesPerMonth, '2028-02-14');
      expect(leap.to, '2028-02-29');
    });

    test('a year range covers the calendar year', () {
      final year = periodRange(HabitScheduleType.timesPerYear, '2026-06-01');
      expect(year.from, '2026-01-01');
      expect(year.to, '2026-12-31');
    });
  });

  group('goals', () {
    test('a task is met by any progress at all', () {
      final task = habit();
      expect(isGoalMet(task, const HabitProgress(count: 0, seconds: 0)), isFalse);
      expect(isGoalMet(task, const HabitProgress(count: 1, seconds: 0)), isTrue);
    });

    test('a count is met at its target and fills proportionally', () {
      final water = habit(goalType: HabitGoalType.count, targetCount: 4);
      expect(goalFraction(water, const HabitProgress(count: 1, seconds: 0)), 0.25);
      expect(isGoalMet(water, const HabitProgress(count: 3, seconds: 0)), isFalse);
      expect(isGoalMet(water, const HabitProgress(count: 4, seconds: 0)), isTrue);
    });

    test('overshooting a count does not push the ring past full', () {
      final water = habit(goalType: HabitGoalType.count, targetCount: 4);
      expect(goalFraction(water, const HabitProgress(count: 9, seconds: 0)), 1);
    });

    test('a duration is met at its target in seconds', () {
      final focus = habit(goalType: HabitGoalType.time, targetSeconds: 1800);
      expect(isGoalMet(focus, const HabitProgress(count: 0, seconds: 1799)), isFalse);
      expect(isGoalMet(focus, const HabitProgress(count: 0, seconds: 1800)), isTrue);
    });

    test('a zero target cannot make every day complete by default', () {
      // A misconfigured target of zero would otherwise be met by no progress
      // at all, which would silently mark every day done.
      final broken = habit(goalType: HabitGoalType.count, targetCount: 0);
      expect(isGoalMet(broken, const HabitProgress(count: 0, seconds: 0)), isFalse);
    });
  });

  group('scheduleSummary', () {
    test('names the common weekday sets rather than listing them', () {
      expect(
        scheduleSummary(
          habit(
            scheduleType: HabitScheduleType.weekdays,
            weekdays: const [1, 2, 3, 4, 5],
          ),
        ),
        'Weekdays',
      );
      expect(
        scheduleSummary(
          habit(
            scheduleType: HabitScheduleType.weekdays,
            weekdays: const [0, 6],
          ),
        ),
        'Weekends',
      );
      expect(
        scheduleSummary(
          habit(
            scheduleType: HabitScheduleType.weekdays,
            weekdays: const [1, 3, 5],
          ),
        ),
        'Mon, Wed, Fri',
      );
    });

    test('mentions the interval only when there is one', () {
      expect(
        scheduleSummary(
          habit(
            scheduleType: HabitScheduleType.weekdays,
            weekdays: const [1],
            weekInterval: 2,
          ),
        ),
        'Mon · every 2w',
      );
    });

    test('describes the quota schedules', () {
      expect(
        scheduleSummary(
          habit(
            scheduleType: HabitScheduleType.timesPerWeek,
            timesPerPeriod: 3,
          ),
        ),
        '3× per week',
      );
    });
  });
}
