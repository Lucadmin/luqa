import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/discarded_writes_notice.dart';
import 'package:luqa/design_system/luqa_sync_status.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/habits/application/habits_controller.dart';
import 'package:luqa/features/habits/domain/habit.dart';
import 'package:luqa/features/habits/domain/habit_schedule.dart';
import 'package:luqa/features/habits/presentation/habit_editor_sheet.dart';
import 'package:luqa/features/habits/presentation/widgets/habit_insights.dart';
import 'package:luqa/features/habits/presentation/widgets/habit_row.dart';
import 'package:luqa/features/habits/presentation/widgets/habit_week_strip.dart';
import 'package:luqa/features/today/application/timeline_controller.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';

/// Everything about habits that does not belong on Today.
///
/// Today carries the check-ins, because that is where they happen. This is the
/// other half: which day you are looking at, the whole list rather than the
/// ones due, how each has been going, and where habits are made and changed.
class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

enum _Tab { day, insights }

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  _Tab _tab = _Tab.day;

  late DateTime _now = ref.read(currentTimeProvider);
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    // The controller outlives this screen — the strip on Today is built from
    // it — so a day browsed to last time would still be selected. Opening the
    // screen means "how am I doing", and the answer to that starts today.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(habitsControllerProvider);
      unawaited(_controller.selectDate(state.todayDate));
    });
    // One clock for the screen, so every running ring advances together
    // instead of each keeping its own.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  HabitsController get _controller =>
      ref.read(habitsControllerProvider.notifier);

  Future<void> _create() async {
    await showHabitEditorSheet(context);
  }

  Future<void> _edit(Habit habit) async {
    await showHabitEditorSheet(context, habit: habit);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitsControllerProvider);
    final theme = Theme.of(context);
    final todayKey = state.todayDate;
    final hasSyncStatus =
        state.pendingWrites > 0 || state.isOffline || state.isRefreshing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          if (hasSyncStatus)
            Padding(
              padding: const EdgeInsets.only(right: LuqaSpacing.xs),
              child: LuqaSyncStatus(
                pendingWrites: state.pendingWrites,
                isOffline: state.isOffline,
                isRefreshing: state.isRefreshing,
                onRetry: _controller.refresh,
                controlKey: const ValueKey('habits-pending-chip'),
              ),
            ),
          IconButton(
            key: const ValueKey('habits-new'),
            tooltip: 'New habit',
            onPressed: _create,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: LuqaSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          if (state.discarded.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LuqaSpacing.lg,
                0,
                LuqaSpacing.lg,
                LuqaSpacing.sm,
              ),
              child: DiscardedWritesNotice(
                discarded: state.discarded,
                onAcknowledge: _controller.acknowledgeDiscarded,
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              LuqaSpacing.sm,
              0,
              LuqaSpacing.sm,
              LuqaSpacing.sm,
            ),
            child: HabitWeekStrip(
              selectedDate: state.selectedDate,
              todayDate: todayKey,
              habits: state.habits,
              facts: state.facts,
              weekStartsOn: state.weekStartsOn,
              onSelect: _controller.selectDate,
              onShiftWeek: (days) => _controller.selectDate(
                addDaysToKey(state.selectedDate, days),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: LuqaSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _dayLabel(state.selectedDate, todayKey),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                _TabToggle(
                  selected: _tab,
                  onChanged: (tab) => setState(() => _tab = tab),
                ),
              ],
            ),
          ),
          const SizedBox(height: LuqaSpacing.sm),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _controller.refresh,
              child: switch (_tab) {
                _Tab.insights => state.isEmpty
                    ? const _Empty(
                        icon: Icons.insights_rounded,
                        title: 'Nothing to look back on yet',
                        message:
                            'Add a habit and this fills in as the days go by.',
                      )
                    : HabitInsights(
                        habits: state.habits,
                        facts: state.facts,
                        todayDate: todayKey,
                        weekStartsOn: state.weekStartsOn,
                      ),
                _Tab.day => _DayList(
                  now: _now,
                  onEdit: _edit,
                  onCreate: _create,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(String selected, String today) {
    final difference = daysBetweenKeys(today, selected);
    return switch (difference) {
      0 => 'Today',
      -1 => 'Yesterday',
      1 => 'Tomorrow',
      _ => fullDate(parseDateKey(selected)),
    };
  }
}

class _DayList extends ConsumerWidget {
  const _DayList({
    required this.now,
    required this.onEdit,
    required this.onCreate,
  });

  final DateTime now;
  final ValueChanged<Habit> onEdit;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitsControllerProvider);
    final controller = ref.read(habitsControllerProvider.notifier);

    if (state.isLoading && state.habits.isEmpty) {
      return const _DayListSkeleton();
    }
    if (state.habits.isEmpty) {
      return _Empty(
        icon: Icons.auto_awesome_rounded,
        title: 'No habits yet',
        message: 'Something to do, a number to reach, or time to put in.',
        actionLabel: 'New habit',
        onAction: onCreate,
      );
    }
    if (state.day.isEmpty) {
      return const _Empty(
        icon: Icons.event_available_rounded,
        title: 'Nothing due',
        message: 'None of your habits are scheduled for this day.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        LuqaSpacing.lg,
        LuqaSpacing.xs,
        LuqaSpacing.lg,
        LuqaSpacing.section,
      ),
      itemCount: state.day.length,
      separatorBuilder: (_, _) => const SizedBox(height: LuqaSpacing.sm),
      itemBuilder: (context, index) {
        final day = state.day[index];
        return HabitRow(
          key: ValueKey('habit-row-${day.id}'),
          day: day,
          now: now,
          onEdit: () => onEdit(day.habit),
          onToggle: () =>
              controller.toggle(day.id, dateKey: state.selectedDate),
          onIncrement: () =>
              controller.increment(day.id, dateKey: state.selectedDate),
          onDecrement: () =>
              controller.decrement(day.id, dateKey: state.selectedDate),
          onStart: () =>
              controller.startTimer(day.id, dateKey: state.selectedDate),
          onStop: () =>
              controller.stopTimer(day.id, dateKey: state.selectedDate),
        );
      },
    );
  }
}

