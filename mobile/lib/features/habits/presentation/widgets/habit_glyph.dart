import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/habits/domain/habit.dart';
import 'package:luqa/features/habits/presentation/habit_icons.dart';

/// A habit's mark: its icon on a wash of its own colour.
///
/// The wash is the colour at low opacity rather than the colour itself, so a
/// list of twelve habits reads as a quiet column with twelve accents rather
/// than twelve competing blocks.
class HabitGlyph extends StatelessWidget {
  const HabitGlyph({
    required this.habit,
    this.size = 44,
    this.faded = false,
    super.key,
  });

  final Habit habit;
  final double size;

  /// Dimmed, for a habit whose day is already done.
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.colorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedOpacity(
      duration: LuqaMotion.state,
      opacity: faded ? 0.55 : 1,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          // A little more presence in the dark, where a 13% wash disappears
          // into the surface it sits on.
          color: color.withValues(alpha: isDark ? 0.2 : 0.13),
          borderRadius: BorderRadius.circular(
            size <= 28 ? size / 2 : LuqaRadii.control,
          ),
        ),
        child: Icon(habitIconFor(habit.icon), size: size * 0.45, color: color),
      ),
    );
  }
}
