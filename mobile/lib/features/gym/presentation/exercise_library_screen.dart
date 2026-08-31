import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/gym/application/gym_overview_controller.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _search = TextEditingController();
  String? _mergingExerciseId;

  @override
  void initState() {
    super.initState();
    _search.addListener(_redraw);
  }

  @override
  void dispose() {
    _search
      ..removeListener(_redraw)
      ..dispose();
    super.dispose();
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  Future<void> _mergeExercise(
    GymExercise source,
    List<GymExercise> exercises,
  ) async {
    final target = await showModalBottomSheet<GymExercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          _MergeTargetSheet(source: source, exercises: exercises),
    );
    if (target == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Merge exercises?'),
        content: Text(
          'All workout history from “${source.name}” will move to '
          '“${target.name}”.\n\n“${target.name}” stays in your list and '
          '“${source.name}” is removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-exercise-merge'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Merge'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _mergingExerciseId = source.id);
    final success = await ref
        .read(gymOverviewControllerProvider.notifier)
        .mergeExercise(
          sourceExerciseId: source.id,
          targetExerciseId: target.id,
        );
    if (!mounted) return;
    setState(() => _mergingExerciseId = null);

    final message = success
        ? 'Merged “${source.name}” into “${target.name}”.'
        : ref.read(gymOverviewControllerProvider).error ??
              'Could not merge the exercises.';
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gymOverviewControllerProvider);
    final overview = state.overview;
    final query = _search.text.trim().toLowerCase();
    final exercises =
        overview?.exercises
            .where(
              (exercise) =>
                  !exercise.archived &&
                  (query.isEmpty ||
                      exercise.name.toLowerCase().contains(query)),
            )
            .toList(growable: false) ??
        const <GymExercise>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      body: overview == null
          ? Center(
              child: state.isLoading
                  ? const CircularProgressIndicator()
                  : FilledButton(
                      onPressed: ref
                          .read(gymOverviewControllerProvider.notifier)
                          .load,
                      child: const Text('Try again'),
                    ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    LuqaSpacing.lg,
                    LuqaSpacing.sm,
                    LuqaSpacing.lg,
                    LuqaSpacing.lg,
                  ),
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      hintText: 'Search exercises',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                Expanded(
                  child: exercises.isEmpty
                      ? Center(
                          child: Text(
                            query.isEmpty
                                ? 'Exercises appear as you add them to workouts.'
                                : 'No exercise matches “${_search.text.trim()}”.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: LuqaSpacing.lg,
                          ),
                          itemCount: exercises.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final exercise = exercises[index];
                            final reference = _latestReference(
                              overview,
                              exercise.id,
                            );
                            final location = overview.locationById(
                              reference?.locationId,
                            );
                            return InkWell(
                              onTap: () {
                                final query = reference?.locationId == null
                                    ? ''
                                    : '?locationId=${Uri.encodeQueryComponent(reference!.locationId!)}';
                                context.push(
                                  '/gym/exercises/${exercise.id}/history$query',
                                );
                              },
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 68,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            exercise.name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge,
                                          ),
                                          const SizedBox(
                                            height: LuqaSpacing.xs,
                                          ),
                                          Text(
                                            reference == null
                                                ? 'No history yet'
                                                : [
                                                    if (location != null)
                                                      location.name,
                                                    reference.raw,
                                                  ].join(' · '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontFeatures: const [
                                                    FontFeature.tabularFigures(),
                                                  ],
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_mergingExerciseId == exercise.id)
                                      const SizedBox.square(
                                        dimension: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else
                                      PopupMenuButton<String>(
                                        key: ValueKey(
                                          'exercise-menu-${exercise.id}',
                                        ),
                                        tooltip: 'Actions for ${exercise.name}',
                                        enabled:
                                            exercises.length > 1 &&
                                            _mergingExerciseId == null,
                                        onSelected: (value) {
                                          if (value == 'merge') {
                                            _mergeExercise(exercise, exercises);
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: 'merge',
                                            child: Row(
                                              children: [
                                                Icon(Icons.merge_rounded),
                                                SizedBox(width: LuqaSpacing.sm),
                                                Flexible(
                                                  child: Text(
                                                    'Merge into another…',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _MergeTargetSheet extends StatefulWidget {
  const _MergeTargetSheet({required this.source, required this.exercises});

  final GymExercise source;
  final List<GymExercise> exercises;

  @override
  State<_MergeTargetSheet> createState() => _MergeTargetSheetState();
}

class _MergeTargetSheetState extends State<_MergeTargetSheet> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(_redraw);
  }

  @override
  void dispose() {
    _search
      ..removeListener(_redraw)
      ..dispose();
    super.dispose();
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final targets =
        widget.exercises
            .where(
              (exercise) =>
                  exercise.id != widget.source.id &&
                  !exercise.archived &&
                  (query.isEmpty ||
                      exercise.name.toLowerCase().contains(query)),
            )
            .toList()
          ..sort((left, right) => left.name.compareTo(right.name));

    return FractionallySizedBox(
      heightFactor: 0.86,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              LuqaSpacing.lg,
              LuqaSpacing.xl,
              LuqaSpacing.lg,
              LuqaSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merge “${widget.source.name}” into…',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: LuqaSpacing.xs),
                Text(
                  'Choose the exercise name you want to keep.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: LuqaSpacing.lg),
                TextField(
                  key: const ValueKey('merge-exercise-search'),
                  controller: _search,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search exercises',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: targets.isEmpty
                ? const Center(child: Text('No matching exercise.'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LuqaSpacing.sm,
                      vertical: LuqaSpacing.sm,
                    ),
                    itemCount: targets.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final target = targets[index];
                      return ListTile(
                        key: ValueKey('merge-target-${target.id}'),
                        title: Text(target.name),
                        subtitle: Text(
                          '${target.sessionCount} session'
                          '${target.sessionCount == 1 ? '' : 's'}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_rounded),
                        onTap: () => Navigator.pop(context, target),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

GymExerciseReference? _latestReference(
  GymOverview overview,
  String exerciseId,
) {
  GymExerciseReference? latest;
  for (final reference in overview.recentReferences) {
    if (reference.exerciseId != exerciseId) continue;
    if (latest == null || reference.dateKey.compareTo(latest.dateKey) > 0) {
      latest = reference;
    }
  }
  return latest;
}
