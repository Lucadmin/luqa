import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/app/top_level_header.dart';
import 'package:luqa/design_system/luqa_sync_status.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/insights/application/insights_controller.dart';
import 'package:luqa/features/insights/application/insights_habits_provider.dart';
import 'package:luqa/features/insights/domain/insights_math.dart';
import 'package:luqa/features/insights/domain/insights_models.dart';
import 'package:luqa/features/insights/presentation/insights_formatters.dart';
import 'package:luqa/features/insights/presentation/insights_readings.dart';
import 'package:luqa/features/insights/presentation/widgets/category_ranking.dart';
import 'package:luqa/features/insights/presentation/widgets/habit_consistency_list.dart';
import 'package:luqa/features/insights/presentation/widgets/readings_list.dart';
import 'package:luqa/features/insights/presentation/widgets/rhythm_wall.dart';
import 'package:luqa/features/today/application/timeline_controller.dart';
import 'package:luqa/features/today/domain/timeline_geometry.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';

/// The Insights tab.
///
/// One focal object: the rhythm wall, and the single number above it that the
/// wall is the shape of. Tapping a column moves that number onto one day and
/// everything below it follows, so the same screen answers "how was this year"
/// and "what happened on the ninth" without becoming two screens.
///
/// Everything here is computed from rows this device already holds, which is
/// why the span control is instant and why a year of history reads the same on
/// a train as it does on wifi.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsControllerProvider);
    final controller = ref.read(insightsControllerProvider.notifier);
    final report = state.report;

    if (state.isLoading && report == null) {
      return const SafeArea(child: _InsightsSkeleton());
    }
    if (report == null) {
      return SafeArea(
        child: _LoadError(
          message: state.error ?? 'Could not read your history.',
          onRetry: controller.refresh,
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: LuqaTopLevelHeader(
                primary: Text(
                  'Insights',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                status: state.isRefreshing || state.isOffline
                    ? LuqaSyncStatus(
                        isRefreshing: state.isRefreshing,
                        isOffline: state.isOffline,
                        onRetry: controller.refresh,
                        controlKey: const ValueKey('insights-sync-status'),
                      )
                    : null,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LuqaSpacing.lg,
                LuqaSpacing.lg,
                LuqaSpacing.lg,
                LuqaSpacing.section,
              ),
              sliver: SliverList.list(
                children: _body(context, ref, state, controller, report),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    WidgetRef ref,
    InsightsState state,
    InsightsController controller,
    InsightsReport report,
  ) {
    final theme = Theme.of(context);
    final selection = state.selection;
    final now = ref.watch(currentTimeProvider);

    final standings = selection == null
        ? report.standings
        : standingsForDay(selection, report.standings);
    final total = selection?.trackedMinutes ?? report.trackedMinutes;
    final readings = buildInsightsReadings(report);

    return [
      _SpanSelector(span: state.span, onChanged: controller.setSpan),
      const SizedBox(height: LuqaSpacing.md),
      _RangeBar(
        state: state,
        report: report,
        onStep: controller.step,
        onNow: controller.toNow,
      ),
      if (state.error != null) ...[
        const SizedBox(height: LuqaSpacing.md),
        _InlineError(message: state.error!, onRetry: controller.refresh),
      ],
      const SizedBox(height: LuqaSpacing.xl),
      _Headline(report: report, selection: selection),
      const SizedBox(height: LuqaSpacing.xl),
      RhythmWall(
        days: report.days,
        selected: state.selectedDay,
        now: now,
        onSelect: (day) {
          HapticFeedback.selectionClick();
          controller.select(day);
        },
      ),
      const SizedBox(height: LuqaSpacing.md),
      Text(
        selection == null
            ? 'One column a day, ${_clockLabel(dayStartHour)} to '
                  '${_clockLabel(dayStartHour)}. Tap one to read it.'
            : 'Tap the column again for the whole ${state.span.label.toLowerCase()}.',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      if (report.isEmpty) ...[
        const SizedBox(height: LuqaSpacing.section),
        _EmptySpan(isCurrent: state.isCurrent),
      ] else ...[
        const SizedBox(height: LuqaSpacing.section),
        _SectionHeading(
          title: selection == null
              ? 'Where it went'
              : relativeDayLabel(selection.day, now),
        ),
        const SizedBox(height: LuqaSpacing.lg),
        CategoryRanking(
          standings: standings,
          total: total,
          showDelta: selection == null,
        ),
        if (selection == null && readings.isNotEmpty) ...[
          const SizedBox(height: LuqaSpacing.section),
          const _SectionHeading(title: 'Patterns'),
          const SizedBox(height: LuqaSpacing.lg),
          ReadingsList(readings: readings),
        ],
        if (selection == null)
          ..._habits(context, ref, from: report.from, to: report.to),
      ],
    ];
  }

  List<Widget> _habits(
    BuildContext context,
    WidgetRef ref, {
    required DateTime from,
    required DateTime to,
  }) {
    final habits = ref
        .watch(insightsHabitsProvider((from: from, to: to)))
        .value;
    if (habits == null || habits.isEmpty) return const [];
    return [
      const SizedBox(height: LuqaSpacing.section),
      _SectionHeading(
        title: 'Habits',
        action: 'Open',
        onAction: () => context.push('/habits'),
      ),
      const SizedBox(height: LuqaSpacing.lg),
      HabitConsistencyList(entries: habits),
    ];
  }

  static String _clockLabel(int hour) =>
      '${hour.toString().padLeft(2, '0')}:00';
}

/// The number the wall is the shape of.
class _Headline extends StatelessWidget {
  const _Headline({required this.report, required this.selection});

  final InsightsReport report;
  final RhythmDay? selection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = selection;
    final minutes = day?.trackedMinutes ?? report.trackedMinutes;
    final sleep = day?.sleepMinutes ?? report.sleepMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          day == null ? 'Tracked' : fullDate(day.day),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: LuqaSpacing.sm),
        AnimatedSwitcher(
          duration: LuqaMotion.state,
          switchInCurve: LuqaMotion.curve,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.centerLeft,
            children: [...previous, ?current],
          ),
          child: Text(
            compactDuration(Duration(minutes: minutes.round())),
            key: ValueKey('${day?.day.toIso8601String() ?? 'span'}|$minutes'),
            style: theme.textTheme.displaySmall?.copyWith(
              color: minutes == 0 ? theme.colorScheme.onSurfaceVariant : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: LuqaSpacing.sm),
        for (final line in _supporting(report, day, sleep))
          Padding(
            padding: const EdgeInsets.only(top: LuqaSpacing.xxs),
            child: Text(
              line,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
      ],
    );
  }

  /// Kept to short lines rather than one long one. Three facts joined by
  /// middots wrap into a paragraph on a phone, and a paragraph under a display
  /// number stops being support and starts competing with it.
  static List<String> _supporting(
    InsightsReport report,
    RhythmDay? day,
    double sleep,
  ) {
    final asleep = sleep > 0
        ? '${compactDuration(Duration(minutes: sleep.round()))} asleep'
        : null;

    if (day != null) {
      // A day compares against nothing: the honest supporting fact is what
      // else is known about it, not a delta invented for symmetry.
      final facts = [?asleep, if (day.hasCompany) 'time with someone'];
      if (facts.isEmpty) {
        return [day.trackedMinutes == 0 ? 'Nothing recorded' : 'Tracked time'];
      }
      return [facts.join('  ·  ')];
    }

    final delta = report.delta;
    return [
      [
        '${compactDuration(Duration(minutes: report.averagePerDay.round()))} a day',
        ?asleep,
      ].join('  ·  '),
      if (delta != null)
        '${signedDuration(delta)} against the previous '
            '${report.span.label.toLowerCase()}',
    ];
  }
}

/// Week, four weeks, twelve weeks. Longer than that and a column is thinner
/// than a hairline, which is a wall that cannot be read rather than more
/// history.
class _SpanSelector extends StatelessWidget {
  const _SpanSelector({required this.span, required this.onChanged});

  final InsightsSpan span;
  final ValueChanged<InsightsSpan> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.raised,
        borderRadius: BorderRadius.circular(LuqaRadii.control),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            for (final option in InsightsSpan.values)
              Expanded(
                child: Semantics(
                  selected: option == span,
                  button: true,
                  child: InkWell(
                    key: ValueKey('insights-span-${option.name}'),
                    onTap: () => onChanged(option),
                    borderRadius: BorderRadius.circular(LuqaRadii.compact),
                    child: AnimatedContainer(
                      duration: LuqaMotion.press,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: option == span
                            ? palette.workingSurface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(LuqaRadii.compact),
                        border: Border.all(
                          color: option == span
                              ? palette.border
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        option.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: option == span
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
      ),
    );
  }
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.state,
    required this.report,
    required this.onStep,
    required this.onNow,
  });

  final InsightsState state;
  final InsightsReport report;
  final ValueChanged<int> onStep;
  final VoidCallback onNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton(
          key: const ValueKey('insights-previous'),
          tooltip: 'Previous ${state.span.label.toLowerCase()}',
          onPressed: () => onStep(-1),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        IconButton(
          key: const ValueKey('insights-next'),
          tooltip: 'Next ${state.span.label.toLowerCase()}',
          onPressed: state.isCurrent ? null : () => onStep(1),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        const SizedBox(width: LuqaSpacing.xs),
        Expanded(
          child: Text(
            insightsRangeLabel(report.from, report.to),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (!state.isCurrent)
          TextButton(
            key: const ValueKey('insights-now'),
            onPressed: onNow,
            child: const Text('Now'),
          ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _EmptySpan extends StatelessWidget {
  const _EmptySpan({required this.isCurrent});

  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      isCurrent
          ? 'Nothing here yet. Track a block or two on Today and this fills '
                'in as you go — nothing needs setting up.'
          : 'Nothing was recorded in this stretch.',
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(LuqaSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Insights', style: theme.textTheme.headlineLarge),
          const SizedBox(height: LuqaSpacing.md),
          Text(message, style: theme.textTheme.bodyLarge),
          const SizedBox(height: LuqaSpacing.lg),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _InsightsSkeleton extends StatelessWidget {
  const _InsightsSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = LuqaPalette.of(context);
    Widget block(double height, {double width = double.infinity}) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: palette.raised,
        borderRadius: BorderRadius.circular(LuqaRadii.compact),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LuqaSpacing.lg,
        LuqaSpacing.xl,
        LuqaSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(44, width: 180),
          const SizedBox(height: LuqaSpacing.xl),
          block(44),
          const SizedBox(height: LuqaSpacing.xl),
          block(52, width: 220),
          const SizedBox(height: LuqaSpacing.xl),
          block(236),
        ],
      ),
    );
  }
}
