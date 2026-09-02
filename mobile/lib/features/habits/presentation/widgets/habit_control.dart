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

/// What a tap on a habit does next, decided once.
///
/// The chip on the timeline strip makes its whole surface the target rather
/// than the ring at its end, so the same decision has to be reachable from two
/// places. It lives here so there is one answer to "what does tapping this
/// habit mean", not one per widget that offers the gesture.
class HabitAction {
  const HabitAction({
    required this.label,
    required this.onTap,
    this.onLongPress,
  });

  /// What the gesture does next, as a screen reader would say it.
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
}

/// The callbacks a habit's day can be changed through.
class HabitActions {
  const HabitActions({
    required this.onToggle,
    required this.onIncrement,
    required this.onDecrement,
    required this.onStart,
    required this.onStop,
  });

  final VoidCallback onToggle;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onStart;
  final VoidCallback onStop;

  /// The primary gesture for [day]'s goal type.
  ///
  /// A task toggles. A count adds one, and once it is full a tap steps back
  /// down — which is what someone who overshot reaches for; a long press takes
  /// one off at any point, so undoing a mis-tap never means tapping all the way
  /// round to the top. A duration starts and pauses.
  HabitAction primaryFor(HabitDay day) => switch (day.habit.goalType) {
    HabitGoalType.task => HabitAction(
      label: habitActionLabel(day),
      onTap: onToggle,
    ),
    HabitGoalType.count => HabitAction(
      label: habitActionLabel(day),
      onTap: day.done ? onDecrement : onIncrement,
      onLongPress: day.count > 0 ? onDecrement : null,
    ),
    HabitGoalType.time => HabitAction(
      label: habitActionLabel(day),
      onTap: day.isRunning ? onStop : onStart,
    ),
  };
}

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
    required this.actions,
    this.size = HabitControlSize.card,
    this.interactive = true,
    super.key,
  });

  final HabitDay day;
  final DateTime now;
  final HabitActions actions;
  final HabitControlSize size;

  /// Whether the control carries the gesture itself.
  ///
  /// False on the timeline strip, where the whole chip is the target: two
  /// nested ink wells would fight over the same tap, and the outer one is the
  /// bigger, better target.
  final bool interactive;

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
        action: interactive ? actions.primaryFor(day) : null,
      ),
      HabitGoalType.count => _CountRing(
        day: day,
        now: now,
        color: color,
        diameter: _diameter,
        glyph: _glyph,
        compact: size == HabitControlSize.compact,
        action: interactive ? actions.primaryFor(day) : null,
      ),
      HabitGoalType.time => _TimerRing(
        day: day,
        now: now,
        color: color,
        diameter: _diameter,
        glyph: _glyph,
        action: interactive ? actions.primaryFor(day) : null,
      ),
    };
}

/// The shared press behaviour: a haptic, and a target no smaller than a thumb.
///
/// The ring itself stays the size the layout asked for; the tap area around it
/// grows to 48 regardless, so a 28px chip control is still comfortably
/// hittable at the edge of a scrolling strip.
///
/// With no [action] the control is drawn and nothing else — the gesture belongs
/// to something larger around it, and its semantics with it.
class _Tappable extends StatelessWidget {
  const _Tappable({required this.action, required this.child});

  final HabitAction? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    if (action == null) return child;

    final onLongPress = action.onLongPress;
    return Semantics(
      button: true,
      label: action.label,
      child: InkResponse(
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          action.onTap();
        },
        onLongPress: onLongPress == null
            ? null
            : () {
                unawaited(HapticFeedback.mediumImpact());
                onLongPress();
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
    required this.action,
  });

  final HabitDay day;
  final Color color;
  final double diameter;
  final double glyph;
  final HabitAction? action;

  @override
  Widget build(BuildContext context) {
    final palette = LuqaPalette.of(context);
    final done = day.done;
    return _Tappable(
      action: action,
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
    required this.action,
  });

  final HabitDay day;
  final DateTime now;
  final Color color;
  final double diameter;
  final double glyph;
  final bool compact;
  final HabitAction? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = day.habit.targetCount < 1 ? 1 : day.habit.targetCount;
    final done = day.done;

    return _Tappable(
      action: action,
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
    required this.action,
  });

  final HabitDay day;
  final DateTime now;
  final Color color;
  final double diameter;
  final double glyph;
  final HabitAction? action;

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
      action: action,
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
