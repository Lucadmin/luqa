import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/gym/application/exercise_history_provider.dart';
import 'package:luqa/features/gym/application/gym_overview_controller.dart';
import 'package:luqa/features/gym/domain/gym_math.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';
import 'package:luqa/features/gym/presentation/gym_formatters.dart';
import 'package:luqa/features/gym/presentation/widgets/exercise_progress_chart.dart';

class ExerciseHistoryScreen extends ConsumerStatefulWidget {
  const ExerciseHistoryScreen({
    required this.exerciseId,
    this.initialLocationId,
    super.key,
  });

  final String exerciseId;
  final String? initialLocationId;

  @override
  ConsumerState<ExerciseHistoryScreen> createState() =>
      _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends ConsumerState<ExerciseHistoryScreen> {
  /// The gyms currently on the chart, or null while the screen is still using
  /// the default. Leaving it null until the first tap is what lets the default
  /// follow the data: every gym that has this exercise, or just the one the
  /// caller arrived from.
  Set<String?>? _enabled;

  /// One line through every selected gym instead of a line each — progress as a
  /// single story rather than a comparison.
  var _combined = false;

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(gymOverviewControllerProvider).overview;
    // Always the whole history: which gyms are shown is a filter over these
    // points, so toggling one is instant and needs no second read.
    final request = (
      exerciseId: widget.exerciseId,
      locationId: null,
      beforeSessionId: null,
    );
    final history = ref.watch(gymExerciseHistoryProvider(request));
    final exerciseName = overview?.exerciseById(widget.exerciseId)?.name;

    return Scaffold(
      appBar: AppBar(title: Text(exerciseName ?? 'Exercise history')),
      body: history.when(
        loading: () => const _HistorySkeleton(),
        error: (error, _) => _HistoryError(
          onRetry: () => ref.invalidate(gymExerciseHistoryProvider(request)),
        ),
        data: (data) {
          final gyms = _gymsInHistory(overview, data.points);
          final enabled = _selection(gyms);
          // Records and totals are read off what is on screen: with one gym
          // showing, a lift that only beat that gym's best is its record.
          final visible = markPersonalRecords([
            for (final point in data.points)
              if (enabled.contains(point.locationId)) point,
          ]);
          final shown = [
            for (final gym in gyms)
              if (enabled.contains(gym)) gym,
          ];

          return RefreshIndicator(
            onRefresh: () async =>
                ref.refresh(gymExerciseHistoryProvider(request).future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                LuqaSpacing.lg,
                LuqaSpacing.lg,
                LuqaSpacing.lg,
                LuqaSpacing.section,
              ),
              children: [
                Text(
                  data.exercise.name,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                if (gyms.length > 1) ...[
                  const SizedBox(height: LuqaSpacing.lg),
                  _GymFilterBar(
                    gyms: gyms,
                    enabled: enabled,
                    overview: overview,
                    onToggle: (gym) => _toggle(gyms, gym),
                  ),
                ],
                const SizedBox(height: LuqaSpacing.xl),
                if (enabled.isEmpty)
                  const _EmptyChart(
                    message: 'No gyms picked. Turn one on to see the line.',
                  )
                else ...[
                  ExerciseProgressChart(
                    series: _series(context, overview, visible, shown),
                    height: 148,
                  ),
                  if (shown.length > 1) ...[
                    const SizedBox(height: LuqaSpacing.lg),
                    _ChartModeToggle(
                      combined: _combined,
                      onChanged: (value) => setState(() => _combined = value),
                    ),
                  ],
                ],
                const SizedBox(height: LuqaSpacing.xl),
                _MetricRow(points: visible),
                const SizedBox(height: LuqaSpacing.section),
                Text('Recent', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: LuqaSpacing.md),
                if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: LuqaSpacing.xl,
                    ),
                    child: Text(
                      data.points.isEmpty
                          ? 'No history yet.'
                          : 'No history at the gyms you picked.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (final point in visible.reversed) ...[
                    _HistoryPointRow(
                      point: point,
                      location: overview?.locationById(point.locationId),
                      showLocation: gyms.length > 1,
                    ),
                    const Divider(),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// The gyms this exercise was actually done at, in the order the gym list
  /// keeps them. A gym with nothing to plot would only be a switch that does
  /// nothing, so it never reaches the row.
  List<String?> _gymsInHistory(
    GymOverview? overview,
    List<GymExercisePoint> points,
  ) {
    final seen = <String?>{for (final point in points) point.locationId};
    final ordered = <String?>[];
    for (final location in overview?.locations ?? const <GymLocation>[]) {
      if (seen.remove(location.id)) ordered.add(location.id);
    }
    // Workouts logged without a gym, then anything logged at a gym this
    // device no longer knows about.
    if (seen.remove(null)) ordered.add(null);
    ordered.addAll(seen);
    return ordered;
  }

  Set<String?> _selection(List<String?> gyms) {
    final chosen = _enabled;
    if (chosen != null) return chosen;
    final initial = widget.initialLocationId;
    // Arriving from a workout at one gym opens on that gym, which is the
    // comparison that was being made a tap ago.
    if (initial != null && gyms.contains(initial)) return {initial};
    return gyms.toSet();
  }

  void _toggle(List<String?> gyms, String? gym) {
    final next = _selection(gyms).toSet();
    if (!next.remove(gym)) next.add(gym);
    setState(() => _enabled = next);
  }

  List<ExerciseProgressSeries> _series(
    BuildContext context,
    GymOverview? overview,
    List<GymExercisePoint> visible,
    List<String?> shown,
  ) {
    // One gym is already one line, and it keeps its own colour so the chart
    // still matches the dot on its chip.
    if (_combined && shown.length > 1) {
      return [
        ExerciseProgressSeries(
          label: 'All picked gyms',
          color: Theme.of(context).colorScheme.primary,
          points: visible,
          // The line is one colour because it is one story, but each workout
          // keeps its gym's dot, so a jump can still be placed.
          dotColors: [
            for (final point in visible)
              _gymColor(context, overview, point.locationId),
          ],
        ),
      ];
    }
    return [
      for (final gym in shown)
        ExerciseProgressSeries(
          label: _gymName(overview, gym),
          color: _gymColor(context, overview, gym),
          points: [
            for (final point in visible)
              if (point.locationId == gym) point,
          ],
        ),
    ];
  }
}

String _gymName(GymOverview? overview, String? id) =>
    overview?.locationById(id)?.name ?? (id == null ? 'No gym' : 'Other gym');

Color _gymColor(BuildContext context, GymOverview? overview, String? id) {
  final location = overview?.locationById(id);
  return location == null
      ? Theme.of(context).colorScheme.outline
      : Color(location.colorValue);
}

/// The gyms on the chart, as switches. Doubles as the chart's legend: the dot
/// beside each name is the colour that gym's line is drawn in.
class _GymFilterBar extends StatelessWidget {
  const _GymFilterBar({
    required this.gyms,
    required this.enabled,
    required this.overview,
    required this.onToggle,
  });

  final List<String?> gyms;
  final Set<String?> enabled;
  final GymOverview? overview;
  final ValueChanged<String?> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: LuqaSpacing.sm,
      runSpacing: LuqaSpacing.sm,
      children: [
        for (final gym in gyms)
          FilterChip(
            key: ValueKey('gym-filter-${gym ?? 'none'}'),
            // The dot is the legend, so it stays put instead of being
            // swapped for a tick when the gym is on.
            showCheckmark: false,
            avatar: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _gymColor(context, overview, gym),
                shape: BoxShape.circle,
              ),
            ),
            label: Text(_gymName(overview, gym)),
            selected: enabled.contains(gym),
            onSelected: (_) => onToggle(gym),
          ),
      ],
    );
  }
}

class _ChartModeToggle extends StatelessWidget {
  const _ChartModeToggle({required this.combined, required this.onChanged});

  final bool combined;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('Per gym')),
          ButtonSegment(value: true, label: Text('Across gyms')),
        ],
        selected: {combined},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.points});

  /// Only what is on the chart. Numbers that counted gyms the reader has
  /// switched off would contradict the line above them.
  final List<GymExercisePoint> points;

  @override
  Widget build(BuildContext context) {
    double? best;
    double? heaviest;
    for (final point in points) {
      final oneRepMax = point.bestOneRepMax;
      if (oneRepMax != null && (best == null || oneRepMax > best)) {
        best = oneRepMax;
      }
      final weight = point.topWeight;
      if (weight != null && (heaviest == null || weight > heaviest)) {
        heaviest = weight;
      }
    }
    return Row(
      children: [
        _Metric(
          label: 'Best e1RM',
          value: best == null ? '—' : '${formatGymNumber(best)} kg',
        ),
        _Metric(
          label: 'Top weight',
          value: heaviest == null ? '—' : '${formatGymNumber(heaviest)} kg',
        ),
        _Metric(label: 'Workouts', value: '${points.length}'),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: LuqaSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPointRow extends StatelessWidget {
  const _HistoryPointRow({
    required this.point,
    required this.location,
    required this.showLocation,
  });

  final GymExercisePoint point;
  final GymLocation? location;
  final bool showLocation;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(point.dateKey) ?? DateTime.now();
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 68),
      child: Row(
        children: [
          if (showLocation) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: location == null
                    ? Theme.of(context).colorScheme.outline
                    : Color(location!.colorValue),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: LuqaSpacing.md),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gymDatedLabel(context, date),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: LuqaSpacing.xs),
                Text(
                  [
                    if (showLocation && location != null) location!.name,
                    point.raw.isEmpty ? gymReferenceSummary(point) : point.raw,
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (point.isPersonalRecord)
            Text(
              'PR',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(onPressed: onRetry, child: const Text('Try again')),
    );
  }
}
