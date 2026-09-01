import 'package:luqa/features/habits/domain/habit.dart';
import 'package:luqa/features/habits/domain/habit_day.dart';
import 'package:luqa/features/habits/domain/habit_schedule.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

/// Turns the timeline's blocks into the per-day, per-category totals a
/// category-linked habit's progress is read from.
///
/// A linked habit does not keep its own count of anything: "two hours of
/// focus" is a claim about the time already tracked on that category, and this
/// is where that claim is evaluated. Doing it from the blocks this device
/// holds is what lets it be true offline.
///
/// A running block is not counted here. Its elapsed time grows every second,
/// and folding it into a total would freeze it at the moment of the call; it
/// comes back separately so a screen can add the seconds as they pass.
({Map<String, int> seconds, Map<String, DateTime> running}) trackedByCategory(
  Iterable<TimeEntry> entries, {
  required int dayStartHour,
}) {
  final seconds = <String, int>{};
  final running = <String, DateTime>{};

  for (final entry in entries) {
    final categoryId = entry.categoryId;
    if (categoryId == null) continue;

    final end = entry.end;
    if (end == null) {
      // The newest running block wins. There is normally only one, but a
      // device that stopped a timer without syncing can leave an older one
      // behind, and the later start is the one the user is looking at.
      final existing = running[categoryId];
      if (existing == null || entry.start.isAfter(existing)) {
        running[categoryId] = entry.start;
      }
      continue;
    }

    // Bucketed by where the block started, the same as the server's day
    // window: a session that runs past the day boundary belongs to the day it
    // was begun in, not split across two.
    final key = '$categoryId|${logicalDateKey(entry.start, dayStartHour)}';
    final elapsed = end.difference(entry.start).inSeconds;
    seconds[key] = (seconds[key] ?? 0) + (elapsed < 0 ? 0 : elapsed);
  }

  return (seconds: seconds, running: running);
}

/// Everything a day's habits resolve from, assembled from the rows this device
/// holds.
HabitDayFacts habitDayFacts({
  required Iterable<HabitLog> logs,
  required Iterable<TimeEntry> entries,
  required int dayStartHour,
}) {
  final tracked = trackedByCategory(entries, dayStartHour: dayStartHour);
  return HabitDayFacts(
    logs: {for (final log in logs) '${log.habitId}|${log.date}': log},
    trackedSeconds: tracked.seconds,
    runningCategories: tracked.running,
  );
}
