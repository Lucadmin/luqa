import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/habits/domain/habit.dart';
import 'package:luqa/features/habits/domain/habit_day.dart';
import 'package:luqa/features/habits/presentation/habit_formatters.dart';
import 'package:luqa/features/habits/presentation/widgets/habit_ring.dart';

/// How much room the control has: a full row, or a chip on the Today strip.
enum HabitControlSize { card, compact }

/// The one thing you actually do to a habit.
///
/// Three goals, three controls, one gesture: a tap. A task is a check, a count
/// is a ring that fills a step at a time, a duration is a ring you start and
/// pause. Nothing here opens a menu or asks a question first — a habit that
/// takes two taps to tick is a habit that stops being ticked.
class HabitControl extends StatelessWidget {
  const HabitControl({
    required this.day,
    required this.now,
    required this.onToggle,
    required this.onIncrement,
    required this.onDecrement,
    required this.onStart,
    required this.onStop,
    this.size = HabitControlSize.card,
    super.key,
  });

  final HabitDay day;
  final DateTime now;
  final VoidCallback onToggle;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final HabitControlSize size;

  double get _diameter => size == HabitControlSize.card ? 42 : 28;
  double get _glyph => size == HabitControlSize.card ? 20 : 14;

  @override
  Widget build(BuildContext context) {
    final color = Color(day.habit.colorValue);
    return KeyedSubtree(
      key: ValueKey('habit-control-${day.id}'),
      child: _control(color),
    );
  }

  Widget _control(Color color) => switch (day.habit.goalType) {
      HabitGoalType.task => _TaskCheck(
        day: day,
        color: color,
        diameter: _diameter,
        glyph: _glyph,
        onToggle: onToggle,
      ),
      HabitGoalType.count => _CountRing(
        day: day,
        now: now,
        color: color,
        diameter: _diameter,
        glyph: _glyph,
        compact: size == HabitControlSize.compact,
        onIncrement: onIncrement,
        onDecrement: onDecrement,
      ),
      HabitGoalType.time => _TimerRing(
        day: day,
        now: now,
        color: color,
        diameter: _diameter,
        glyph: _glyph,
        onStart: onStart,
        onStop: onStop,
      ),
    };
}

/// The shared press behaviour: a haptic, and a target no smaller than a thumb.
///
/// The ring itself stays the size the layout asked for; the tap area around it
/// grows to 48 regardless, so a 28px chip control is still comfortably
/// hittable at the edge of a scrolling strip.
class _Tappable extends StatelessWidget {
  const _Tappable({
    required this.label,
    required this.onTap,
    required this.child,
    this.onLongPress,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          onTap();
        },
        onLongPress: onLongPress == null
            ? null
            : () {
                unawaited(HapticFeedback.mediumImpact());
                onLongPress!();
              },
        radius: 24,
        containedInkWell: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(child: ExcludeSemantics(child: child)),
        ),
      ),
    );
  }
}

class _TaskCheck extends StatelessWidget {
  const _TaskCheck({
    required this.day,
    required this.color,
    required this.diameter,
    required this.glyph,
    required this.onToggle,
  });

  final HabitDay day;
  final Color color;
  final double diameter;
  final double glyph;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = LuqaPalette.of(context);
    final done = day.done;
    return _Tappable(
      label: habitActionLabel(day),
      onTap: onToggle,
      child: AnimatedContainer(
        duration: LuqaMotion.state,
        curve: LuqaMotion.curve,
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? color : Colors.transparent,
          border: Border.all(
            color: done ? color : palette.border,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.check_rounded,
          size: glyph,
          weight: 700,
          // The tick is always drawn, and only its opacity moves: the circle
          // fills and the mark arrives together rather than one after it.
          color: done
              ? _onColor(context, color)
              : Colors.transparent,
        ),
      ),
    );
  }
}

class _CountRing extends StatelessWidget {
  const _CountRing({
    required this.day,
    required this.now,
    required this.color,
    required this.diameter,
    required this.glyph,
    required this.compact,
    required this.onIncrement,
    required this.onDecrement,
  });

  final HabitDay day;
  final DateTime now;
  final Color color;
  final double diameter;
  final double glyph;
  final bool compact;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = day.habit.targetCount < 1 ? 1 : day.habit.targetCount;
    final done = day.done;

    return _Tappable(
      label: habitActionLabel(day),
      // Tapping adds one; once the count is full a tap steps back down, which
      // is what someone who overshot reaches for. A long press takes one off
      // at any point, so undoing a mis-tap never means tapping all the way
      // round to the top.
      onTap: done ? onDecrement : onIncrement,
      onLongPress: day.count > 0 ? onDecrement : null,
      child: HabitRing(
        fraction: day.liveFraction(now),
        color: color,
        size: diameter,
        child: done
            ? Icon(Icons.check_rounded, size: glyph, weight: 700, color: color)
            : Text(
                compact ? '${day.count}' : '${day.count}/$target',
                style: (compact
                        ? theme.textTheme.labelSmall
                        : theme.textTheme.labelMedium)
                    ?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w700,
                    ),
              ),
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  const _TimerRing({
    required this.day,
    required this.now,
    required this.color,
    required this.diameter,
    required this.glyph,
    required this.onStart,
    required this.onStop,
  });

  final HabitDay day;
  final DateTime now;
  final Color color;
  final double diameter;
  final double glyph;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final running = day.isRunning;
    // Done and stopped is a tick; anything else is the thing to do next.
    final icon = running
        ? Icons.pause_rounded
        : day.isDoneAt(now)
        ? Icons.check_rounded
        : Icons.play_arrow_rounded;

    return _Tappable(
      label: habitActionLabel(day),
      onTap: running ? onStop : onStart,
      child: HabitRing(
        fraction: day.liveFraction(now),
        color: color,
        size: diameter,
        child: Icon(icon, size: glyph, color: color, weight: 700),
      ),
    );
  }
}

/// Ink that stays legible on a habit's own colour, whichever one was picked.
Color _onColor(BuildContext context, Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? Colors.white
    : LuqaColors.lightInk;
