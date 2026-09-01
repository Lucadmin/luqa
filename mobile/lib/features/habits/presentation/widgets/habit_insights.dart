import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/habits/domain/habit.dart';
import 'package:luqa/features/habits/domain/habit_day.dart';
import 'package:luqa/features/habits/domain/habit_schedule.dart';
import 'package:luqa/features/habits/presentation/widgets/habit_glyph.dart';

/// How each habit has actually been going.
///
/// Four weeks, one square a day, and the two numbers that matter: the streak
/// you are protecting and the share of days you managed. Days the habit was
/// not due are drawn as gaps rather than as misses — a habit due on Mondays
/// has not failed on a Tuesday.
class HabitInsights extends StatelessWidget {
  const HabitInsights({
    required this.habits,
    required this.facts,
    required this.todayDate,
    required this.weekStartsOn,
    super.key,
  });

  final List<Habit> habits;
  final HabitDayFacts facts;
  final String todayDate;
  final int weekStartsOn;

  static const windowDays = 28;

  @override
  Widget build(BuildContext context) {
    final from = addDaysToKey(todayDate, -(windowDays - 1));
    final stats = resolveHabitStats(
      habits: habits,
      from: from,
      to: todayDate,
      facts: facts,
      weekStartsOn: weekStartsOn,
    );
    final byHabit = {for (final stat in stats) stat.habitId: stat};
    final days = [
      for (var offset = 0; offset < windowDays; offset++)
        addDaysToKey(from, offset),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        LuqaSpacing.lg,
        LuqaSpacing.md,
        LuqaSpacing.lg,
        LuqaSpacing.section,
      ),
      itemCount: habits.length,
      separatorBuilder: (_, _) => const SizedBox(height: LuqaSpacing.sm),
      itemBuilder: (context, index) {
        final habit = habits[index];
        return _InsightCard(
          habit: habit,
          stat: byHabit[habit.id],
          days: days,
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.habit,
    required this.stat,
    required this.days,
  });

  final Habit habit;
  final HabitStat? stat;
  final List<String> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final color = Color(habit.colorValue);
    final fractions = stat?.fractions ?? const <String, double>{};
    final streak = stat?.streak ?? 0;
    final rate = ((stat?.rate ?? 0) * 100).round();

    return Container(
      padding: const EdgeInsets.all(LuqaSpacing.md),
      decoration: BoxDecoration(
        color: palette.workingSurface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(LuqaRadii.surface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HabitGlyph(habit: habit, size: 36),
              const SizedBox(width: LuqaSpacing.md),
              Expanded(
                child: Text(
                  habit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              Semantics(
                label: '$streak day streak',
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 16,
                        color: streak > 0
                            ? color
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: LuqaSpacing.xxs),
                      Text(
                        '$streak',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: streak > 0
                              ? color
                              : theme.colorScheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LuqaSpacing.md),
          Semantics(
            label: 'Last ${HabitInsights.windowDays} days',
            child: ExcludeSemantics(
              child: Wrap(
                spacing: 3,
                runSpacing: 3,
                children: [
                  for (final day in days)
                    _DaySquare(
                      // Absent means the habit was not due; zero means it was
                      // and nothing happened. Drawn differently, because they
                      // are different facts.
                      fraction: fractions[day],
                      color: color,
                      idle: palette.raised,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: LuqaSpacing.sm),
          Text(
            '$rate% done · last ${HabitInsights.windowDays} days'
            '  ·  best streak ${stat?.bestStreak ?? 0}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySquare extends StatelessWidget {
  const _DaySquare({
    required this.fraction,
    required this.color,
    required this.idle,
  });

  final double? fraction;
  final Color color;
  final Color idle;

  @override
  Widget build(BuildContext context) {
    final value = fraction;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: value == null
            ? idle
            // Partial progress is a paler square, not a missing one: three of
            // five glasses of water is a real fact about that day.
            : color.withValues(alpha: 0.2 + 0.8 * value.clamp(0, 1)),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
