import 'package:luqa/features/habits/domain/habit.dart';

/// Habit scheduling and goal maths, in date keys.
///
/// The counterpart of the server's `src/lib/habits.ts`, and deliberately the
/// same shape: both clients decide whether a habit is due, and whether a day is
/// done, from the same rules, so a phone with no signal and the browser never
/// disagree about a streak.
///
/// A date key is `YYYY-MM-DD` for a logical day. Parsing builds a local
/// midnight and only ever reads calendar fields, which is what keeps the maths
/// stable across daylight saving: two dates an hour apart in real time are
/// still one day apart here.

final RegExp _dateKeyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

bool isDateKey(String value) => _dateKeyPattern.hasMatch(value);

String dateKeyOf(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year.toString().padLeft(4, '0')}-$month-$day';
}

DateTime parseDateKey(String key) {
  final parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    parts.length > 1 ? int.parse(parts[1]) : 1,
    parts.length > 2 ? int.parse(parts[2]) : 1,
  );
}

/// The logical day an instant falls in: a block logged at 01:00 belongs to the
/// day that has not ended yet, not to the one the clock just started.
String logicalDateKey(DateTime at, int dayStartHour) =>
    dateKeyOf(at.subtract(Duration(hours: dayStartHour)));

String addDaysToKey(String key, int days) {
  final date = parseDateKey(key);
  return dateKeyOf(DateTime(date.year, date.month, date.day + days));
}

/// Whole days from [from] to [to], positive when [to] is later.
int daysBetweenKeys(String from, String to) {
  final a = parseDateKey(from);
  final b = parseDateKey(to);
  // Compared in UTC so an hour lost or gained to daylight saving cannot round
  // a whole day away.
  final ua = DateTime.utc(a.year, a.month, a.day);
  final ub = DateTime.utc(b.year, b.month, b.day);
  return ub.difference(ua).inDays;
}

/// Dart weekdays run Monday=1..Sunday=7; habits store Sunday=0..Saturday=6,
/// the same as the browser's `Date.getDay()`.
int weekdayIndex(DateTime date) => date.weekday % 7;

DateTime startOfWeek(DateTime date, int weekStartsOn) {
  final day = DateTime(date.year, date.month, date.day);
  final diff = (weekdayIndex(day) - weekStartsOn + 7) % 7;
  return DateTime(day.year, day.month, day.day - diff);
}

/// Is [habit] active — shown at all — on [dateKey]?
bool isScheduledOn(Habit habit, String dateKey, {int weekStartsOn = 1}) {
  if (habit.excludedDates.contains(dateKey)) return false;
  final date = parseDateKey(dateKey);

  switch (habit.scheduleType) {
    case HabitScheduleType.daily:
      return true;

    case HabitScheduleType.weekdays:
      if (!habit.weekdays.contains(weekdayIndex(date))) return false;
      final interval = habit.weekInterval < 1 ? 1 : habit.weekInterval;
      if (interval == 1) return true;
      final anchorKey = habit.anchorDate ?? dateKeyOf(habit.createdAt);
      final anchorWeek = startOfWeek(parseDateKey(anchorKey), weekStartsOn);
      final thisWeek = startOfWeek(date, weekStartsOn);
      final weeks =
          (daysBetweenKeys(dateKeyOf(anchorWeek), dateKeyOf(thisWeek)) / 7)
              .round();
      return weeks % interval == 0;

    case HabitScheduleType.interval:
      final anchorKey = habit.anchorDate ?? dateKeyOf(habit.createdAt);
      final diff = daysBetweenKeys(anchorKey, dateKey);
      if (diff < 0) return false;
      return diff % (habit.intervalDays < 1 ? 1 : habit.intervalDays) == 0;

    case HabitScheduleType.timesPerWeek:
    case HabitScheduleType.timesPerMonth:
    case HabitScheduleType.timesPerYear:
      // Active every day; the quota is what is tracked across the period.
      return true;

    case HabitScheduleType.dates:
      return habit.dates.contains(dateKey);
  }
}

/// An inclusive range of date keys.
class DateKeyRange {
  const DateKeyRange(this.from, this.to);

  final String from;
  final String to;

  bool contains(String key) => key.compareTo(from) >= 0 && key.compareTo(to) <= 0;
}

