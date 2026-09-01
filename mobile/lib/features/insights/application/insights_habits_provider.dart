import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/features/habits/data/habits_providers.dart';
import 'package:luqa/features/habits/data/tracked_time.dart';
import 'package:luqa/features/habits/domain/habit.dart';
import 'package:luqa/features/habits/domain/habit_day.dart';
import 'package:luqa/features/habits/domain/habit_schedule.dart';
import 'package:luqa/features/today/data/today_providers.dart';
import 'package:luqa/features/today/domain/timeline_geometry.dart';

/// A habit and how it actually went over the span on screen.
class HabitConsistency {
  const HabitConsistency({required this.habit, required this.stat});

  final Habit habit;
  final HabitStat stat;
}

/// How the habits held up over a span of Insights.
///
/// Kept apart from the rest of the screen deliberately: habits are a different
/// collection with a different sync, and a phone that has the timeline but not
/// yet the habits should show the wall rather than an error. This provider
/// failing costs the reader one section, not the tab.
final insightsHabitsProvider = FutureProvider.autoDispose
    .family<List<HabitConsistency>, ({DateTime from, DateTime to})>((
      ref,
      range,
    ) async {
      final habits = ref.watch(habitsRepositoryProvider);
      final timeline = ref.watch(todayRepositoryProvider);
      final settings = ref.watch(localFirstHabitsRepositoryProvider);
      final startHour = settings?.dayStartHour ?? dayStartHour;
      final weekStartsOn = settings?.weekStartsOn ?? 1;

      final live = [
        for (final habit in await habits.loadHabits())
          if (!habit.archived) habit,
      ];
      if (live.isEmpty) return const [];

      final from = dateKeyOf(range.from);
      final to = dateKeyOf(addDays(range.to, -1));

      // A habit due "every third day unless it was done" decides each day from
      // the days before it, so the read has to start before the span does or
      // its first days would be resolved against nothing.
      final lookback = live
          .map((habit) => habit.rollingLookbackDays)
          .fold(0, math.max);
      final readFrom = addDaysToKey(from, -lookback);

      final logs = await habits.loadLogs(from: readFrom, to: to);
      final window = await timeline.loadWindow(
        DateTime(range.from.year, range.from.month, range.from.day - lookback),
        // Exclusive, and a day past the end so a block begun late on the last
        // day is still inside it.
        DateTime(range.to.year, range.to.month, range.to.day + 1),
      );

      final stats = resolveHabitStats(
        habits: live,
        from: from,
        to: to,
        facts: habitDayFacts(
          logs: logs,
          entries: window.entries,
          dayStartHour: startHour,
        ),
        weekStartsOn: weekStartsOn,
      );
      final byHabit = {for (final stat in stats) stat.habitId: stat};

      return [
        for (final habit in live)
          if ((byHabit[habit.id]?.scheduled ?? 0) > 0)
            HabitConsistency(habit: habit, stat: byHabit[habit.id]!),
      ];
    });
