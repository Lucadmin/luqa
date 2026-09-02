import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/habits/domain/habit_day.dart';
import 'package:luqa/features/habits/presentation/habit_formatters.dart';
import 'package:luqa/features/habits/presentation/widgets/habit_control.dart';
import 'package:luqa/features/habits/presentation/widgets/habit_glyph.dart';

/// One habit on the habits screen: what it is, where it has got to, and the
/// control to move it on.
///
/// The name and the progress open the editor; only the control on the right
/// changes anything. Keeping those apart is what lets the whole row be a
/// comfortable target for the thing you came to do without a mis-tap costing
/// you a check-in.
class HabitRow extends StatelessWidget {
  const HabitRow({
    required this.day,
    required this.now,
    required this.onEdit,
    required this.onToggle,
    required this.onIncrement,
    required this.onDecrement,
    required this.onStart,
    required this.onStop,
    super.key,
  });

  final HabitDay day;
  final DateTime now;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.workingSurface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(LuqaRadii.surface),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Edit ${day.habit.name}',
              child: InkWell(
                onTap: onEdit,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(LuqaRadii.surface),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    LuqaSpacing.md,
                    LuqaSpacing.md,
                    LuqaSpacing.sm,
                    LuqaSpacing.md,
                  ),
                  child: ExcludeSemantics(
                    child: Row(
                      children: [
                        HabitGlyph(habit: day.habit, faded: day.done),
                        const SizedBox(width: LuqaSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                day.habit.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: day.done
                                      ? theme.colorScheme.onSurfaceVariant
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: LuqaSpacing.xxs),
                              Text(
                                habitProgressLine(day, now),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: LuqaSpacing.sm),
            child: HabitControl(
              day: day,
              now: now,
              actions: HabitActions(
                onToggle: onToggle,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
                onStart: onStart,
                onStop: onStop,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
