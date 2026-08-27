import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
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
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: const PageStorageKey('today-scroll'),
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
                      _TodayHeader(day: state.day),
                      const SizedBox(height: LuqaSpacing.xl),
                      _CaptureActions(
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
                          Text(
                            '${compactDuration(_tracked(state.entries))} tracked',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: LuqaSpacing.md),
                      TodayTimeline(
                        entries: state.entries,
                        categories: state.categories,
                      ),
                      const SizedBox(height: LuqaSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Duration _tracked(List<TimeEntry> entries) =>
      entries.fold(Duration.zero, (total, entry) => total + entry.duration);
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.day});

  final DateTime day;

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
                    'L',
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
  const _CaptureActions({required this.onLogTime, required this.onStartTimer});

  final VoidCallback onLogTime;
  final VoidCallback onStartTimer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            key: const ValueKey('log-time-button'),
            onPressed: onLogTime,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Log time'),
          ),
        ),
        const SizedBox(width: LuqaSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onStartTimer,
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

  final Duration sleep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${compactDuration(sleep)} sleep',
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
                  '${compactDuration(sleep)} sleep',
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
