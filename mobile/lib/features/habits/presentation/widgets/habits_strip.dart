import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/habits/application/habits_controller.dart';
import 'package:luqa/features/habits/domain/habit_day.dart';
import 'package:luqa/features/habits/presentation/widgets/habit_control.dart';
import 'package:luqa/features/habits/presentation/widgets/habit_glyph.dart';

/// Today's habits, as one scrolling line.
///
/// This is where habits are actually kept up: in the middle of logging the
/// day, not on a screen you have to remember to visit. A chip is a whole
/// interaction — the name to know which it is, and the control to tick it —
/// and the row ends with the way through to everything else about them.
class HabitsStrip extends ConsumerWidget {
  const HabitsStrip({required this.now, super.key});

  /// Passed in rather than read here, so the running rings tick on the same
  /// clock as the timeline they sit above rather than on one of their own.
  final DateTime now;

  static const height = 46.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitsControllerProvider);
    final controller = ref.read(habitsControllerProvider.notifier);

    // The height is held through the first load rather than collapsed, so the
    // timeline underneath does not jump down the moment the cache answers.
    if (state.isLoading && state.day.isEmpty) {
      return const SizedBox(height: height);
    }

    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(
                left: LuqaSpacing.lg,
                right: LuqaSpacing.sm,
              ),
              itemCount: state.day.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: LuqaSpacing.sm),
              itemBuilder: (context, index) {
                final day = state.day[index];
                return _HabitChip(
                  key: ValueKey('habit-chip-${day.id}'),
                  day: day,
                  now: now,
                  onToggle: () => controller.toggle(day.id),
                  onIncrement: () => controller.increment(day.id),
                  onDecrement: () => controller.decrement(day.id),
                  onStart: () => controller.startTimer(day.id),
                  onStop: () => controller.stopTimer(day.id),
                );
              },
            ),
          ),
          // Outside the scroll rather than at the end of it. The tally and the
          // way through to the rest of habits are the two things on this line
          // that have to be reachable without reading it — and a chip at the
          // far end of six habits is neither.
          Padding(
            padding: const EdgeInsets.only(right: LuqaSpacing.lg),
            child: _AllHabitsChip(
              done: state.doneCount,
              total: state.day.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitChip extends StatelessWidget {
  const _HabitChip({
    required this.day,
    super.key,
    required this.now,
    required this.onToggle,
    required this.onIncrement,
    required this.onDecrement,
    required this.onStart,
    required this.onStop,
  });

  final HabitDay day;
  final DateTime now;
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
        borderRadius: BorderRadius.circular(HabitsStrip.height / 2),
      ),
      padding: const EdgeInsets.only(left: LuqaSpacing.xs, right: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HabitGlyph(habit: day.habit, size: 26, faded: day.done),
          const SizedBox(width: LuqaSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 116),
            child: Text(
              day.habit.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: day.done
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: LuqaSpacing.xxs),
          HabitControl(
            day: day,
            now: now,
            size: HabitControlSize.compact,
            onToggle: onToggle,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
            onStart: onStart,
            onStop: onStop,
          ),
        ],
      ),
    );
  }
}

/// The end of the strip, and the way through to the rest of habits.
///
/// It carries the day's tally rather than only a plus, so the line answers
/// "how am I doing" without being scrolled to the end and read chip by chip.
class _AllHabitsChip extends StatelessWidget {
  const _AllHabitsChip({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final complete = total > 0 && done == total;
    // Terse on purpose. This chip is pinned beside a scrolling line of
    // habits, so every character it spends is a character of habit name that
    // no longer fits; the full sentence is in the semantics label instead.
    final label = total == 0 ? 'Add a habit' : '$done/$total';

    return Semantics(
      button: true,
      label: total == 0 ? 'Add a habit' : 'Habits, $done of $total done',
      child: InkWell(
        key: const ValueKey('habits-strip-all'),
        onTap: () => context.push('/habits'),
        borderRadius: BorderRadius.circular(HabitsStrip.height / 2),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: palette.border,
              // Dashed is not worth a custom painter here; the open outline
              // and the muted ink already read as "not a habit, a way out".
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(HabitsStrip.height / 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: LuqaSpacing.md),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  total == 0 ? Icons.add_rounded : Icons.checklist_rounded,
                  size: 16,
                  color: complete
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: LuqaSpacing.xs),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: complete
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: LuqaSpacing.xxs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
