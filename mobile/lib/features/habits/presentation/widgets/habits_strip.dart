import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/habits/application/habits_controller.dart';
import 'package:luqa/features/habits/domain/habit_day.dart';
import 'package:luqa/features/habits/presentation/widgets/habit_control.dart';
import 'package:luqa/features/habits/presentation/widgets/habit_glyph.dart';
import 'package:luqa/features/habits/presentation/widgets/habit_ring.dart';

/// The habits of the day the timeline is showing, as one scrolling line.
///
/// This is where habits are actually kept up: in the middle of logging the
/// day, not on a screen you have to remember to visit. A chip is a whole
/// interaction — the name to know which it is, the control to read it at a
/// glance, and the whole surface as the target — and the row ends with the
/// day's tally, which is also the way through to everything else about them.
///
/// It belongs to the day on screen behind it. Scroll the timeline back to
/// Tuesday and this is Tuesday's line: what was due then, how it went, and a
/// tap that lands on Tuesday.
class HabitsStrip extends ConsumerStatefulWidget {
  const HabitsStrip({required this.now, super.key});

  /// The screen's clock, which advances once a minute.
  ///
  /// Enough for everything on this row except a running ring, which gets a
  /// faster one of its own below — see [_HabitsStripState._ticking].
  final DateTime now;

  static const height = 46.0;

  /// How much of the scrolling line is faded out under the summary.
  static const _fade = 20.0;

  @override
  ConsumerState<HabitsStrip> createState() => _HabitsStripState();
}

class _HabitsStripState extends ConsumerState<HabitsStrip> {
  Timer? _ticker;
  late DateTime _now = widget.now;

  @override
  void didUpdateWidget(HabitsStrip old) {
    super.didUpdateWidget(old);
    // The screen's minute is the floor: a second-hand of our own may be ahead
    // of it, but it is never behind.
    if (widget.now.isAfter(_now)) _now = widget.now;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Runs a clock only while there is something on the row that moves.
  ///
  /// A duration habit's ring fills continuously, and on the screen's own
  /// minute clock it would sit visibly still for the best part of a minute —
  /// which reads as broken rather than as running. The rest of the time this
  /// row has no business rebuilding sixty times a minute, so it does not.
  void _ticking(bool running) {
    if (running == (_ticker != null)) return;
    if (!running) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitsControllerProvider);
    final controller = ref.read(habitsControllerProvider.notifier);
    final days = state.stripDay;

    _ticking(days.any((day) => day.isRunning));

    // The height is held through the first load rather than collapsed, so the
    // timeline underneath does not jump down the moment the cache answers.
    if (state.isLoading && days.isEmpty) {
      return const SizedBox(height: HabitsStrip.height);
    }

    return SizedBox(
      height: HabitsStrip.height,
      child: Row(
        children: [
          Expanded(
            child: days.isEmpty
                ? _NothingDue(hasHabits: state.habits.isNotEmpty)
                : _ChipList(
                    days: days,
                    now: _now,
                    // The day on screen, not today: this line belongs to the
                    // grid behind it, and a tap has to land on the day the
                    // person tapping it can see.
                    dateKey: state.stripDate,
                    controller: controller,
                  ),
          ),
          // Outside the scroll rather than at the end of it. The tally and the
          // way through to the rest of habits are the two things on this line
          // that have to be reachable without reading it — and a chip at the
          // far end of six habits is neither.
          _DayTally(
            done: state.stripDoneCount,
            total: days.length,
            hasHabits: state.habits.isNotEmpty,
            isToday: state.stripIsToday,
          ),
        ],
      ),
    );
  }
}

/// The scrolling line itself, with its trailing edge faded out.
///
/// The fade is what lets a chip pass under the tally instead of colliding with
/// it. A vertical rule would be the other way to separate them, but it would
/// meet the divider under the strip at a corner and read as a stray tick.
class _ChipList extends StatelessWidget {
  const _ChipList({
    required this.days,
    required this.now,
    required this.dateKey,
    required this.controller,
  });

  final List<HabitDay> days;
  final DateTime now;
  final String dateKey;
  final HabitsController controller;

  @override
  Widget build(BuildContext context) {
    final canvas = Theme.of(context).scaffoldBackgroundColor;

    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [canvas.withValues(alpha: 0), canvas],
        stops: const [0, 1],
      ).createShader(
        Rect.fromLTWH(
          bounds.width - HabitsStrip._fade,
          0,
          HabitsStrip._fade,
          bounds.height,
        ),
      ),
      blendMode: BlendMode.dstIn,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
          left: LuqaSpacing.lg,
          right: LuqaSpacing.sm,
        ),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: LuqaSpacing.sm),
        itemBuilder: (context, index) {
          final day = days[index];
          return _HabitChip(
            key: ValueKey('habit-chip-${day.id}'),
            day: day,
            now: now,
            actions: HabitActions(
              onToggle: () => controller.toggle(day.id, dateKey: dateKey),
              onIncrement: () => controller.increment(day.id, dateKey: dateKey),
              onDecrement: () => controller.decrement(day.id, dateKey: dateKey),
              onStart: () => controller.startTimer(day.id, dateKey: dateKey),
              onStop: () => controller.stopTimer(day.id, dateKey: dateKey),
            ),
          );
        },
      ),
    );
  }
}

