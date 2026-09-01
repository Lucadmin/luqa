import 'package:luqa/features/habits/domain/habit.dart';
import 'package:luqa/features/habits/domain/habit_schedule.dart';

/// Everything a day's habits can be resolved from, already gathered.
///
/// The server works this out from the database. A phone works it out from the
/// rows it has already synced — the habits, their logs, and the time entries
/// behind any category-linked goal — which is what lets the strip on Today be
/// correct with no network at all.
///
/// The maps have to cover more than the day being asked about: a weekly quota
/// counts across its whole week, and a monthly TIME goal across its whole
/// month. Whoever builds this loads the widest period the habits need.
class HabitDayFacts {
  const HabitDayFacts({
    this.logs = const {},
    this.trackedSeconds = const {},
    this.runningCategories = const {},
  });

  /// Stored progress, keyed `habitId|dateKey`.
  final Map<String, HabitLog> logs;

  /// Seconds tracked on a category during a logical day, keyed
  /// `categoryId|dateKey`. Closed entries only; a running one is elapsed time,
  /// which is a different thing and is counted from [runningCategories].
  final Map<String, int> trackedSeconds;

  /// The category a timer is currently running against, and since when.
  final Map<String, DateTime> runningCategories;

  HabitLog? logFor(String habitId, String dateKey) =>
      logs['$habitId|$dateKey'];

  int trackedOn(String categoryId, String dateKey) =>
      trackedSeconds['$categoryId|$dateKey'] ?? 0;
}

/// A habit, plus what has happened to it on one particular day.
class HabitDay {
  const HabitDay({
    required this.habit,
    required this.count,
    required this.seconds,
    required this.runningSince,
    required this.done,
    required this.periodDone,
    required this.periodTarget,
  });

  final Habit habit;

  /// Reps done (COUNT) or 0/1 (TASK).
  final int count;

  /// Seconds banked toward a TIME goal, excluding anything a running timer has
  /// accumulated since it started.
  final int seconds;

  /// When the timer behind this habit started, or null if none is running.
  final DateTime? runningSince;

  /// Whether the day's goal is met, counting the running timer.
  final bool done;

  /// For a quota schedule: days completed so far in the current period.
  final int? periodDone;

  /// For a quota schedule: the quota itself.
  final int? periodTarget;

  String get id => habit.id;

  bool get isRunning => runningSince != null;

  /// Seconds including whatever a running timer has added by [now].
  ///
  /// Kept out of [seconds] so a screen can rebuild once a second without the
  /// resolver — or the database — being touched at all.
  int liveSeconds(DateTime now) {
    final since = runningSince;
    if (since == null) return seconds;
    final elapsed = now.difference(since).inSeconds;
    return seconds + (elapsed < 0 ? 0 : elapsed);
  }

  HabitProgress liveProgress(DateTime now) =>
      HabitProgress(count: count, seconds: liveSeconds(now));

  /// 0..1 of the goal reached, counting a running timer.
  double liveFraction(DateTime now) => goalFraction(habit, liveProgress(now));

  bool isDoneAt(DateTime now) => isGoalMet(habit, liveProgress(now));
}

/// "Was this habit's goal met on this day", answered from the rows already
/// loaded.
///
/// The same question [_completedInPeriod] asks of a quota, and the same one a
/// rolling interval asks of the days before the one being decided — so it is
/// asked in one place rather than three.
DoneOn _doneOn(Habit habit, HabitDayFacts facts) =>
    (dateKey) => isGoalMet(habit, _dayProgress(habit, dateKey, facts));

/// The progress stored against one habit on one day, before any running timer
/// is added to it.
HabitProgress _dayProgress(Habit habit, String dateKey, HabitDayFacts facts) {
  if (habit.isCategoryLinked) {
    return HabitProgress(
      count: 0,
      seconds: facts.trackedOn(habit.categoryId!, dateKey),
    );
  }
  final log = facts.logFor(habit.id, dateKey);
  return HabitProgress(count: log?.count ?? 0, seconds: log?.seconds ?? 0);
}

/// Sums a habit's stored progress across an inclusive range of days.
///
/// Used for TIME goals whose target is a week's or a month's total rather than
/// a day's. The running timer comes back separately: it belongs to today, and
/// adding its elapsed time here would freeze it at the moment of the call.
({int seconds, DateTime? runningSince}) _periodProgress(
  Habit habit,
  DateKeyRange range,
  HabitDayFacts facts,
) {
  var seconds = 0;
  DateTime? runningSince;

  if (habit.isCategoryLinked) {
    final categoryId = habit.categoryId!;
    for (
      var key = range.from;
      key.compareTo(range.to) <= 0;
      key = addDaysToKey(key, 1)
    ) {
      seconds += facts.trackedOn(categoryId, key);
    }
    runningSince = facts.runningCategories[categoryId];
  } else {
    for (
      var key = range.from;
      key.compareTo(range.to) <= 0;
      key = addDaysToKey(key, 1)
    ) {
      final log = facts.logFor(habit.id, key);
      if (log == null) continue;
      seconds += log.seconds;
      final since = log.runningSince;
      // Only one day's log can be running, but the newest wins if a stale one
      // was left behind by a device that stopped without syncing.
      if (since != null &&
          (runningSince == null || since.isAfter(runningSince))) {
        runningSince = since;
      }
    }
  }

  return (seconds: seconds, runningSince: runningSince);
}

