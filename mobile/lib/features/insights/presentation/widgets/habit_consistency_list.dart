import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/insights/application/insights_habits_provider.dart';
import 'package:luqa/features/habits/presentation/widgets/habit_glyph.dart';
import 'package:luqa/features/insights/presentation/insights_formatters.dart';

/// How the habits held up, against what the schedule actually asked for.
///
/// The denominator is the days a habit was due, not the days in the span. A
/// habit due on Mondays has not failed on a Tuesday, and a bar that said
/// otherwise would be inventing misses.
class HabitConsistencyList extends StatelessWidget {
  const HabitConsistencyList({required this.entries, super.key});

  final List<HabitConsistency> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          if (index > 0) const SizedBox(height: LuqaSpacing.md),
          _HabitRow(entry: entries[index]),
        ],
      ],
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.entry});

  final HabitConsistency entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final habit = entry.habit;
    final stat = entry.stat;
    final color = Color(habit.colorValue);

    return Semantics(
      label:
          '${habit.name}, ${stat.completed} of ${stat.scheduled} days done, '
          '${percent(stat.rate)}'
          '${stat.streak > 1 ? ', ${stat.streak} day streak' : ''}',
      excludeSemantics: true,
      child: Row(
        children: [
          HabitGlyph(habit: habit, size: 28),
          const SizedBox(width: LuqaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        habit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(width: LuqaSpacing.sm),
                    Text(
                      '${stat.completed}/${stat.scheduled}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: LuqaSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(LuqaRadii.indicator),
                  child: LinearProgressIndicator(
                    value: stat.rate.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: palette.raised,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
