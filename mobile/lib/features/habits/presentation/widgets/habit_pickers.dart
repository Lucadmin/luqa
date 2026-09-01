import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/habits/presentation/habit_icons.dart';

/// The small label above a group of fields in the habit editor.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: 11,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// A row of mutually exclusive options.
///
/// A segmented control rather than a dropdown: there are never more than three
/// of these, and seeing the alternatives is most of what makes a goal type or
/// a period comprehensible in the first place.
class HabitSegmented<T> extends StatelessWidget {
  const HabitSegmented({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    super.key,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.raised,
        borderRadius: BorderRadius.circular(LuqaRadii.control),
      ),
      child: Row(
        children: [
          for (final value in values)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == selected,
                label: labelOf(value),
                child: InkWell(
                  onTap: () => onChanged(value),
                  borderRadius: BorderRadius.circular(LuqaRadii.compact),
                  child: AnimatedContainer(
                    duration: LuqaMotion.press,
                    curve: LuqaMotion.curve,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == selected
                          ? palette.workingSurface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(LuqaRadii.compact),
                      border: Border.all(
                        color: value == selected
                            ? palette.border
                            : Colors.transparent,
                      ),
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        labelOf(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: value == selected
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A number with a minus and a plus either side of it.
///
/// Typing "3" into a keyboard to mean three glasses of water is more work than
/// the number deserves, and a stepper cannot be left in a state that will not
/// parse.
class HabitStepper extends StatelessWidget {
  const HabitStepper({
    required this.value,
    required this.label,
    required this.onChanged,
    this.min = 1,
    this.max = 999,
    this.step = 1,
    super.key,
  });

  final int value;
  final String label;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: palette.raised,
        borderRadius: BorderRadius.circular(LuqaRadii.compact),
      ),
      child: Row(
        children: [
          _Step(
            icon: Icons.remove_rounded,
            tooltip: 'Fewer',
            onPressed: value > min ? () => onChanged(value - step) : null,
          ),
          Expanded(
            child: Semantics(
              label: '$label: $value',
              child: ExcludeSemantics(
                child: Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _Step(
            icon: Icons.add_rounded,
            tooltip: 'More',
            onPressed: value < max ? () => onChanged(value + step) : null,
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.tooltip, this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 48,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
    ),
  );
}

/// Sunday-first day-of-week toggles, matching how a habit stores them.
class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({
    required this.selected,
    required this.weekStartsOn,
    required this.onChanged,
    super.key,
  });

  final List<int> selected;
  final int weekStartsOn;
  final ValueChanged<List<int>> onChanged;

  static const _letters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _names = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);

    return Row(
      children: [
        // Shown starting on the day the account's week starts on, so the row
        // reads the way this person's calendar does.
        for (var offset = 0; offset < 7; offset++)
          Builder(
            builder: (context) {
              final day = (weekStartsOn + offset) % 7;
              final isOn = selected.contains(day);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: offset == 6 ? 0 : 6),
                  child: Semantics(
                    button: true,
                    selected: isOn,
                    label: _names[day],
                    child: InkWell(
                      onTap: () => onChanged(
                        isOn
                            ? [
                                for (final value in selected)
                                  if (value != day) value,
                              ]
                            : [...selected, day]..sort(),
                      ),
                      borderRadius: BorderRadius.circular(LuqaRadii.compact),
                      child: AnimatedContainer(
                        duration: LuqaMotion.press,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isOn
                              ? theme.colorScheme.primary
                              : palette.raised,
                          borderRadius: BorderRadius.circular(
                            LuqaRadii.compact,
                          ),
                        ),
                        child: ExcludeSemantics(
                          child: Text(
                            _letters[day],
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isOn
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// The icon and colour a habit is recognised by.
///
/// Both in one horizontal band: they are the same decision — what this looks
/// like at a glance in a strip — and separating them into two scrolling rows
/// would make the sheet longer without making the choice clearer.
class HabitAppearancePicker extends StatelessWidget {
  const HabitAppearancePicker({
    required this.icon,
    required this.colorValue,
    required this.onIconChanged,
    required this.onColorChanged,
    super.key,
  });

  final String? icon;
  final int colorValue;
  final ValueChanged<String> onIconChanged;
  final ValueChanged<int> onColorChanged;

  @override
  Widget build(BuildContext context) {
    final palette = LuqaPalette.of(context);
    final selected = Color(colorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: habitColorValues.length,
            separatorBuilder: (_, _) => const SizedBox(width: LuqaSpacing.sm),
            itemBuilder: (context, index) {
              final value = habitColorValues[index];
              final isOn = value == colorValue;
              return Semantics(
                button: true,
                selected: isOn,
                label: 'Colour ${index + 1}',
                child: InkResponse(
                  onTap: () => onColorChanged(value),
                  radius: 24,
                  child: Container(
                    width: 36,
                    height: 44,
                    alignment: Alignment.center,
                    child: Container(
                      width: isOn ? 30 : 26,
                      height: isOn ? 30 : 26,
                      decoration: BoxDecoration(
                        color: Color(value),
                        shape: BoxShape.circle,
                        border: isOn
                            ? Border.all(color: palette.canvas, width: 3)
                            : null,
                        boxShadow: isOn
                            ? [
                                BoxShadow(
                                  color: Color(value).withValues(alpha: 0.5),
                                  blurRadius: 0,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: LuqaSpacing.md),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: habitIconNames.length,
            separatorBuilder: (_, _) => const SizedBox(width: LuqaSpacing.sm),
            itemBuilder: (context, index) {
              final name = habitIconNames[index];
              final isOn = name == (icon ?? defaultHabitIcon);
              return Semantics(
                button: true,
                selected: isOn,
                label: 'Icon ${index + 1}',
                child: InkWell(
                  onTap: () => onIconChanged(name),
                  borderRadius: BorderRadius.circular(LuqaRadii.control),
                  child: Container(
                    width: 48,
                    decoration: BoxDecoration(
                      color: isOn
                          ? selected.withValues(alpha: isDark ? 0.24 : 0.16)
                          : palette.raised,
                      borderRadius: BorderRadius.circular(LuqaRadii.control),
                      border: Border.all(
                        color: isOn ? selected : Colors.transparent,
                      ),
                    ),
                    child: ExcludeSemantics(
                      child: Icon(
                        habitIcons[name],
                        size: 20,
                        color: isOn
                            ? selected
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
