import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/insights/domain/insights_math.dart';
import 'package:luqa/features/insights/domain/insights_models.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

const _categories = [
  Category(id: 'work', name: 'Work', colorValue: 0xFF6543E8),
  Category(id: 'food', name: 'Food', colorValue: 0xFFB45309),
];

/// Thursday, mid-afternoon.
final _now = DateTime(2026, 8, 27, 15);

TimeEntry _entry(
  String id,
  DateTime start,
  Duration length, {
  String? categoryId = 'work',
  String description = 'Work',
  List<String> personIds = const [],
}) => TimeEntry(
  id: id,
  description: description,
  categoryId: categoryId,
  start: start,
  end: start.add(length),
  personIds: personIds,
);

SleepEntry _night(DateTime start, DateTime end, {DateTime? midpoint}) =>
    SleepEntry(
      id: 'sleep-${start.toIso8601String()}',
      source: 'HEALTH_CONNECT',
      sourceApp: null,
      title: null,
      start: start,
      end: end,
      sleepMinutes: end.difference(start).inMinutes,
      awakeMinutes: 0,
      lightMinutes: null,
      deepMinutes: null,
      remMinutes: null,
      isNap: false,
      midpoint: midpoint ?? start.add(end.difference(start) ~/ 2),
    );

InsightsReport _report({
  InsightsSpan span = InsightsSpan.week,
  List<TimeEntry> entries = const [],
  List<SleepEntry> sleep = const [],
  int offset = 0,
}) {
  final range = insightsRange(span: span, now: _now, offset: offset);
  return buildInsightsReport(
    span: span,
    from: range.from,
    to: range.to,
    entries: entries,
    sleep: sleep,
    categories: _categories,
    now: _now,
  );
}

