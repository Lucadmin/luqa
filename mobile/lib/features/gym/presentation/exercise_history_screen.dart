import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/gym/application/exercise_history_provider.dart';
import 'package:luqa/features/gym/application/gym_overview_controller.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';
import 'package:luqa/features/gym/presentation/gym_formatters.dart';
import 'package:luqa/features/gym/presentation/widgets/progress_sparkline.dart';

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
  late String? _locationId = widget.initialLocationId;

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(gymOverviewControllerProvider).overview;
    final request = (
      exerciseId: widget.exerciseId,
      locationId: _locationId,
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
        data: (data) => RefreshIndicator(
          onRefresh: () async =>
              ref.refresh(gymExerciseHistoryProvider(request).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              LuqaSpacing.lg,
              LuqaSpacing.sm,
              LuqaSpacing.lg,
              LuqaSpacing.section,
            ),
            children: [
              _HistoryGymRow(
                location: overview?.locationById(_locationId),
                allGyms: _locationId == null,
                onTap: overview == null
                    ? null
                    : () => _pickLocation(overview.locations),
              ),
              const SizedBox(height: LuqaSpacing.xxl),
              Text(
                data.exercise.name,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: LuqaSpacing.xxl),
              if (_locationId == null) ...[
                Text(
                  'Choose a gym for a comparable progress line.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else ...[
                ProgressSparkline(points: data.points, height: 148),
                const SizedBox(height: LuqaSpacing.xl),
                _MetricRow(history: data),
              ],
              const SizedBox(height: LuqaSpacing.section),
              Text('Recent', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: LuqaSpacing.md),
              if (data.points.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.xl),
                  child: Text(
                    _locationId == null
                        ? 'No history yet.'
                        : 'No history at this gym yet.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                for (final point in data.points.reversed) ...[
                  _HistoryPointRow(
                    point: point,
                    location: overview?.locationById(point.locationId),
                    showLocation: _locationId == null,
                  ),
                  const Divider(),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickLocation(List<GymLocation> locations) async {
    final result = await showModalBottomSheet<_HistoryGymSelection>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          LuqaSpacing.xl,
          LuqaSpacing.sm,
          LuqaSpacing.xl,
          LuqaSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('History gym', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: LuqaSpacing.lg),
            _HistoryGymOption(
              name: 'All gyms',
              detail: 'Grouped history, no combined graph',
              selected: _locationId == null,
              onTap: () =>
                  Navigator.pop(context, const _HistoryGymSelection(null)),
            ),
            for (final location in locations.where((item) => !item.archived))
              _HistoryGymOption(
                name: location.name,
                detail: location.code,
                color: Color(location.colorValue),
                selected: location.id == _locationId,
                onTap: () =>
                    Navigator.pop(context, _HistoryGymSelection(location.id)),
              ),
          ],
        ),
      ),
    );
    if (result != null && mounted) setState(() => _locationId = result.id);
  }
}

class _HistoryGymSelection {
  const _HistoryGymSelection(this.id);
  final String? id;
}

class _HistoryGymRow extends StatelessWidget {
  const _HistoryGymRow({
    required this.location,
    required this.allGyms,
    required this.onTap,
  });

  final GymLocation? location;
  final bool allGyms;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: location == null
                    ? Theme.of(context).colorScheme.outline
                    : Color(location!.colorValue),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: LuqaSpacing.sm),
            Expanded(
              child: Text(allGyms ? 'All gyms' : location?.name ?? 'Gym'),
            ),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
      ),
    );
  }
}

class _HistoryGymOption extends StatelessWidget {
  const _HistoryGymOption({
    required this.name,
    required this.detail,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String name;
  final String detail;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color ?? Theme.of(context).colorScheme.outline,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: LuqaSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name),
                  Text(
                    detail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_rounded),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.history});

  final GymExerciseHistory history;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Metric(
          label: 'Best e1RM',
          value: history.bestEver == null
              ? '—'
              : '${formatGymNumber(history.bestEver!)} kg',
        ),
        _Metric(
          label: 'Top weight',
          value: history.heaviest == null
              ? '—'
              : '${formatGymNumber(history.heaviest!)} kg',
        ),
        _Metric(label: 'Workouts', value: '${history.points.length}'),
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
                  MaterialLocalizations.of(context).formatMediumDate(date),
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
