import 'dart:math' as math;

import 'package:luqa/features/insights/domain/insights_models.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa/features/today/domain/timeline_geometry.dart';

/// Local midnight of the week [value] falls in.
///
/// [weekStartsOn] follows the account setting: 0 is Sunday, 1 is Monday.
DateTime startOfWeek(DateTime value, {int weekStartsOn = 1}) {
  final day = startOfDay(value);
  // DateTime.weekday is 1..7 with Monday first; the setting counts from
  // Sunday, so both are moved onto the same 0..6 scale before subtracting.
  final index = day.weekday % 7;
  final delta = (index - weekStartsOn % 7 + 7) % 7;
  return addDays(day, -delta);
}

/// The half-open range of logical days one screen of Insights covers.
///
/// [offset] steps whole spans into the past; 0 is the span containing today.
/// The range always ends on a week boundary, so the newest span runs to the
/// end of the current week and its last days are simply empty until they
/// happen — a week that redrew itself narrower every morning would make the
/// wall impossible to compare against last week's.
({DateTime from, DateTime to}) insightsRange({
  required InsightsSpan span,
  required DateTime now,
  int offset = 0,
  int weekStartsOn = 1,
  int startHour = dayStartHour,
}) {
  final today = startOfLogicalDay(now, startHour);
  final currentWeek = startOfWeek(today, weekStartsOn: weekStartsOn);
  final to = addDays(currentWeek, 7 * (1 + span.weeks * offset));
  return (from: addDays(to, -span.days), to: to);
}

