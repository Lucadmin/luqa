/// How much of the past one screen of Insights covers.
///
/// Every span is a whole number of weeks and starts on a week boundary, so the
/// rhythm wall's columns always line up under the same weekday. A span that
/// drifted by a day would turn the one pattern most lives actually have — the
/// working week — into noise.
enum InsightsSpan {
  week(weeks: 1, label: 'Week'),
  fourWeeks(weeks: 4, label: '4 weeks'),
  twelveWeeks(weeks: 12, label: '12 weeks');

  const InsightsSpan({required this.weeks, required this.label});

  final int weeks;
  final String label;

  int get days => weeks * 7;
}

/// A stretch of one column of the rhythm wall, in minutes from the top of the
/// logical day.
class MinuteSpan {
  const MinuteSpan(this.from, this.to);

  final double from;
  final double to;

  double get minutes => to - from;
}

/// One tracked block as the wall draws it: already clipped to a single column.
class RhythmSegment {
  const RhythmSegment({
    required this.span,
    required this.categoryId,
    required this.colorValue,
    required this.description,
    this.running = false,
  });

  final MinuteSpan span;

  /// Null for a block filed under no category.
  final String? categoryId;

  /// Null travels with a null [categoryId]: the wall paints those in the
  /// shell's own muted grey rather than borrowing an identity colour for
  /// something that has no identity.
  final int? colorValue;

  final String description;
  final bool running;
}

/// One logical day, ready to paint.
class RhythmDay {
  const RhythmDay({
    required this.day,
    required this.spanMinutes,
    required this.tracked,
    required this.asleep,
    required this.trackedMinutes,
    required this.sleepMinutes,
    required this.accountedMinutes,
    required this.hasCompany,
    required this.isFuture,
    required this.isToday,
  });

  /// Local midnight of the logical day. The column itself runs from the day
  /// start hour on this date to the day start hour on the next.
  final DateTime day;

  /// The column's real length. A clock-change day is 23 or 25 hours long, and
  /// the wall would rather be an hour narrower than an hour wrong.
  final double spanMinutes;

  final List<RhythmSegment> tracked;
  final List<MinuteSpan> asleep;

  final double trackedMinutes;
  final double sleepMinutes;

  /// Tracked time and measured sleep, counted once where they overlap.
  final double accountedMinutes;

  /// Whether anyone was tagged on this day.
  final bool hasCompany;

  final bool isFuture;
  final bool isToday;

  bool get isEmpty => tracked.isEmpty && asleep.isEmpty;
}

/// One category's share of a span, next to what it was the span before.
class CategoryStanding {
  const CategoryStanding({
    required this.categoryId,
    required this.name,
    required this.colorValue,
    required this.minutes,
    required this.previousMinutes,
  });

  final String? categoryId;
  final String name;
  final int? colorValue;
  final double minutes;
  final double previousMinutes;

  /// Positive means more time than the span before.
  double get delta => minutes - previousMinutes;

  /// True only when there is a previous span to compare against at all, so a
  /// first-ever week does not read as "everything is new".
  bool get isNew => previousMinutes == 0;
}

/// The single tracked block that stood out over a span.
class TrackedHighlight {
  const TrackedHighlight({
    required this.minutes,
    required this.description,
    required this.day,
    required this.colorValue,
  });

  final double minutes;
  final String description;

  /// The logical day it started on.
  final DateTime day;

  final int? colorValue;
}

/// Everything about a span that is a number rather than a picture.
///
/// Deliberately unformatted. Turning these into sentences is a presentation
/// decision — it depends on the words, the locale and how much room there is —
/// and keeping it out of here is what lets the arithmetic be tested on its own.
class InsightsFacts {
  const InsightsFacts({
    required this.daysTracked,
    required this.typicalStartMinutes,
    required this.typicalEndMinutes,
    required this.fullestHour,
    required this.fullestHourMinutes,
    required this.longestBlock,
    required this.nights,
    required this.averageSleepMinutes,
    required this.sleepMidpointMinutes,
    required this.weekendMidpointDrift,
    required this.accountedFraction,
    required this.daysWithCompany,
    required this.busiestWeekday,
    required this.busiestWeekdayMinutes,
    required this.weekendShare,
  });

  const InsightsFacts.empty()
    : daysTracked = 0,
      typicalStartMinutes = null,
      typicalEndMinutes = null,
      fullestHour = null,
      fullestHourMinutes = 0,
      longestBlock = null,
      nights = 0,
      averageSleepMinutes = null,
      sleepMidpointMinutes = null,
      weekendMidpointDrift = null,
      accountedFraction = 0,
      daysWithCompany = 0,
      busiestWeekday = null,
      busiestWeekdayMinutes = 0,
      weekendShare = null;

  /// Days of the span with any tracked time at all.
  final int daysTracked;

  /// Mean minutes since midnight of the first block of a day, over the days
  /// that had one. Null when nothing was tracked.
  final double? typicalStartMinutes;

  /// Mean end of the last block of a day. Past midnight it keeps counting, so
  /// a day that usually ends at one in the morning reads as 1500, not 60.
  final double? typicalEndMinutes;

  /// Hour of the clock, 0..23, carrying the most tracked time across the span.
  final int? fullestHour;
  final double fullestHourMinutes;

  final TrackedHighlight? longestBlock;

  /// Nights of measured sleep inside the span.
  final int nights;
  final double? averageSleepMinutes;

  /// Circular mean of the nightly midpoint, as minutes since midnight.
  final double? sleepMidpointMinutes;

  /// How much later the midpoint sits on nights begun at the weekend. Null
  /// unless both kinds of night are present, since a difference needs two
  /// things to be a difference.
  final double? weekendMidpointDrift;

  /// Tracked time and measured sleep over the elapsed span, counted once where
  /// they overlap.
  final double accountedFraction;

  final int daysWithCompany;

  /// `DateTime.monday`..`DateTime.sunday`, or null over a single week where
  /// "the busiest weekday" is only ever the busiest day.
  final int? busiestWeekday;
  final double busiestWeekdayMinutes;

  /// Share of tracked time falling on Saturday and Sunday. Null when nothing
  /// was tracked.
  final double? weekendShare;
}

/// Everything one screen of Insights is drawn from.
class InsightsReport {
  const InsightsReport({
    required this.span,
    required this.from,
    required this.to,
    required this.days,
    required this.standings,
    required this.facts,
    required this.trackedMinutes,
    required this.previousTrackedMinutes,
    required this.sleepMinutes,
    required this.elapsedDays,
  });

  final InsightsSpan span;

  /// Logical day, inclusive.
  final DateTime from;

  /// Logical day, exclusive.
  final DateTime to;

  final List<RhythmDay> days;
  final List<CategoryStanding> standings;
  final InsightsFacts facts;

  final double trackedMinutes;
  final double previousTrackedMinutes;
  final double sleepMinutes;

  /// Days of the span that have actually happened. The average is over these
  /// rather than over the whole span, so Monday of a new week is not reported
  /// as a catastrophic drop.
  final int elapsedDays;

  bool get isEmpty => trackedMinutes == 0 && sleepMinutes == 0;

  /// Null when there is nothing to compare against, which is different from a
  /// comparison that came out at zero.
  double? get delta => previousTrackedMinutes == 0
      ? null
      : trackedMinutes - previousTrackedMinutes;

  double get averagePerDay =>
      elapsedDays == 0 ? 0 : trackedMinutes / elapsedDays;

  RhythmDay? dayFor(DateTime day) {
    for (final candidate in days) {
      if (candidate.day == day) return candidate;
    }
    return null;
  }
}