/// How many days of [range] this habit's goal was met on.
int _completedInPeriod(Habit habit, DateKeyRange range, HabitDayFacts facts) {
  var done = 0;
  for (
    var key = range.from;
    key.compareTo(range.to) <= 0;
    key = addDaysToKey(key, 1)
  ) {
    // Recomputed from the day's progress rather than read from the log's
    // `completedAt`. A linked TIME habit has no log to carry that flag until
    // the server writes one, and a quota that only counted after a sync would
    // be wrong exactly when the phone is offline.
    if (_doneOn(habit, facts)(key)) done++;
  }
  return done;
}

/// The habits scheduled on [dateKey], in order, each with its progress
/// resolved for that day.
List<HabitDay> resolveHabitDay({
  required List<Habit> habits,
  required String dateKey,
  required HabitDayFacts facts,
  int weekStartsOn = 1,
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final resolved = <HabitDay>[];

  for (final habit in habits) {
    if (habit.archived) continue;
    if (!isScheduledOn(
      habit,
      dateKey,
      weekStartsOn: weekStartsOn,
      doneOn: _doneOn(habit, facts),
    )) {
      continue;
    }

    int count;
    int seconds;
    DateTime? runningSince;

    if (habit.goalType == HabitGoalType.time &&
        habit.goalPeriod != HabitGoalPeriod.day) {
      final range = goalPeriodRange(
        habit.goalPeriod,
        dateKey,
        weekStartsOn: weekStartsOn,
      );
      final period = _periodProgress(habit, range, facts);
      count = 0;
      seconds = period.seconds;
      runningSince = period.runningSince;
    } else {
      final progress = _dayProgress(habit, dateKey, facts);
      count = progress.count;
      seconds = progress.seconds;
      runningSince = habit.isCategoryLinked
          ? facts.runningCategories[habit.categoryId!]
          : facts.logFor(habit.id, dateKey)?.runningSince;
    }

    int? periodDone;
    int? periodTarget;
    if (habit.scheduleType.isPeriodQuota) {
      periodDone = _completedInPeriod(
        habit,
        periodRange(habit.scheduleType, dateKey, weekStartsOn: weekStartsOn),
        facts,
      );
      periodTarget = habit.timesPerPeriod;
    }

    // A running timer counts toward the goal, which is what makes a ring fill
    // and latch while it runs rather than only once it is stopped.
    final elapsed = runningSince == null
        ? 0
        : at.difference(runningSince).inSeconds.clamp(0, 1 << 31);

    resolved.add(
      HabitDay(
        habit: habit,
        count: count,
        seconds: seconds,
        runningSince: runningSince,
        done: isGoalMet(
          habit,
          HabitProgress(count: count, seconds: seconds + elapsed),
        ),
        periodDone: periodDone,
        periodTarget: periodTarget,
      ),
    );
  }

  return resolved;
}

/// Per-habit analytics over a window of days.
class HabitStat {
  const HabitStat({
    required this.habitId,
    required this.fractions,
    required this.streak,
    required this.bestStreak,
    required this.completed,
    required this.scheduled,
  });

  final String habitId;

  /// Date key to goal fraction, for the scheduled days only. A day that is
  /// absent was not one this habit was due on.
  final Map<String, double> fractions;

  /// Consecutive completions counting back from the end of the window.
  final int streak;
  final int bestStreak;
  final int completed;
  final int scheduled;

  double get rate => scheduled == 0 ? 0 : completed / scheduled;
}

/// Completion history for each habit across an inclusive window.
///
/// [to] is treated as today: a day that is still pending does not break a
/// streak, because a habit that has not been done *yet* has not been missed.
List<HabitStat> resolveHabitStats({
  required List<Habit> habits,
  required String from,
  required String to,
  required HabitDayFacts facts,
  int weekStartsOn = 1,
}) {
  final stats = <HabitStat>[];

  for (final habit in habits) {
    final fractions = <String, double>{};
    var completed = 0;
    var scheduled = 0;
    var bestStreak = 0;
    var run = 0;
    // A rolling interval decides a day from the days before it, including the
    // ones before the window — which is why this reads the facts rather than
    // the fractions being built up as the loop goes.
    final doneOn = _doneOn(habit, facts);

    final days = <String>[];
    for (
      var key = from;
      key.compareTo(to) <= 0;
      key = addDaysToKey(key, 1)
    ) {
      if (!isScheduledOn(
        habit,
        key,
        weekStartsOn: weekStartsOn,
        doneOn: doneOn,
      )) {
        continue;
      }
      days.add(key);
      final fraction = goalFraction(habit, _dayProgress(habit, key, facts));
      fractions[key] = fraction;
      scheduled++;
      if (fraction >= 1) {
        completed++;
        run++;
        if (run > bestStreak) bestStreak = run;
      } else {
        run = 0;
      }
    }

    var streak = 0;
    var allowPending = true;
    for (final key in days.reversed) {
      if ((fractions[key] ?? 0) >= 1) {
        streak++;
      } else if (key == to && allowPending) {
        // Today is not done yet rather than missed.
        allowPending = false;
      } else {
        break;
      }
    }

    stats.add(
      HabitStat(
        habitId: habit.id,
        fractions: fractions,
        streak: streak,
        bestStreak: bestStreak,
        completed: completed,
        scheduled: scheduled,
      ),
    );
  }

  return stats;
}
