import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/today/application/today_controller.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa/features/today/presentation/log_time_sheet.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';
import 'package:luqa/features/today/presentation/widgets/today_timeline.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  Future<void> _openLogTime(BuildContext context) async {
    final added = await showLogTimeSheet(context);
    if (!context.mounted || !added) return;
    await HapticFeedback.lightImpact();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry added to the timeline.')),
    );
  }

  void _showTimerPreview(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Live timer is the next state in this vertical slice.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayControllerProvider);
    final user = ref.watch(authControllerProvider).value?.user;
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator.adaptive(
        onRefresh: () => ref.read(todayControllerProvider.notifier).retry(),
        child: CustomScrollView(
          key: const PageStorageKey('today-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TodayHeader(day: state.day, initial: user?.initial),
                        _SyncStatus(state: state),
                        const SizedBox(height: LuqaSpacing.xl),
                        _CaptureActions(
                          enabled: !state.isLoading,
                          onLogTime: () => _openLogTime(context),
                          onStartTimer: () => _showTimerPreview(context),
                        ),
                        const SizedBox(height: LuqaSpacing.lg),
                        _SleepRow(sleep: state.sleep),
                        const Divider(),
                        _HabitStrip(habits: state.habits),
                        const Divider(),
                        const SizedBox(height: LuqaSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Timeline', style: theme.textTheme.titleLarge),
                            if (!state.isLoading)
                              Text(
                                '${compactDuration(_tracked(state.entries))} tracked',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: LuqaSpacing.md),
                        _TimelineBody(state: state),
                        const SizedBox(height: LuqaSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Duration _tracked(List<TimeEntry> entries) =>
      entries.fold(Duration.zero, (total, entry) => total + entry.duration);
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.day, required this.initial});

  final DateTime day;
  final String? initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Today', style: theme.textTheme.headlineLarge),
              const SizedBox(height: LuqaSpacing.xs),
              Text(
                fullDate(day),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: LuqaSpacing.sm),
        Semantics(
          button: true,
          label: 'Profile',
          child: InkWell(
            onTap: () => context.push('/profile'),
            borderRadius: BorderRadius.circular(LuqaRadii.control),
            child: SizedBox.square(
              dimension: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: LuqaPalette.of(context).raised,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial ?? 'L',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CaptureActions extends StatelessWidget {
  const _CaptureActions({
    required this.enabled,
    required this.onLogTime,
    required this.onStartTimer,
  });

  final bool enabled;
  final VoidCallback onLogTime;
  final VoidCallback onStartTimer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            key: const ValueKey('log-time-button'),
            onPressed: enabled ? onLogTime : null,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Log time'),
          ),
        ),
        const SizedBox(width: LuqaSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled ? onStartTimer : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start timer'),
          ),
        ),
      ],
    );
  }
}

class _SleepRow extends StatelessWidget {
  const _SleepRow({required this.sleep});

  final Duration? sleep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: sleep == null
          ? 'Sleep data not connected'
          : '${compactDuration(sleep!)} sleep',
      child: InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sleep detail is ready for Health data.'),
          ),
        ),
        borderRadius: BorderRadius.circular(LuqaRadii.control),
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 38,
                  child: Icon(
                    Icons.bedtime_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: LuqaSpacing.md),
              Expanded(
                child: Text(
                  sleep == null
                      ? 'Sleep data not connected'
                      : '${compactDuration(sleep!)} sleep',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitStrip extends StatelessWidget {
  const _HabitStrip({required this.habits});

  final List<HabitSnapshot> habits;

  IconData _iconFor(String key) => switch (key) {
    'water' => Icons.water_drop_outlined,
    'read' => Icons.menu_book_outlined,
    _ => Icons.accessibility_new_rounded,
  };

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const _EmptyHabitRow();
    }
    return Semantics(
      button: true,
      label: 'Today habits. Open habit management.',
      child: InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Habit management route is reserved.')),
        ),
        borderRadius: BorderRadius.circular(LuqaRadii.control),
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (final habit in habits) ...[
                Expanded(
                  child: _HabitItem(
                    icon: _iconFor(habit.iconKey),
                    name: habit.name,
                    progress: habit.progress,
                    color: Color(habit.colorValue),
                  ),
                ),
              ],
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHabitRow extends StatelessWidget {
  const _EmptyHabitRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: LuqaSpacing.md),
          Expanded(
            child: Text(
              'Habits are not connected yet',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatus extends StatelessWidget {
  const _SyncStatus({required this.state});

  final TodayState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = state.isOffline
        ? 'Offline · showing saved data'
        : state.isRefreshing
        ? 'Updating…'
        : null;
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : LuqaMotion.state,
      child: message == null
          ? const SizedBox.shrink(key: ValueKey('today-synced'))
          : Padding(
              key: ValueKey(message),
              padding: const EdgeInsets.only(top: LuqaSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    state.isOffline
                        ? Icons.cloud_off_outlined
                        : Icons.sync_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: LuqaSpacing.sm),
                  Text(
                    message,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TimelineBody extends ConsumerWidget {
  const _TimelineBody({required this.state});

  final TodayState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.entries.isEmpty) {
      return const _TimelineSkeleton();
    }
    if (state.error != null && state.entries.isEmpty) {
      return _TimelineLoadError(
        message: state.error!,
        onRetry: () => ref.read(todayControllerProvider.notifier).retry(),
      );
    }
    if (state.entries.isEmpty) {
      return const _EmptyTimeline();
    }
    return TodayTimeline(entries: state.entries, categories: state.categories);
  }
}

class _TimelineSkeleton extends StatelessWidget {
  const _TimelineSkeleton();

  @override
  Widget build(BuildContext context) {
    final raised = LuqaPalette.of(context).raised;
    return ExcludeSemantics(
      child: Column(
        children: [
          for (final width in [0.72, 0.92, 0.58]) ...[
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: raised,
                    borderRadius: BorderRadius.circular(LuqaRadii.control),
                  ),
                  child: const SizedBox(height: 72),
                ),
              ),
            ),
            const SizedBox(height: LuqaSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _TimelineLoadError extends StatelessWidget {
  const _TimelineLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: LuqaPalette.of(context).border),
        borderRadius: BorderRadius.circular(LuqaRadii.surface),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LuqaSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_off_outlined),
            const SizedBox(height: LuqaSpacing.md),
            Text(message, style: theme.textTheme.bodyLarge),
            const SizedBox(height: LuqaSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.section),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: LuqaSpacing.md),
            Text('Nothing logged yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: LuqaSpacing.xs),
            Text(
              'Add the first part of your day when you are ready.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitItem extends StatelessWidget {
  const _HabitItem({
    required this.icon,
    required this.name,
    required this.progress,
    required this.color,
  });

  final IconData icon;
  final String name;
  final String progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(width: LuqaSpacing.xs),
        Flexible(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium,
          ),
        ),
        const SizedBox(width: LuqaSpacing.xs),
        Text(
          progress,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
