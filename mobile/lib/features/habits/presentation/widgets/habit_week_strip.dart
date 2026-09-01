import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/habits/domain/habit.dart';
import 'package:luqa/features/habits/domain/habit_day.dart';
import 'package:luqa/features/habits/domain/habit_schedule.dart';

/// The week around the selected day, with how each day went.
///
/// The dots are the point: a week you can read at a glance is what turns a
/// list of today's habits into a sense of how the week is going, without a
/// chart or a second screen.
class HabitWeekStrip extends StatelessWidget {
  const HabitWeekStrip({
    required this.selectedDate,
    required this.todayDate,
    required this.habits,
    required this.facts,
    required this.weekStartsOn,
    required this.onSelect,
    required this.onShiftWeek,
    super.key,
  });

  final String selectedDate;
  final String todayDate;
  final List<Habit> habits;
  final HabitDayFacts facts;
  final int weekStartsOn;
  final ValueChanged<String> onSelect;
  final ValueChanged<int> onShiftWeek;

  static const _letters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final start = startOfWeek(parseDateKey(selectedDate), weekStartsOn);
    final days = [
      for (var offset = 0; offset < 7; offset++)
        DateTime(start.year, start.month, start.day + offset),
    ];

    return Row(
      children: [
        _WeekArrow(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Previous week',
          onPressed: () => onShiftWeek(-7),
        ),
        for (final date in days)
          Expanded(
            child: _DayCell(
              date: date,
              letter: _letters[weekdayIndex(date)],
              selected: dateKeyOf(date) == selectedDate,
              isToday: dateKeyOf(date) == todayDate,
              marks: _marksFor(dateKeyOf(date)),
              onTap: () => onSelect(dateKeyOf(date)),
            ),
          ),
        _WeekArrow(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Next week',
          onPressed: () => onShiftWeek(7),
        ),
      ],
    );
  }

  /// One mark per habit due that day, filled once its goal was met.
  ///
  /// Resolved in one pass over all the habits rather than one per habit: which
  /// days a rolling interval is due on depends on the days around it, so this
  /// is the same work the day list does and there is no cheaper shortcut.
  ///
  /// Capped at four: past that the dots stop being countable and start being
  /// texture, and the day cell has to stay a comfortable target.
  List<_Mark> _marksFor(String dateKey) {
    final due = resolveHabitDay(
      habits: habits,
      dateKey: dateKey,
      facts: facts,
      weekStartsOn: weekStartsOn,
    );
    return [
      for (final day in due.take(4))
        _Mark(color: Color(day.habit.colorValue), done: day.done),
    ];
  }
}

class _Mark {
  const _Mark({required this.color, required this.done});

  final Color color;
  final bool done;
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.letter,
    required this.selected,
    required this.isToday,
    required this.marks,
    required this.onTap,
  });

  final DateTime date;
  final String letter;
  final bool selected;
  final bool isToday;
  final List<_Mark> marks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: '${date.day}, ${marks.where((m) => m.done).length} '
          'of ${marks.length} done',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LuqaRadii.control),
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.sm),
            decoration: BoxDecoration(
              color: selected ? palette.raised : Colors.transparent,
              borderRadius: BorderRadius.circular(LuqaRadii.control),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  letter,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: LuqaSpacing.xs),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${date.day}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isToday
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: LuqaSpacing.xs),
                SizedBox(
                  height: 5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final mark in marks)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: mark.done
                                  ? mark.color
                                  // Due and not done reads as an outline, not
                                  // as a second colour to decode.
                                  : palette.border,
                              shape: BoxShape.circle,
                            ),
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
    );
  }
}

class _WeekArrow extends StatelessWidget {
  const _WeekArrow({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 40,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      icon: Icon(icon, size: 20),
    ),
  );
}