/// The period containing [dateKey], for a quota schedule.
DateKeyRange periodRange(
  HabitScheduleType scheduleType,
  String dateKey, {
  int weekStartsOn = 1,
}) {
  final date = parseDateKey(dateKey);
  switch (scheduleType) {
    case HabitScheduleType.timesPerMonth:
      return DateKeyRange(
        dateKeyOf(DateTime(date.year, date.month, 1)),
        // Day zero of the next month is the last day of this one, whatever
        // its length and whether or not it is a leap year.
        dateKeyOf(DateTime(date.year, date.month + 1, 0)),
      );
    case HabitScheduleType.timesPerYear:
      return DateKeyRange(
        dateKeyOf(DateTime(date.year, 1, 1)),
        dateKeyOf(DateTime(date.year, 12, 31)),
      );
    default:
      // Weekly, and anything else asked about its week.
      final from = startOfWeek(date, weekStartsOn);
      return DateKeyRange(
        dateKeyOf(from),
        dateKeyOf(DateTime(from.year, from.month, from.day + 6)),
      );
  }
}

/// The period a TIME goal's target covers, when it is not a daily one.
DateKeyRange goalPeriodRange(
  HabitGoalPeriod period,
  String dateKey, {
  int weekStartsOn = 1,
}) => periodRange(
  period == HabitGoalPeriod.month
      ? HabitScheduleType.timesPerMonth
      : HabitScheduleType.timesPerWeek,
  dateKey,
  weekStartsOn: weekStartsOn,
);

/// How far into a day's goal a given amount of progress is.
class HabitProgress {
  const HabitProgress({required this.count, required this.seconds});

  static const zero = HabitProgress(count: 0, seconds: 0);

  final int count;
  final int seconds;
}

bool isGoalMet(Habit habit, HabitProgress progress) {
  switch (habit.goalType) {
    case HabitGoalType.task:
      return progress.count >= 1;
    case HabitGoalType.count:
      return progress.count >= (habit.targetCount < 1 ? 1 : habit.targetCount);
    case HabitGoalType.time:
      return progress.seconds >=
          (habit.targetSeconds < 1 ? 1 : habit.targetSeconds);
  }
}

/// 0..1 of the day's goal reached.
double goalFraction(Habit habit, HabitProgress progress) {
  switch (habit.goalType) {
    case HabitGoalType.task:
      return progress.count >= 1 ? 1 : 0;
    case HabitGoalType.count:
      final target = habit.targetCount < 1 ? 1 : habit.targetCount;
      return (progress.count / target).clamp(0, 1).toDouble();
    case HabitGoalType.time:
      final target = habit.targetSeconds < 1 ? 1 : habit.targetSeconds;
      return (progress.seconds / target).clamp(0, 1).toDouble();
  }
}

const _weekdayShort = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// A one-line summary of when a habit is due, e.g. "Mon, Wed, Fri".
String scheduleSummary(Habit habit) {
  switch (habit.scheduleType) {
    case HabitScheduleType.daily:
      return 'Every day';
    case HabitScheduleType.weekdays:
      final days = [...habit.weekdays]..sort();
      if (days.length == 7) return 'Every day';
      if (days.isEmpty) return 'No days';
      final label = days.length == 5 && days.every((d) => d >= 1 && d <= 5)
          ? 'Weekdays'
          : days.length == 2 && days.contains(0) && days.contains(6)
          ? 'Weekends'
          : days.map((d) => _weekdayShort[d]).join(', ');
      return habit.weekInterval > 1
          ? '$label · every ${habit.weekInterval}w'
          : label;
    case HabitScheduleType.interval:
      return habit.intervalDays == 1
          ? 'Every day'
          : 'Every ${habit.intervalDays} days';
    case HabitScheduleType.timesPerWeek:
      return '${habit.timesPerPeriod}× per week';
    case HabitScheduleType.timesPerMonth:
      return '${habit.timesPerPeriod}× per month';
    case HabitScheduleType.timesPerYear:
      return '${habit.timesPerPeriod}× per year';
    case HabitScheduleType.dates:
      return habit.dates.length == 1
          ? 'On 1 date'
          : 'On ${habit.dates.length} dates';
  }
}

/// The "this week" half of a period TIME goal's label, or empty for a daily one.
String goalPeriodLabel(HabitGoalPeriod period) => switch (period) {
  HabitGoalPeriod.week => 'this week',
  HabitGoalPeriod.month => 'this month',
  HabitGoalPeriod.day => '',
};

/// The word a quota schedule counts within.
String quotaPeriodLabel(HabitScheduleType type) => switch (type) {
  HabitScheduleType.timesPerWeek => 'this week',
  HabitScheduleType.timesPerMonth => 'this month',
  HabitScheduleType.timesPerYear => 'this year',
  _ => '',
};
