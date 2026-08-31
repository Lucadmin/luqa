import 'dart:math' as math;

import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

const int minutesPerDay = 24 * 60;

/// Everything the timeline creates or resizes lands on a five-minute step.
const int snapMinutes = 5;

/// Hour at which the logical day flips. Activity between midnight and this
/// hour still belongs to the evening before, which is what the day totals and
/// the day label follow. The grid itself stays midnight-to-midnight.
const int dayStartHour = 3;

/// Local midnight of the calendar day `value` falls on.
DateTime startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Calendar-safe day arithmetic — survives DST shifts and month ends.
DateTime addDays(DateTime value, int days) =>
    DateTime(value.year, value.month, value.day + days);

/// Stable integer index for a calendar date, independent of timezone and DST.
/// Differences between two of these are exact day counts, which is how dates
/// map onto scroll offsets.
int dayNumber(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

/// Minutes since local midnight, fractional so the now-line moves smoothly.
double minutesSinceMidnight(DateTime value) =>
    value.difference(startOfDay(value)).inSeconds / 60;

/// Minutes-since-midnight on `day` back to an absolute instant. Built from
/// calendar fields rather than by adding a Duration, so a DST boundary shifts
/// the wall clock rather than the position on the grid.
DateTime minutesToDate(DateTime day, num minutes) =>
    DateTime(day.year, day.month, day.day, 0, minutes.round());

/// Midnight of the logical day an instant belongs to.
DateTime startOfLogicalDay(DateTime value, [int startHour = dayStartHour]) =>
    startOfDay(value.subtract(Duration(hours: startHour)));

int snap(num minutes, [int step = snapMinutes]) =>
    (minutes / step).round() * step;

/// One entry placed on the grid, with its column inside an overlap cluster.
class LaidOutEntry {
  const LaidOutEntry({
    required this.entry,
    required this.startMin,
    required this.endMin,
    required this.running,
    required this.lane,
    required this.lanes,
    required this.clippedTop,
    required this.clippedBottom,
  });

  final TimeEntry entry;
  final double startMin;
  final double endMin;
  final bool running;

  /// Column index within the cluster of entries this one overlaps.
  final int lane;

  /// Total columns in that cluster.
  final int lanes;

  /// The entry continues past this pane's edge, so the block is drawn open
  /// and the neighbouring day picks up the other half.
  final bool clippedTop;
  final bool clippedBottom;
}

class LaidOutSleep {
  const LaidOutSleep({
    required this.entry,
    required this.startMin,
    required this.endMin,
    required this.clippedTop,
    required this.clippedBottom,
  });

  final SleepEntry entry;
  final double startMin;
  final double endMin;
  final bool clippedTop;
  final bool clippedBottom;
}

/// An interior stretch of the day with nothing logged in it.
class TimelineGap {
  const TimelineGap({required this.startMin, required this.endMin});

  final double startMin;
  final double endMin;

  double get minutes => endMin - startMin;

  Duration get duration => Duration(minutes: minutes.round());
}

class _Raw {
  _Raw(
    this.entry,
    this.startMin,
    this.endMin,
    this.running,
    this.clippedTop,
    this.clippedBottom,
  );

  final TimeEntry entry;
  final double startMin;
  double endMin;
  final bool running;
  final bool clippedTop;
  final bool clippedBottom;
}

List<_Raw> _toRaw(List<TimeEntry> entries, DateTime dayStart, DateTime now) {
  final raw = <_Raw>[];
  for (final entry in entries) {
    final rawStart = entry.start.difference(dayStart).inSeconds / 60;
    final running = entry.isRunning;
    final rawEnd = entry.endOrNow(now).difference(dayStart).inSeconds / 60;
    final startMin = rawStart.clamp(0, minutesPerDay).toDouble();
    final endMin = math.max(
      startMin + 1,
      rawEnd.clamp(0, minutesPerDay).toDouble(),
    );
    if (rawEnd <= 0 || rawStart >= minutesPerDay) continue;
    raw.add(
      _Raw(
        entry,
        startMin,
        endMin,
        running,
        rawStart < 0,
        rawEnd > minutesPerDay,
      ),
    );
  }
  raw.sort((left, right) {
    final byStart = left.startMin.compareTo(right.startMin);
    return byStart != 0 ? byStart : left.endMin.compareTo(right.endMin);
  });
  return raw;
}

/// Place a day's entries, splitting anything that overlaps into side-by-side
/// columns so nothing is hidden behind anything else.
List<LaidOutEntry> layOutEntries(
  List<TimeEntry> entries,
  DateTime dayStart,
  DateTime now,
) {
  final raw = _toRaw(entries, dayStart, now);
  final result = <LaidOutEntry>[];

  var index = 0;
  while (index < raw.length) {
    // Grow a cluster of transitively overlapping entries.
    var clusterEnd = raw[index].endMin;
    var next = index + 1;
    while (next < raw.length && raw[next].startMin < clusterEnd) {
      clusterEnd = math.max(clusterEnd, raw[next].endMin);
      next++;
    }
    final cluster = raw.sublist(index, next);

    // Greedy column assignment: reuse the first column that has freed up.
    final laneEnds = <double>[];
    final lanes = <int>[];
    for (final item in cluster) {
      var lane = laneEnds.indexWhere((end) => end <= item.startMin);
      if (lane == -1) {
        lane = laneEnds.length;
        laneEnds.add(item.endMin);
      } else {
        laneEnds[lane] = item.endMin;
      }
      lanes.add(lane);
    }

    for (var k = 0; k < cluster.length; k++) {
      final item = cluster[k];
      result.add(
        LaidOutEntry(
          entry: item.entry,
          startMin: item.startMin,
          endMin: item.endMin,
          running: item.running,
          lane: lanes[k],
          lanes: laneEnds.length,
          clippedTop: item.clippedTop,
          clippedBottom: item.clippedBottom,
        ),
      );
    }

    index = next;
  }

  return result;
}

List<LaidOutSleep> layOutSleep(List<SleepEntry> sessions, DateTime dayStart) {
  final result = <LaidOutSleep>[];
  for (final entry in sessions) {
    final rawStart = entry.start.difference(dayStart).inSeconds / 60;
    final rawEnd = entry.end.difference(dayStart).inSeconds / 60;
    final startMin = rawStart.clamp(0, minutesPerDay).toDouble();
    final endMin = rawEnd.clamp(0, minutesPerDay).toDouble();
    if (endMin <= startMin) continue;
    result.add(
      LaidOutSleep(
        entry: entry,
        startMin: startMin,
        endMin: endMin,
        clippedTop: rawStart < 0,
        clippedBottom: rawEnd > minutesPerDay,
      ),
    );
  }
  return result;
}

/// Stretches of the day nothing accounts for, plus the trailing stretch up to
/// now on the current day. Slivers shorter than one snap step are ignored.
///
/// Sleep counts as accounted-for even though it is not tracked time: those
/// hours are spoken for, so a gap must not run through them, and filling the
/// gap beside a night should stop at the moment it ended.
List<TimelineGap> computeGaps(
  List<TimeEntry> entries,
  List<SleepEntry> sleep,
  DateTime dayStart,
  DateTime now, {
  required bool isToday,
}) {
  final spans = <TimelineGap>[
    for (final item in _toRaw(entries, dayStart, now))
      TimelineGap(startMin: item.startMin, endMin: item.endMin),
    for (final band in layOutSleep(sleep, dayStart))
      TimelineGap(startMin: band.startMin, endMin: band.endMin),
  ]..sort((left, right) => left.startMin.compareTo(right.startMin));
  if (spans.isEmpty) return const [];

  final nowMin = isToday
      ? math.min(
          now.difference(dayStart).inSeconds / 60,
          minutesPerDay.toDouble(),
        )
      : null;

  // Merge everything covered, then read the holes off the merged spans.
  final merged = <TimelineGap>[];
  var spanStart = spans.first.startMin;
  var spanEnd = spans.first.endMin;
  for (final item in spans.skip(1)) {
    if (item.startMin <= spanEnd) {
      spanEnd = math.max(spanEnd, item.endMin);
    } else {
      merged.add(TimelineGap(startMin: spanStart, endMin: spanEnd));
      spanStart = item.startMin;
      spanEnd = item.endMin;
    }
  }
  merged.add(TimelineGap(startMin: spanStart, endMin: spanEnd));

  final gaps = <TimelineGap>[];
  for (var i = 0; i < merged.length - 1; i++) {
    final gap = TimelineGap(
      startMin: merged[i].endMin,
      endMin: merged[i + 1].startMin,
    );
    if (gap.minutes >= snapMinutes) gaps.add(gap);
  }

  final lastEnd = merged.last.endMin;
  if (nowMin != null && nowMin - lastEnd >= snapMinutes) {
    gaps.add(TimelineGap(startMin: lastEnd, endMin: nowMin));
  }

  return gaps;
}