/// Everything Insights needs about one span, from this device's own rows.
///
/// [entries] and [sleep] should cover the previous span as well, so the
/// comparison beside every number comes from the same read rather than from a
/// second one that could disagree with it.
InsightsReport buildInsightsReport({
  required InsightsSpan span,
  required DateTime from,
  required DateTime to,
  required List<TimeEntry> entries,
  required List<SleepEntry> sleep,
  required List<Category> categories,
  required DateTime now,
  int startHour = dayStartHour,
}) {
  final colors = {for (final category in categories) category.id: category};
  final today = startOfLogicalDay(now, startHour);
  final previousFrom = addDays(from, -span.days);

  // Bucketed by every logical day they touch, in one pass, so a twelve-week
  // wall is one walk over the rows rather than eighty-four of them. A block
  // that runs past midnight lands in both of its days and is clipped inside
  // each.
  final entriesByDay = <int, List<TimeEntry>>{};
  final sleepByDay = <int, List<SleepEntry>>{};

  final days = <RhythmDay>[];
  final trackedByCategory = <String?, double>{};
  final previousByCategory = <String?, double>{};
  final byHour = List<double>.filled(24, 0);
  final byWeekday = List<double>.filled(8, 0);
  final weekdayCounts = List<int>.filled(8, 0);

  var trackedMinutes = 0.0;
  var previousTrackedMinutes = 0.0;
  var sleepMinutes = 0.0;
  var accountedMinutes = 0.0;
  var elapsedMinutes = 0.0;
  var elapsedDays = 0;
  var daysTracked = 0;
  var daysWithCompany = 0;
  var weekendMinutes = 0.0;

  final starts = <double>[];
  final ends = <double>[];
  TrackedHighlight? longest;

  final previousStart = DateTime(
    previousFrom.year,
    previousFrom.month,
    previousFrom.day,
    startHour,
  );
  final spanStart = DateTime(from.year, from.month, from.day, startHour);

  for (final entry in entries) {
    final end = entry.end ?? now;
    if (!end.isAfter(entry.start)) continue;
    _bucket(entriesByDay, entry, entry.start, end, from, to, startHour);

    // The previous span is only ever a total, so it is folded in on the way
    // past rather than by building a second wall nobody looks at.
    final overlap = _overlapMinutes(entry.start, end, previousStart, spanStart);
    if (overlap > 0) {
      previousTrackedMinutes += overlap;
      previousByCategory[entry.categoryId] =
          (previousByCategory[entry.categoryId] ?? 0) + overlap;
    }
  }
  for (final session in sleep) {
    if (!session.end.isAfter(session.start)) continue;
    _bucket(
      sleepByDay,
      session,
      session.start,
      session.end,
      from,
      to,
      startHour,
    );
  }

  for (var day = from; day.isBefore(to); day = addDays(day, 1)) {
    final dayStart = DateTime(day.year, day.month, day.day, startHour);
    final dayEnd = DateTime(day.year, day.month, day.day + 1, startHour);
    final spanMinutes = dayEnd.difference(dayStart).inMinutes.toDouble();

    final segments = <RhythmSegment>[];
    final busy = <MinuteSpan>[];
    var dayTracked = 0.0;
    var company = false;
    // The shape of the day is drawn from the blocks that *began* on it. A
    // session that ran past the day boundary did not start at the boundary,
    // and counting its clipped edge as a start would report every late night
    // as an early morning.
    double? firstStart;
    double? lastEnd;

    for (final entry in entriesByDay[dayNumber(day)] ?? const <TimeEntry>[]) {
      final end = entry.end ?? now;
      final start = entry.start.isAfter(dayStart) ? entry.start : dayStart;
      final stop = end.isBefore(dayEnd) ? end : dayEnd;
      if (!stop.isAfter(start)) continue;

      final minutes = stop.difference(start).inMinutes.toDouble();
      final category = entry.categoryId == null
          ? null
          : colors[entry.categoryId];
      segments.add(
        RhythmSegment(
          span: MinuteSpan(
            start.difference(dayStart).inSeconds / 60,
            stop.difference(dayStart).inSeconds / 60,
          ),
          categoryId: entry.categoryId,
          colorValue: category?.colorValue,
          description: entry.description,
          running: entry.isRunning,
        ),
      );
      busy.add(
        MinuteSpan(
          start.difference(dayStart).inSeconds / 60,
          stop.difference(dayStart).inSeconds / 60,
        ),
      );
      dayTracked += minutes;
      trackedByCategory[entry.categoryId] =
          (trackedByCategory[entry.categoryId] ?? 0) + minutes;
      if (entry.hasPeople) company = true;

      _spreadOverHours(byHour, start, stop);

      // The whole block, not the piece of it that landed in this day: the
      // longest thing you did is a fact about the block, and a session that
      // ran through three in the morning did not stop there.
      final whole = end.difference(entry.start).inMinutes.toDouble();
      if (startOfLogicalDay(entry.start, startHour) == day) {
        final began = entry.start.difference(dayStart).inSeconds / 60;
        final finished = end.difference(dayStart).inSeconds / 60;
        if (firstStart == null || began < firstStart) firstStart = began;
        if (lastEnd == null || finished > lastEnd) lastEnd = finished;

        if ((longest == null || whole > longest.minutes) &&
            entry.description.trim().isNotEmpty) {
          longest = TrackedHighlight(
            minutes: whole,
            description: entry.description.trim(),
            day: day,
            colorValue: category?.colorValue,
          );
        }
      }
    }

    final nights = <MinuteSpan>[];
    for (final session in sleepByDay[dayNumber(day)] ?? const <SleepEntry>[]) {
      final start = session.start.isAfter(dayStart) ? session.start : dayStart;
      final stop = session.end.isBefore(dayEnd) ? session.end : dayEnd;
      if (!stop.isAfter(start)) continue;
      nights.add(
        MinuteSpan(
          start.difference(dayStart).inSeconds / 60,
          stop.difference(dayStart).inSeconds / 60,
        ),
      );
    }

    final daySleep = nights.fold<double>(
      0,
      (total, span) => total + span.minutes,
    );
    final accounted = _unionMinutes([...busy, ...nights]);
    final isToday = day == today;
    final isFuture = day.isAfter(today);

    segments.sort((a, b) => a.span.from.compareTo(b.span.from));

    days.add(
      RhythmDay(
        day: day,
        spanMinutes: spanMinutes,
        tracked: segments,
        asleep: nights,
        trackedMinutes: dayTracked,
        sleepMinutes: daySleep,
        accountedMinutes: accounted,
        hasCompany: company,
        isFuture: isFuture,
        isToday: isToday,
      ),
    );

    trackedMinutes += dayTracked;
    sleepMinutes += daySleep;
    accountedMinutes += accounted;

    if (!isFuture) {
      elapsedDays++;
      // Today has only happened up to now, so counting the rest of it as
      // unaccounted for would make every afternoon look like a bad day.
      elapsedMinutes += isToday
          ? math.min(spanMinutes, now.difference(dayStart).inMinutes.toDouble())
          : spanMinutes;
    }
    if (dayTracked > 0) {
      daysTracked++;
      byWeekday[day.weekday] += dayTracked;
      weekdayCounts[day.weekday]++;
      if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
        weekendMinutes += dayTracked;
      }
      // Measured from the same origin as the start, so an evening that runs
      // past the day boundary reads as later rather than as the small hours.
      if (firstStart != null) starts.add(firstStart);
      if (lastEnd != null) ends.add(lastEnd);
    }
    if (company) daysWithCompany++;
  }

  final standings = <CategoryStanding>[
    for (final id in {...trackedByCategory.keys, ...previousByCategory.keys})
      CategoryStanding(
        categoryId: id,
        name: id == null
            ? 'Uncategorised'
            : colors[id]?.name ?? 'Uncategorised',
        colorValue: id == null ? null : colors[id]?.colorValue,
        minutes: trackedByCategory[id] ?? 0,
        previousMinutes: previousByCategory[id] ?? 0,
      ),
  ]..sort((a, b) => b.minutes.compareTo(a.minutes));

  return InsightsReport(
    span: span,
    from: from,
    to: to,
    days: days,
    // A category that carried five hours last month and none this one is kept.
    // It sorts to the bottom with an empty bar, which is the honest picture:
    // dropping it would quietly turn "you stopped" into "it never existed".
    standings: [
      for (final standing in standings)
        if (standing.minutes > 0 || standing.previousMinutes > 0) standing,
    ],
    facts: _buildFacts(
      span: span,
      days: days,
      startHour: startHour,
      starts: starts,
      ends: ends,
      byHour: byHour,
      byWeekday: byWeekday,
      weekdayCounts: weekdayCounts,
      longest: longest,
      sleep: sleep,
      from: from,
      to: to,
      trackedMinutes: trackedMinutes,
      weekendMinutes: weekendMinutes,
      accountedMinutes: accountedMinutes,
      elapsedMinutes: elapsedMinutes,
      daysTracked: daysTracked,
      daysWithCompany: daysWithCompany,
    ),
    trackedMinutes: trackedMinutes,
    previousTrackedMinutes: previousTrackedMinutes,
    sleepMinutes: sleepMinutes,
    elapsedDays: elapsedDays,
  );
}

