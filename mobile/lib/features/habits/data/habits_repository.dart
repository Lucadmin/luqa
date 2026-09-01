import 'package:luqa/features/habits/domain/habit.dart';

/// A habit as the editor leaves it, before it has an id or a place in the list.
class HabitDraft {
  const HabitDraft({
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.goalType,
    required this.goalPeriod,
    required this.targetCount,
    required this.targetSeconds,
    required this.categoryId,
    required this.scheduleType,
    required this.weekdays,
    required this.weekInterval,
    required this.intervalDays,
    required this.timesPerPeriod,
    required this.anchorDate,
    required this.dates,
    required this.excludedDates,
  });

  final String name;
  final String? icon;
  final int colorValue;
  final HabitGoalType goalType;
  final HabitGoalPeriod goalPeriod;
  final int targetCount;
  final int targetSeconds;
  final String? categoryId;
  final HabitScheduleType scheduleType;
  final List<int> weekdays;
  final int weekInterval;
  final int intervalDays;
  final int timesPerPeriod;
  final String? anchorDate;
  final List<String> dates;
  final List<String> excludedDates;

  /// The draft as a habit, once an identity and a place in the list are known.
  Habit toHabit({
    required String id,
    required int order,
    required DateTime createdAt,
  }) => Habit(
    id: id,
    name: name,
    icon: icon,
    colorValue: colorValue,
    order: order,
    goalType: goalType,
    // A period target only means anything for a duration goal; anything else
    // is a daily one however the editor was left.
    goalPeriod: goalType == HabitGoalType.time ? goalPeriod : HabitGoalPeriod.day,
    targetCount: targetCount,
    targetSeconds: targetSeconds,
    // The same for the category link: it is what makes a duration goal read
    // from tracked time, and means nothing on a task or a count.
    categoryId: goalType == HabitGoalType.time ? categoryId : null,
    scheduleType: scheduleType,
    weekdays: weekdays,
    weekInterval: weekInterval,
    intervalDays: intervalDays,
    timesPerPeriod: timesPerPeriod,
    anchorDate: anchorDate,
    dates: dates,
    excludedDates: excludedDates,
    archived: false,
    createdAt: createdAt,
  );
}

/// Everything the habits screens read and write.
///
/// Progress is written as the day's resolved state rather than as an action to
/// apply. The device has already worked out what the tap means — it resolves
/// habits locally — and sending the result is what lets a check-in be queued
/// and retried without the count drifting.
abstract interface class HabitsRepository {
  /// Every habit, archived included. Callers filter for what they are drawing.
  Future<List<Habit>> loadHabits();

  /// Stored progress across an inclusive range of logical days.
  Future<List<HabitLog>> loadLogs({required String from, required String to});

  Future<Habit> createHabit(HabitDraft draft, {String? id});

  Future<Habit> saveHabit(Habit habit);

  Future<void> archiveHabit(String id);

  /// Persists a whole ordering of habit ids.
  Future<void> reorderHabits(List<String> ids);

  Future<HabitLog> writeLog(HabitLog log);
}
