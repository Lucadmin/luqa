import 'package:luqa/features/habits/domain/habit.dart';
import 'package:luqa/features/habits/domain/habit_day.dart';
import 'package:luqa/features/habits/domain/habit_schedule.dart';

/// "1h 25m", "45m", "2h" — a duration goal at rest.
String habitDuration(int seconds) {
  final total = seconds < 0 ? 0 : seconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  if (hours == 0 && minutes == 0) return total == 0 ? '0m' : '<1m';
  if (hours == 0) return '${minutes}m';
  if (minutes == 0) return '${hours}h';
  return '${hours}h ${minutes}m';
}

/// The line under a habit's name: where it has got to, and when it is due.
///
/// Built as parts rather than a sentence so a long name and a large text size
/// can drop the tail rather than wrapping into three lines.
String habitProgressLine(HabitDay day, DateTime now) {
  final parts = <String>[];
  final habit = day.habit;

  switch (habit.goalType) {
    case HabitGoalType.time:
      final period = goalPeriodLabel(habit.goalPeriod);
      parts.add(
        '${habitDuration(day.liveSeconds(now))} / '
        '${habitDuration(habit.targetSeconds)}'
        '${period.isEmpty ? '' : ' $period'}',
      );
    case HabitGoalType.count:
      parts.add('${day.count} / ${habit.targetCount}');
    case HabitGoalType.task:
      break;
  }

  final target = day.periodTarget;
  if (target != null) {
    parts.add(
      '${day.periodDone ?? 0}/$target ${quotaPeriodLabel(habit.scheduleType)}',
    );
  } else {
    parts.add(scheduleSummary(habit));
  }

  return parts.join(' · ');
}

/// What the check-in control does next, as a screen reader would say it.
String habitActionLabel(HabitDay day) => switch (day.habit.goalType) {
  HabitGoalType.task => day.done ? 'Mark not done' : 'Mark done',
  HabitGoalType.count => day.done ? 'Remove one' : 'Add one',
  HabitGoalType.time => day.isRunning ? 'Pause timer' : 'Start timer',
};