InsightsFacts _buildFacts({
  required InsightsSpan span,
  required List<RhythmDay> days,
  required int startHour,
  required List<double> starts,
  required List<double> ends,
  required List<double> byHour,
  required List<double> byWeekday,
  required List<int> weekdayCounts,
  required TrackedHighlight? longest,
  required List<SleepEntry> sleep,
  required DateTime from,
  required DateTime to,
  required double trackedMinutes,
  required double weekendMinutes,
  required double accountedMinutes,
  required double elapsedMinutes,
  required int daysTracked,
  required int daysWithCompany,
}) {
  int? fullestHour;
  var fullestMinutes = 0.0;
  for (var hour = 0; hour < 24; hour++) {
    if (byHour[hour] > fullestMinutes) {
      fullestMinutes = byHour[hour];
      fullestHour = hour;
    }
  }

  int? busiestWeekday;
  var busiestMinutes = 0.0;
  if (span != InsightsSpan.week) {
    for (var weekday = 1; weekday <= 7; weekday++) {
      // An average, not a total: three Mondays and two Tuesdays in a span
      // would otherwise make Monday busier by arithmetic alone.
      final count = weekdayCounts[weekday];
      final average = count == 0 ? 0.0 : byWeekday[weekday] / count;
      if (average > busiestMinutes) {
        busiestMinutes = average;
        busiestWeekday = weekday;
      }
    }
  }

  // A night belongs to the evening it began, which is what makes "Friday
  // night" mean the night after Friday rather than the one before it.
  final nights = [
    for (final session in sleep)
      if (!session.isNap &&
          !startOfLogicalDay(session.start, startHour).isBefore(from) &&
          startOfLogicalDay(session.start, startHour).isBefore(to))
        session,
  ];

  final weekendMidpoints = <double>[];
  final weekdayMidpoints = <double>[];
  var asleepMinutes = 0.0;
  for (final session in nights) {
    asleepMinutes += session.asleep.inMinutes;
    final midpoint =
        session.midpoint ??
        session.start.add(session.end.difference(session.start) ~/ 2);
    final minutes = minutesSinceMidnight(midpoint);
    final bedtime = startOfLogicalDay(session.start, startHour).weekday;
    if (bedtime == DateTime.friday || bedtime == DateTime.saturday) {
      weekendMidpoints.add(minutes);
    } else {
      weekdayMidpoints.add(minutes);
    }
  }

  final allMidpoints = [...weekendMidpoints, ...weekdayMidpoints];
  final midpoint = allMidpoints.isEmpty ? null : _clockMean(allMidpoints);
  final drift = weekendMidpoints.isEmpty || weekdayMidpoints.isEmpty
      ? null
      : _clockDifference(
          _clockMean(weekendMidpoints),
          _clockMean(weekdayMidpoints),
        );

  return InsightsFacts(
    daysTracked: daysTracked,
    typicalStartMinutes: starts.isEmpty ? null : _mean(starts) + startHour * 60,
    typicalEndMinutes: ends.isEmpty ? null : _mean(ends) + startHour * 60,
    fullestHour: fullestHour,
    fullestHourMinutes: fullestMinutes,
    longestBlock: longest,
    nights: nights.length,
    averageSleepMinutes: nights.isEmpty ? null : asleepMinutes / nights.length,
    sleepMidpointMinutes: midpoint,
    weekendMidpointDrift: drift,
    accountedFraction: elapsedMinutes == 0
        ? 0
        : (accountedMinutes / elapsedMinutes).clamp(0.0, 1.0),
    daysWithCompany: daysWithCompany,
    busiestWeekday: busiestWeekday,
    busiestWeekdayMinutes: busiestMinutes,
    weekendShare: trackedMinutes == 0 ? null : weekendMinutes / trackedMinutes,
  );
}

