/// What "done" means for one day of a habit.
enum HabitGoalType {
  /// Done or not done.
  task,

  /// A number of reps to reach.
  count,

  /// A duration to accumulate.
  time,
}

/// Whether a TIME target is a daily quota or a running total for a period.
enum HabitGoalPeriod { day, week, month }

/// How a habit recurs.
enum HabitScheduleType {
  daily,
  weekdays,
  interval,
  timesPerWeek,
  timesPerMonth,
  timesPerYear,
  dates,
}

extension HabitScheduleTypeX on HabitScheduleType {
  /// True for the schedules that are active every day and track a quota across
  /// a period rather than naming particular days.
  bool get isPeriodQuota =>
      this == HabitScheduleType.timesPerWeek ||
      this == HabitScheduleType.timesPerMonth ||
      this == HabitScheduleType.timesPerYear;
}

/// A goal plus a schedule. Together they decide what shows on a given day and
/// what counts as done on it.
///
/// Dates here are date keys — `YYYY-MM-DD` for a logical day in the user's
/// timezone — rather than instants. A habit is kept on a calendar, not on a
/// clock, and a key survives the timezone changing under it where an instant
/// silently moves to a different day.
class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.order,
    required this.goalType,
    required this.goalPeriod,
    required this.targetCount,
    required this.targetSeconds,
    required this.categoryId,
    required this.scheduleType,
    required this.weekdays,
    required this.weekInterval,
    required this.intervalDays,
    required this.intervalFromLastDone,
    required this.timesPerPeriod,
    required this.anchorDate,
    required this.dates,
    required this.excludedDates,
    required this.archived,
    required this.createdAt,
  });

  final String id;
  final String name;

  /// Name from the shared habit icon set, or null for the default mark.
  final String? icon;
  final int colorValue;
  final int order;

  final HabitGoalType goalType;
  final HabitGoalPeriod goalPeriod;

  /// Reps needed for a COUNT goal. Always 1 for a TASK.
  final int targetCount;

  /// Duration goal in seconds for a TIME habit.
  final int targetSeconds;

  /// A TIME habit linked to a tracking category draws its progress from the
  /// time tracked on that category, and its timer is a real time entry rather
  /// than a number kept beside one.
  final String? categoryId;

  final HabitScheduleType scheduleType;

  /// For WEEKDAYS — 0 is Sunday, 6 is Saturday.
  final List<int> weekdays;

  /// For WEEKDAYS — every N weeks.
  final int weekInterval;

  /// For INTERVAL — every N days from the anchor.
  final int intervalDays;

  /// For INTERVAL — count from the last day the goal was met, rather than from
  /// the anchor.
  ///
  /// "Shave every second day" on a fixed grid keeps insisting on the original
  /// odd days: miss Wednesday, do it Thursday, and Friday is still the day it
  /// wants. Counting from the last time shifts the whole cycle instead, which
  /// is what that phrase usually means.
  final bool intervalFromLastDone;

  /// For TIMES_PER_* — the quota within each period.
  final int timesPerPeriod;

  /// The date key an interval counts from. Null falls back to the day the
  /// habit was created.
  final String? anchorDate;

  /// For DATES — the explicit days.
  final List<String> dates;

  /// Days to skip, whatever the schedule would otherwise say.
  final List<String> excludedDates;

  final bool archived;
  final DateTime createdAt;

  /// True when progress comes from tracked time rather than from a log this
  /// habit keeps of its own.
  bool get isCategoryLinked =>
      goalType == HabitGoalType.time && categoryId != null;

  /// True when which days this habit is due on depends on when it was last
  /// done, rather than only on the calendar.
  bool get isRollingInterval =>
      scheduleType == HabitScheduleType.interval && intervalFromLastDone;

  /// How far back deciding one day can need to look.
  ///
  /// "Due unless it was done within the last N days" needs exactly those N
  /// days, so loading history for a rolling habit never means loading more
  /// than its own interval — even for one not done in a year.
  int get rollingLookbackDays =>
      isRollingInterval ? (intervalDays < 1 ? 1 : intervalDays) : 0;

  Habit copyWith({
    String? name,
    String? Function()? icon,
    int? colorValue,
    int? order,
    HabitGoalType? goalType,
    HabitGoalPeriod? goalPeriod,
    int? targetCount,
    int? targetSeconds,
    String? Function()? categoryId,
    HabitScheduleType? scheduleType,
    List<int>? weekdays,
    int? weekInterval,
    int? intervalDays,
    bool? intervalFromLastDone,
    int? timesPerPeriod,
    String? Function()? anchorDate,
    List<String>? dates,
    List<String>? excludedDates,
    bool? archived,
  }) => Habit(
    id: id,
    name: name ?? this.name,
    icon: icon == null ? this.icon : icon(),
    colorValue: colorValue ?? this.colorValue,
    order: order ?? this.order,
    goalType: goalType ?? this.goalType,
    goalPeriod: goalPeriod ?? this.goalPeriod,
    targetCount: targetCount ?? this.targetCount,
    targetSeconds: targetSeconds ?? this.targetSeconds,
    categoryId: categoryId == null ? this.categoryId : categoryId(),
    scheduleType: scheduleType ?? this.scheduleType,
    weekdays: weekdays ?? this.weekdays,
    weekInterval: weekInterval ?? this.weekInterval,
    intervalDays: intervalDays ?? this.intervalDays,
    intervalFromLastDone: intervalFromLastDone ?? this.intervalFromLastDone,
    timesPerPeriod: timesPerPeriod ?? this.timesPerPeriod,
    anchorDate: anchorDate == null ? this.anchorDate : anchorDate(),
    dates: dates ?? this.dates,
    excludedDates: excludedDates ?? this.excludedDates,
    archived: archived ?? this.archived,
    createdAt: createdAt,
  );
}

/// One habit's stored progress for one logical day.
class HabitLog {
  const HabitLog({
    required this.habitId,
    required this.date,
    required this.count,
    required this.seconds,
    required this.runningSince,
    required this.completedAt,
  });

  const HabitLog.empty(this.habitId, this.date)
    : count = 0,
      seconds = 0,
      runningSince = null,
      completedAt = null;

  final String habitId;
  final String date;

  /// Reps done for a COUNT goal, or 0/1 for a TASK.
  final int count;

  /// Seconds banked toward an unlinked TIME goal.
  final int seconds;

  /// When an unlinked timer started. The elapsed time is added as it runs
  /// rather than written every second, so a phone that spent the afternoon in
  /// a pocket still shows the right total when it wakes.
  final DateTime? runningSince;

  /// The first moment the day's goal was met.
  final DateTime? completedAt;

  bool get isRunning => runningSince != null;

  HabitLog copyWith({
    int? count,
    int? seconds,
    DateTime? Function()? runningSince,
    DateTime? Function()? completedAt,
  }) => HabitLog(
    habitId: habitId,
    date: date,
    count: count ?? this.count,
    seconds: seconds ?? this.seconds,
    runningSince: runningSince == null ? this.runningSince : runningSince(),
    completedAt: completedAt == null ? this.completedAt : completedAt(),
  );
}