class _TabToggle extends StatelessWidget {
  const _TabToggle({required this.selected, required this.onChanged});

  final _Tab selected;
  final ValueChanged<_Tab> onChanged;

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
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final tab in _Tab.values)
            Semantics(
              button: true,
              selected: tab == selected,
              label: tab == _Tab.day ? 'Day' : 'Insights',
              child: InkWell(
                onTap: () => onChanged(tab),
                borderRadius: BorderRadius.circular(LuqaRadii.compact),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(
                    horizontal: LuqaSpacing.md,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tab == selected
                        ? palette.workingSurface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(LuqaRadii.compact),
                  ),
                  child: ExcludeSemantics(
                    child: Text(
                      tab == _Tab.day ? 'Day' : 'Insights',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: tab == selected
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
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

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Scrollable so pull-to-refresh still works on an empty screen, which is
    // exactly where someone is most likely to try it.
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        LuqaSpacing.xl,
        LuqaSpacing.section,
        LuqaSpacing.xl,
        LuqaSpacing.xl,
      ),
      children: [
        Icon(icon, size: 28, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: LuqaSpacing.md),
        Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const SizedBox(height: LuqaSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: LuqaSpacing.xl),
          Center(
            child: FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(actionLabel!),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayListSkeleton extends StatelessWidget {
  const _DayListSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = LuqaPalette.of(context);
    return ExcludeSemantics(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          LuqaSpacing.lg,
          LuqaSpacing.xs,
          LuqaSpacing.lg,
          LuqaSpacing.lg,
        ),
        children: [
          for (var index = 0; index < 4; index++) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.raised,
                borderRadius: BorderRadius.circular(LuqaRadii.surface),
              ),
              child: const SizedBox(height: 68, width: double.infinity),
            ),
            const SizedBox(height: LuqaSpacing.sm),
          ],
        ],
      ),
    );
  }
}
