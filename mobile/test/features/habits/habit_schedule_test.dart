import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/habits/domain/habit.dart';
import 'package:luqa/features/habits/domain/habit_schedule.dart';

Habit habit({
  HabitScheduleType scheduleType = HabitScheduleType.daily,
  List<int> weekdays = const [],
  int weekInterval = 1,
  int intervalDays = 2,
  bool intervalFromLastDone = false,
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
  intervalFromLastDone: intervalFromLastDone,
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

    test('a fixed interval keeps its grid however it actually went', () {
      final shave = habit(
        scheduleType: HabitScheduleType.interval,
        intervalDays: 2,
        anchorDate: '2026-03-09',
      );
      // Done on the 9th and the 12th; the grid does not care.
      done(String key) => key == '2026-03-09' || key == '2026-03-12';

      expect(isScheduledOn(shave, '2026-03-11', doneOn: done), isTrue);
      // The day after doing it, the fixed grid still says yes — which is the
      // behaviour a rolling interval exists to replace.
      expect(isScheduledOn(shave, '2026-03-13', doneOn: done), isTrue);
    });

    group('a rolling interval', () {
      final shave = habit(
        scheduleType: HabitScheduleType.interval,
        intervalDays: 2,
        intervalFromLastDone: true,
        anchorDate: '2026-03-09',
      );

      test('is due from the anchor when it has never been done', () {
        bool never(String key) => false;
        expect(isScheduledOn(shave, '2026-03-08', doneOn: never), isFalse);
        expect(isScheduledOn(shave, '2026-03-09', doneOn: never), isTrue);
        // Overdue means due again tomorrow, not due again in two days.
        expect(isScheduledOn(shave, '2026-03-10', doneOn: never), isTrue);
      });

      test('rests the day after it was done, and comes back the next', () {
        done(String key) => key == '2026-03-09';
        expect(isScheduledOn(shave, '2026-03-09', doneOn: done), isTrue);
        expect(isScheduledOn(shave, '2026-03-10', doneOn: done), isFalse);
        expect(isScheduledOn(shave, '2026-03-11', doneOn: done), isTrue);
      });

      test('shifts the whole cycle when a turn is missed', () {
        // Shaved Monday the 9th, missed Wednesday, shaved Thursday the 12th.
        done(String key) => key == '2026-03-09' || key == '2026-03-12';

        // Wednesday was due and went by.
        expect(isScheduledOn(shave, '2026-03-11', doneOn: done), isTrue);
        // Thursday was still due — an overdue habit keeps asking.
        expect(isScheduledOn(shave, '2026-03-12', doneOn: done), isTrue);
        // And from there the cycle counts from Thursday, not from Monday.
        expect(isScheduledOn(shave, '2026-03-13', doneOn: done), isFalse);
        expect(isScheduledOn(shave, '2026-03-14', doneOn: done), isTrue);
      });

      test('still shows on the day it was done', () {
        // Otherwise ticking a habit would make it vanish out of the list it
        // was ticked in.
        done(String key) => key == '2026-03-10';
        expect(isScheduledOn(shave, '2026-03-10', doneOn: done), isTrue);
      });

      test('looks back the whole interval, not just one day', () {
        final weekly = habit(
          scheduleType: HabitScheduleType.interval,
          intervalDays: 4,
          intervalFromLastDone: true,
          anchorDate: '2026-03-09',
        );
        done(String key) => key == '2026-03-10';
        expect(isScheduledOn(weekly, '2026-03-11', doneOn: done), isFalse);
        expect(isScheduledOn(weekly, '2026-03-12', doneOn: done), isFalse);
        expect(isScheduledOn(weekly, '2026-03-13', doneOn: done), isFalse);
        expect(isScheduledOn(weekly, '2026-03-14', doneOn: done), isTrue);
      });

      test('never looks behind the anchor', () {
        final monthly = habit(
          scheduleType: HabitScheduleType.interval,
          intervalDays: 30,
          intervalFromLastDone: true,
          anchorDate: '2026-03-09',
        );
        var asked = <String>[];
        bool record(String key) {
          asked.add(key);
          return false;
        }

        expect(isScheduledOn(monthly, '2026-03-11', doneOn: record), isTrue);
        // The day itself, then back only as far as the anchor.
        expect(asked, ['2026-03-11', '2026-03-10', '2026-03-09']);
      });

      test('an excluded date still wins', () {
        final skipped = habit(
          scheduleType: HabitScheduleType.interval,
          intervalDays: 2,
          intervalFromLastDone: true,
          anchorDate: '2026-03-09',
          excludedDates: const ['2026-03-11'],
        );
        bool never(String key) => false;
        expect(isScheduledOn(skipped, '2026-03-11', doneOn: never), isFalse);
      });

      test('with no history it nags rather than hiding', () {
        // A caller that cannot answer "was it done" gets the habit shown, not
        // silently dropped from a day it may well be due on.
        expect(isScheduledOn(shave, '2026-03-13'), isTrue);
      });

      test('reports how far back deciding a day can need to look', () {
        expect(shave.rollingLookbackDays, 2);
        expect(
          habit(
            scheduleType: HabitScheduleType.interval,
            intervalDays: 2,
          ).rollingLookbackDays,
          0,
        );
        expect(habit().rollingLookbackDays, 0);
      });
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

    test('says which end an interval is counted from', () {
      expect(
        scheduleSummary(
          habit(scheduleType: HabitScheduleType.interval, intervalDays: 2),
        ),
        'Every 2 days',
      );
      expect(
        scheduleSummary(
          habit(
            scheduleType: HabitScheduleType.interval,
            intervalDays: 2,
            intervalFromLastDone: true,
          ),
        ),
        'Every 2 days · from the last',
      );
      // Counted from either end, every day is every day.
      expect(
        scheduleSummary(
          habit(
            scheduleType: HabitScheduleType.interval,
            intervalDays: 1,
            intervalFromLastDone: true,
          ),
        ),
        'Every day',
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
