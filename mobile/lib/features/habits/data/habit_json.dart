import 'package:luqa/features/habits/domain/habit.dart';
import 'package:luqa_api/api.dart' as api;

/// Codecs shared by the write queue, the read cache, and the network, so a
/// habit written by any one of them is readable by the others.

String hexColor(int value) =>
    '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

int colorValueOf(String value) {
  final hex = value.startsWith('#') ? value.substring(1) : value;
  final parsed = int.tryParse(hex, radix: 16);
  // An unreadable colour is not worth failing a habit over; it gets the
  // default accent and everything else about the row survives.
  return parsed == null ? 0xFFF5C451 : 0xFF000000 | parsed;
}

// --- enums ------------------------------------------------------------------
//
// Wire names are the enum's own spelling, so a stored habit and a synced one
// decode through the same path. An unrecognised value falls back rather than
// throwing: a row written by a newer build must not make the cache unreadable.

const _goalTypeNames = {
  HabitGoalType.task: 'TASK',
  HabitGoalType.count: 'COUNT',
  HabitGoalType.time: 'TIME',
};

const _goalPeriodNames = {
  HabitGoalPeriod.day: 'DAY',
  HabitGoalPeriod.week: 'WEEK',
  HabitGoalPeriod.month: 'MONTH',
};

const _scheduleTypeNames = {
  HabitScheduleType.daily: 'DAILY',
  HabitScheduleType.weekdays: 'WEEKDAYS',
  HabitScheduleType.interval: 'INTERVAL',
  HabitScheduleType.timesPerWeek: 'TIMES_PER_WEEK',
  HabitScheduleType.timesPerMonth: 'TIMES_PER_MONTH',
  HabitScheduleType.timesPerYear: 'TIMES_PER_YEAR',
  HabitScheduleType.dates: 'DATES',
};

String goalTypeName(HabitGoalType value) => _goalTypeNames[value]!;
String goalPeriodName(HabitGoalPeriod value) => _goalPeriodNames[value]!;
String scheduleTypeName(HabitScheduleType value) => _scheduleTypeNames[value]!;

HabitGoalType goalTypeFromName(String? value) => _goalTypeNames.entries
    .firstWhere(
      (entry) => entry.value == value,
      orElse: () => const MapEntry(HabitGoalType.task, 'TASK'),
    )
    .key;

HabitGoalPeriod goalPeriodFromName(String? value) => _goalPeriodNames.entries
    .firstWhere(
      (entry) => entry.value == value,
      orElse: () => const MapEntry(HabitGoalPeriod.day, 'DAY'),
    )
    .key;

HabitScheduleType scheduleTypeFromName(String? value) => _scheduleTypeNames
    .entries
    .firstWhere(
      (entry) => entry.value == value,
      orElse: () => const MapEntry(HabitScheduleType.daily, 'DAILY'),
    )
    .key;

api.HabitGoalType goalTypeToApi(HabitGoalType value) => switch (value) {
  HabitGoalType.task => api.HabitGoalType.TASK,
  HabitGoalType.count => api.HabitGoalType.COUNT,
  HabitGoalType.time => api.HabitGoalType.TIME,
};

api.HabitGoalPeriod goalPeriodToApi(HabitGoalPeriod value) => switch (value) {
  HabitGoalPeriod.day => api.HabitGoalPeriod.DAY,
  HabitGoalPeriod.week => api.HabitGoalPeriod.WEEK,
  HabitGoalPeriod.month => api.HabitGoalPeriod.MONTH,
};

api.HabitScheduleType scheduleTypeToApi(HabitScheduleType value) =>
    switch (value) {
      HabitScheduleType.daily => api.HabitScheduleType.DAILY,
      HabitScheduleType.weekdays => api.HabitScheduleType.WEEKDAYS,
      HabitScheduleType.interval => api.HabitScheduleType.INTERVAL,
      HabitScheduleType.timesPerWeek => api.HabitScheduleType.TIMES_PER_WEEK,
      HabitScheduleType.timesPerMonth => api.HabitScheduleType.TIMES_PER_MONTH,
      HabitScheduleType.timesPerYear => api.HabitScheduleType.TIMES_PER_YEAR,
      HabitScheduleType.dates => api.HabitScheduleType.DATES,
    };

// --- domain <- network ------------------------------------------------------

Habit habitFromApi(api.Habit value) => Habit(
  id: value.id,
  name: value.name,
  icon: value.icon,
  colorValue: colorValueOf(value.color),
  order: value.order,
  goalType: goalTypeFromName(value.goalType.toString()),
  goalPeriod: goalPeriodFromName(value.goalPeriod.toString()),
  targetCount: value.targetCount,
  targetSeconds: value.targetSeconds,
  categoryId: value.categoryId,
  scheduleType: scheduleTypeFromName(value.scheduleType.toString()),
  weekdays: List<int>.unmodifiable(value.weekdays),
  weekInterval: value.weekInterval,
  intervalDays: value.intervalDays,
  timesPerPeriod: value.timesPerPeriod,
  anchorDate: value.anchorDate,
  dates: List<String>.unmodifiable(value.dates),
  excludedDates: List<String>.unmodifiable(value.excludedDates),
  archived: value.archived,
  createdAt: value.createdAt.toLocal(),
);

HabitLog habitLogFromApi(api.HabitLog value) => HabitLog(
  habitId: value.habitId,
  date: value.date,
  count: value.count,
  seconds: value.seconds,
  runningSince: value.runningSince?.toLocal(),
  completedAt: value.completedAt?.toLocal(),
);

// --- stored form ------------------------------------------------------------

Map<String, Object?> habitToJson(Habit value) => {
  'id': value.id,
  'name': value.name,
  'icon': value.icon,
  'color': value.colorValue,
  'order': value.order,
  'goalType': goalTypeName(value.goalType),
  'goalPeriod': goalPeriodName(value.goalPeriod),
  'targetCount': value.targetCount,
  'targetSeconds': value.targetSeconds,
  'categoryId': value.categoryId,
  'scheduleType': scheduleTypeName(value.scheduleType),
  'weekdays': value.weekdays,
  'weekInterval': value.weekInterval,
  'intervalDays': value.intervalDays,
  'timesPerPeriod': value.timesPerPeriod,
  'anchorDate': value.anchorDate,
  'dates': value.dates,
  'excludedDates': value.excludedDates,
  'archived': value.archived,
  'createdAt': value.createdAt.toUtc().toIso8601String(),
};

Habit habitFromJson(Map<String, Object?> value) => Habit(
  id: value['id']! as String,
  name: value['name']! as String,
  icon: value['icon'] as String?,
  colorValue: value['color']! as int,
  order: value['order']! as int,
  goalType: goalTypeFromName(value['goalType'] as String?),
  goalPeriod: goalPeriodFromName(value['goalPeriod'] as String?),
  targetCount: value['targetCount']! as int,
  targetSeconds: value['targetSeconds']! as int,
  categoryId: value['categoryId'] as String?,
  scheduleType: scheduleTypeFromName(value['scheduleType'] as String?),
  weekdays: [for (final day in value['weekdays']! as List<Object?>) day! as int],
  weekInterval: value['weekInterval']! as int,
  intervalDays: value['intervalDays']! as int,
  timesPerPeriod: value['timesPerPeriod']! as int,
  anchorDate: value['anchorDate'] as String?,
  dates: [for (final key in value['dates']! as List<Object?>) key! as String],
  excludedDates: [
    for (final key in value['excludedDates']! as List<Object?>) key! as String,
  ],
  archived: value['archived']! as bool,
  createdAt: DateTime.parse(value['createdAt']! as String).toLocal(),
);