/// One habit, and the gesture that moves it on.
///
/// The whole chip is the target rather than the ring at its end. A habit that
/// takes aim before it takes a tap is a habit that stops being ticked, and a
/// 140-wide chip is a target a thumb finds without looking at it.
class _HabitChip extends StatelessWidget {
  const _HabitChip({
    required this.day,
    required this.now,
    required this.actions,
    super.key,
  });

  final HabitDay day;
  final DateTime now;
  final HabitActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final action = actions.primaryFor(day);
    final colour = Color(day.habit.colorValue);
    final onLongPress = action.onLongPress;

    return Semantics(
      button: true,
      label: '${day.habit.name}. ${action.label}',
      child: Material(
        // Flat and crisp: raised tone, no border, 6px corners. A pill is for a
        // tag or a status, and this is neither — it is a control.
        color: day.done
            // The Tint Ceiling: a finished habit's own colour washes the chip
            // so the row reads at a glance, well short of full saturation,
            // which is kept for the marks on top of it.
            ? Color.alphaBlend(colour.withValues(alpha: 0.10), palette.raised)
            : palette.raised,
        borderRadius: BorderRadius.circular(LuqaRadii.compact),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
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
          child: ExcludeSemantics(
            child: Padding(
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
                  // Drawn, not tapped: the chip around it owns the gesture, so
                  // the two are never competing for the same finger.
                  HabitControl(
                    day: day,
                    now: now,
                    actions: actions,
                    size: HabitControlSize.compact,
                    interactive: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The day with habits but none of them due on it.
class _NothingDue extends StatelessWidget {
  const _NothingDue({required this.hasHabits});

  final bool hasHabits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: LuqaSpacing.lg),
        child: Text(
          // With no habits at all this line is the invitation to make one, so
          // it says what to do rather than reporting that there is nothing.
          hasHabits ? 'Nothing due' : 'Add a habit',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// How the day is going, and the way through to the rest of habits.
///
/// A ring rather than a pill: the arc is the same mark every habit on the row
/// already wears, so the tally reads as the sum of the line instead of as one
/// more chip on the end of it. Ghost at rest — no container until it is
/// pressed — because it is the quietest thing on a row of controls.
class _DayTally extends StatelessWidget {
  const _DayTally({
    required this.done,
    required this.total,
    required this.hasHabits,
    required this.isToday,
  });

  final int done;
  final int total;
  final bool hasHabits;

  /// A tally for a day the timeline was scrolled to is drawn muted rather than
  /// in Luqa purple, so a number that is not about today never looks like it
  /// is. The header directly above already names the day; this only has to
  /// avoid contradicting it.
  final bool isToday;

  static const _diameter = 32.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final complete = total > 0 && done == total;
    final muted = theme.colorScheme.onSurfaceVariant;
    final accent = isToday ? theme.colorScheme.primary : muted;

    // Terse on purpose. This sits beside a scrolling line of habits, so every
    // character it spends is a character of habit name that no longer fits;
    // the full sentence is in the semantics label instead.
    final Widget centre;
    if (total == 0) {
      centre = Icon(
        hasHabits ? Icons.checklist_rounded : Icons.add_rounded,
        size: 15,
        color: muted,
      );
    } else if (complete) {
      centre = Icon(
        Icons.check_rounded,
        size: 16,
        weight: 700,
        color: accent,
      );
    } else {
      centre = Text(
        '$done/$total',
        style: theme.textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }

    return Semantics(
      button: true,
      label: switch ((total, hasHabits)) {
        (0, false) => 'Add a habit',
        (0, true) => 'Habits, nothing due',
        _ => 'Habits, $done of $total done',
      },
      child: Padding(
        padding: const EdgeInsets.only(right: LuqaSpacing.sm),
        child: InkResponse(
          key: const ValueKey('habits-strip-all'),
          onTap: () => context.push('/habits'),
          radius: 24,
          containedInkWell: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
            child: Center(
              child: ExcludeSemantics(
                child: HabitRing(
                  fraction: total == 0 ? 0 : done / total,
                  color: accent,
                  size: _diameter,
                  stroke: 2.5,
                  child: centre,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