void main() {
  group('insightsRange', () {
    test('a week runs from its own Monday to the next', () {
      final range = insightsRange(span: InsightsSpan.week, now: _now);
      expect(range.from, DateTime(2026, 8, 24));
      expect(range.to, DateTime(2026, 8, 31));
    });

    test('stepping back moves by whole spans, not by weeks', () {
      final week = insightsRange(
        span: InsightsSpan.week,
        now: _now,
        offset: -1,
      );
      expect(week.from, DateTime(2026, 8, 17));
      expect(week.to, DateTime(2026, 8, 24));

      final quarter = insightsRange(
        span: InsightsSpan.twelveWeeks,
        now: _now,
        offset: -1,
      );
      expect(quarter.to, DateTime(2026, 6, 8));
      expect(quarter.from, DateTime(2026, 3, 16));
    });

    test('a Sunday-start account still gets whole weeks', () {
      final range = insightsRange(
        span: InsightsSpan.week,
        now: _now,
        weekStartsOn: 0,
      );
      expect(range.from, DateTime(2026, 8, 23));
      expect(range.to, DateTime(2026, 8, 30));
    });
  });

  group('buildInsightsReport', () {
    test('a span is one column per day, marked past, present and future', () {
      final report = _report();
      expect(report.days, hasLength(7));
      expect(report.days.first.day, DateTime(2026, 8, 24));
      expect(report.days.where((day) => day.isToday), hasLength(1));
      // Monday to Thursday have happened; Friday to Sunday have not.
      expect(report.days.where((day) => day.isFuture), hasLength(3));
      expect(report.elapsedDays, 4);
    });

    test('a block crossing the day start is split at it, not lost', () {
      final report = _report(
        entries: [
          _entry(
            'night-shift',
            DateTime(2026, 8, 25, 23),
            const Duration(hours: 6),
          ),
        ],
      );

      final tuesday = report.dayFor(DateTime(2026, 8, 25))!;
      final wednesday = report.dayFor(DateTime(2026, 8, 26))!;
      // 23:00 to 03:00 belongs to Tuesday; 03:00 to 05:00 to Wednesday.
      expect(tuesday.trackedMinutes, 240);
      expect(wednesday.trackedMinutes, 120);
      expect(report.trackedMinutes, 360);
    });

    test('the longest stretch is the whole block, not the day it fits in', () {
      final report = _report(
        entries: [
          _entry(
            'night-shift',
            DateTime(2026, 8, 25, 23),
            const Duration(hours: 6),
            description: 'Night shift',
          ),
          _entry('morning', DateTime(2026, 8, 24, 9), const Duration(hours: 5)),
        ],
      );

      expect(report.facts.longestBlock?.description, 'Night shift');
      expect(report.facts.longestBlock?.minutes, 360);
      expect(report.facts.longestBlock?.day, DateTime(2026, 8, 25));
    });

    test('the previous span is counted from the same rows', () {
      final report = _report(
        entries: [
          // This week.
          _entry('a', DateTime(2026, 8, 24, 9), const Duration(hours: 3)),
          // Last week, so it belongs to the comparison rather than the total.
          _entry('b', DateTime(2026, 8, 18, 9), const Duration(hours: 1)),
          // Two weeks back, outside both.
          _entry('c', DateTime(2026, 8, 11, 9), const Duration(hours: 9)),
        ],
      );

      expect(report.trackedMinutes, 180);
      expect(report.previousTrackedMinutes, 60);
      expect(report.delta, 120);
    });

    test('nothing to compare against reads as no comparison, not as zero', () {
      final report = _report(
        entries: [
          _entry('a', DateTime(2026, 8, 24, 9), const Duration(hours: 3)),
        ],
      );
      expect(report.delta, isNull);
    });

    test('categories rank by time and carry what they were before', () {
      final report = _report(
        entries: [
          _entry('a', DateTime(2026, 8, 24, 9), const Duration(hours: 3)),
          _entry(
            'b',
            DateTime(2026, 8, 24, 13),
            const Duration(hours: 4),
            categoryId: 'food',
          ),
          _entry('c', DateTime(2026, 8, 17, 9), const Duration(hours: 5)),
        ],
      );

      expect(report.standings.map((s) => s.name), ['Food', 'Work']);
      expect(report.standings.first.isNew, isTrue);
      expect(report.standings.last.previousMinutes, 300);
      expect(report.standings.last.delta, -120);
    });

    test('a category you stopped keeps its place, at zero', () {
      final report = _report(
        entries: [
          _entry('now', DateTime(2026, 8, 24, 9), const Duration(hours: 2)),
          _entry(
            'then',
            DateTime(2026, 8, 18, 9),
            const Duration(hours: 5),
            categoryId: 'food',
          ),
        ],
      );

      expect(report.standings.map((s) => s.name), ['Work', 'Food']);
      final dropped = report.standings.last;
      expect(dropped.minutes, 0);
      expect(dropped.delta, -300);
    });

    test('a block with no category is named rather than dropped', () {
      final report = _report(
        entries: [
          _entry(
            'a',
            DateTime(2026, 8, 24, 9),
            const Duration(hours: 1),
            categoryId: null,
          ),
        ],
      );
      expect(report.standings.single.name, 'Uncategorised');
      expect(report.standings.single.colorValue, isNull);
    });

    test('sleep under a tracked block is accounted for once', () {
      final report = _report(
        entries: [
          _entry('a', DateTime(2026, 8, 24, 6), const Duration(hours: 2)),
        ],
        sleep: [_night(DateTime(2026, 8, 24, 4), DateTime(2026, 8, 24, 7))],
      );

      final monday = report.dayFor(DateTime(2026, 8, 24))!;
      expect(monday.trackedMinutes, 120);
      expect(monday.sleepMinutes, 180);
      // 04:00 to 08:00 with the hour of overlap counted once.
      expect(monday.accountedMinutes, 240);
    });

    test('the day shape ignores what only spilled into the day', () {
      final report = _report(
        entries: [
          // Begun on Monday, still running at the Tuesday boundary.
          _entry('spill', DateTime(2026, 8, 24, 23), const Duration(hours: 5)),
          _entry('tue', DateTime(2026, 8, 25, 9), const Duration(hours: 2)),
        ],
      );

      // Tuesday's first block began at 09:00. Reading the spill's clipped edge
      // would have reported the day as starting at the day boundary instead.
      expect(report.facts.typicalStartMinutes, (23 * 60 + 9 * 60) / 2);
    });
  });

  group('facts', () {
    test('the fullest hour is by the clock, across the whole span', () {
      final report = _report(
        entries: [
          _entry('a', DateTime(2026, 8, 24, 9, 30), const Duration(hours: 1)),
          _entry('b', DateTime(2026, 8, 25, 9, 30), const Duration(hours: 1)),
          _entry('c', DateTime(2026, 8, 26, 14), const Duration(hours: 1)),
        ],
      );
      // 09:30–10:30 twice puts thirty minutes in 09 and thirty in 10 on each
      // day; the hour that wins is the one with the most in it overall.
      expect(report.facts.fullestHour, anyOf(9, 10));
      expect(report.facts.fullestHourMinutes, 60);
    });

    test('the sleep midpoint averages around the night, not around noon', () {
      final report = _report(
        sleep: [
          _night(DateTime(2026, 8, 24, 23, 30), DateTime(2026, 8, 25, 7, 30)),
          _night(DateTime(2026, 8, 25, 0, 30), DateTime(2026, 8, 25, 8, 30)),
        ],
      );
      // Midpoints of 03:30 and 04:30 average to 04:00. A plain mean of the two
      // clock readings would have landed in the afternoon.
      expect(report.facts.sleepMidpointMinutes, 4 * 60);
      expect(report.facts.nights, 2);
    });

    test('weekend drift needs both kinds of night to exist', () {
      // The week before, so both a working night and a Friday one have
      // already happened.
      final monday = _night(
        DateTime(2026, 8, 17, 23),
        DateTime(2026, 8, 18, 7),
      );
      // One in the morning on the Saturday is the Friday night going late,
      // and is counted against the day it was begun on rather than the date
      // the clock had reached.
      final friday = _night(DateTime(2026, 8, 22, 1), DateTime(2026, 8, 22, 9));

      final weekdayOnly = _report(offset: -1, sleep: [monday]);
      expect(weekdayOnly.facts.weekendMidpointDrift, isNull);
      expect(weekdayOnly.facts.nights, 1);

      final both = _report(offset: -1, sleep: [monday, friday]);
      // Midpoints of 03:00 and 05:00.
      expect(both.facts.weekendMidpointDrift, 120);
    });

    test('a day with someone tagged is counted as company', () {
      final report = _report(
        entries: [
          _entry(
            'a',
            DateTime(2026, 8, 24, 19),
            const Duration(hours: 2),
            personIds: const ['mara'],
          ),
          _entry('b', DateTime(2026, 8, 25, 9), const Duration(hours: 2)),
        ],
      );
      expect(report.facts.daysWithCompany, 1);
      expect(report.dayFor(DateTime(2026, 8, 24))!.hasCompany, isTrue);
      expect(report.dayFor(DateTime(2026, 8, 25))!.hasCompany, isFalse);
    });

    test('accounting is against the time that has passed, not the span', () {
      // Four full logical days would be 5760 minutes; today has only run from
      // 03:00 to 15:00, so the elapsed span is 3 x 1440 + 720.
      final report = _report(
        entries: [
          for (var day = 24; day <= 27; day++)
            _entry(
              'd$day',
              DateTime(2026, 8, day, 9),
              const Duration(hours: 1),
            ),
        ],
      );
      expect(report.facts.accountedFraction, closeTo(240 / 5040, 0.0001));
    });

    test('the busiest weekday is an average, not a total', () {
      // Two Mondays of one hour each against a single Tuesday of ninety
      // minutes: Monday has more time in it, Tuesday is the heavier day.
      final report = _report(
        span: InsightsSpan.fourWeeks,
        entries: [
          _entry('m1', DateTime(2026, 8, 10, 9), const Duration(hours: 1)),
          _entry('m2', DateTime(2026, 8, 17, 9), const Duration(hours: 1)),
          _entry('t1', DateTime(2026, 8, 11, 9), const Duration(minutes: 90)),
        ],
      );
      expect(report.facts.busiestWeekday, DateTime.tuesday);
      expect(report.facts.busiestWeekdayMinutes, 90);
    });

    test('a single week has no busiest weekday to report', () {
      final report = _report(
        entries: [
          _entry('a', DateTime(2026, 8, 24, 9), const Duration(hours: 3)),
        ],
      );
      expect(report.facts.busiestWeekday, isNull);
    });
  });

  group('standingsForDay', () {
    test('splits one day by category, keeping the span colours', () {
      final report = _report(
        entries: [
          _entry('a', DateTime(2026, 8, 24, 9), const Duration(hours: 3)),
          _entry(
            'b',
            DateTime(2026, 8, 24, 13),
            const Duration(hours: 1),
            categoryId: 'food',
          ),
          _entry('c', DateTime(2026, 8, 25, 9), const Duration(hours: 8)),
        ],
      );

      final monday = standingsForDay(
        report.dayFor(DateTime(2026, 8, 24))!,
        report.standings,
      );
      expect(monday.map((s) => s.name), ['Work', 'Food']);
      expect(monday.first.minutes, 180);
      expect(monday.first.colorValue, 0xFF6543E8);
      // The span's own comparison does not belong to a single day inside it.
      expect(monday.first.previousMinutes, 0);
    });
  });
}