/// Files [value] under every logical day of [from, to) that [start, end)
/// touches.
void _bucket<T>(
  Map<int, List<T>> buckets,
  T value,
  DateTime start,
  DateTime end,
  DateTime from,
  DateTime to,
  int startHour,
) {
  var day = startOfLogicalDay(start, startHour);
  // The last day it touches. An instant exactly on a day start belongs to the
  // day beginning there, not to the one it closes.
  final last = startOfLogicalDay(
    end.subtract(const Duration(microseconds: 1)),
    startHour,
  );
  if (day.isBefore(from)) day = from;
  for (; !day.isAfter(last) && day.isBefore(to); day = addDays(day, 1)) {
    (buckets[dayNumber(day)] ??= <T>[]).add(value);
  }
}

/// How many minutes of [start, end) fall inside [from, to).
double _overlapMinutes(
  DateTime start,
  DateTime end,
  DateTime from,
  DateTime to,
) {
  final clippedStart = start.isAfter(from) ? start : from;
  final clippedEnd = end.isBefore(to) ? end : to;
  return clippedEnd.isAfter(clippedStart)
      ? clippedEnd.difference(clippedStart).inSeconds / 60
      : 0;
}

/// Adds a block's minutes to whichever hours of the clock it passed through.
void _spreadOverHours(List<double> byHour, DateTime start, DateTime end) {
  var cursor = start;
  while (cursor.isBefore(end)) {
    final nextHour = DateTime(
      cursor.year,
      cursor.month,
      cursor.day,
      cursor.hour + 1,
    );
    final stop = nextHour.isBefore(end) ? nextHour : end;
    byHour[cursor.hour] += stop.difference(cursor).inSeconds / 60;
    cursor = stop;
  }
}

/// Total length of a set of spans with their overlaps counted once.
double _unionMinutes(List<MinuteSpan> spans) {
  if (spans.isEmpty) return 0;
  final sorted = [...spans]..sort((a, b) => a.from.compareTo(b.from));
  var total = 0.0;
  var from = sorted.first.from;
  var to = sorted.first.to;
  for (final span in sorted.skip(1)) {
    if (span.from > to) {
      total += to - from;
      from = span.from;
      to = span.to;
    } else if (span.to > to) {
      to = span.to;
    }
  }
  return total + (to - from);
}

double _mean(List<double> values) =>
    values.reduce((a, b) => a + b) / values.length;

/// Mean of a set of clock times, measured around the evening rather than
/// around midnight.
///
/// Sleep midpoints sit either side of midnight, where a plain average of
/// 23:30 and 00:30 comes out at noon. Rotating the day so the seam falls at
/// six in the evening puts every plausible midpoint in one unbroken run.
double _clockMean(List<double> minutes) {
  const seam = 18 * 60;
  final rotated = [
    for (final value in minutes) (value - seam + minutesPerDay) % minutesPerDay,
  ];
  return (_mean(rotated) + seam) % minutesPerDay;
}

/// How much later [a] is than [b] on the clock, taking the short way round.
double _clockDifference(double a, double b) {
  final delta = (a - b + minutesPerDay) % minutesPerDay;
  return delta > minutesPerDay / 2 ? delta - minutesPerDay : delta;
}

/// One day's tracked time, split by category and ranked the same way the span
/// is.
///
/// Names and colours come from the span's own standings rather than from a
/// second lookup, so a category can never be drawn one colour in the ranking
/// and another in the day inside it.
List<CategoryStanding> standingsForDay(
  RhythmDay day,
  List<CategoryStanding> spanStandings,
) {
  final known = {
    for (final standing in spanStandings) standing.categoryId: standing,
  };
  final minutes = <String?, double>{};
  for (final segment in day.tracked) {
    minutes[segment.categoryId] =
        (minutes[segment.categoryId] ?? 0) + segment.span.minutes;
  }

  return <CategoryStanding>[
    for (final entry in minutes.entries)
      CategoryStanding(
        categoryId: entry.key,
        name: known[entry.key]?.name ?? 'Uncategorised',
        colorValue: known[entry.key]?.colorValue,
        minutes: entry.value,
        // A day has no previous day to be compared against here; the
        // comparison on screen belongs to the span.
        previousMinutes: 0,
      ),
  ]..sort((a, b) => b.minutes.compareTo(a.minutes));
}
