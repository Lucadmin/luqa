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

  /// The one exercise whose row is currently doing something slow enough to
  /// need saying so. Merging is the only such action; renaming and removing
  /// land on this device immediately.
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

  void _report(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _renameExercise(
    GymExercise exercise,
    List<GymExercise> exercises,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _RenameExerciseDialog(
        exercise: exercise,
        // Two exercises with the same name would be two histories the graph
        // cannot tell apart, which is the mess merging exists to clean up.
        // Better to name the clash and point at merging than to make it.
        taken: {
          for (final other in exercises)
            if (other.id != exercise.id) _nameKey(other.name): other.name,
        },
      ),
    );
    if (name == null || !mounted) return;

    final renamed = await ref
        .read(gymOverviewControllerProvider.notifier)
        .renameExercise(id: exercise.id, name: name);
    if (!mounted) return;
    _report(
      renamed
          ? 'Renamed “${exercise.name}” to “$name”.'
          : ref.read(gymOverviewControllerProvider).error ??
                'Could not rename the exercise.',
    );
  }

  Future<void> _deleteExercise(GymExercise exercise) async {
    final logged = exercise.sessionCount > 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete “${exercise.name}”?'),
        content: Text(
          logged
              ? 'It is on ${exercise.sessionCount} '
                    '${exercise.sessionCount == 1 ? 'workout' : 'workouts'}, so '
                    'those keep it and it leaves this list. To fold its '
                    'history into another exercise, merge instead.'
              : 'Nothing has been logged against it, so it goes for good.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-exercise-delete'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final removal = await ref
        .read(gymOverviewControllerProvider.notifier)
        .deleteExercise(exercise.id);
    if (!mounted) return;
    _report(
      removal == null
          ? ref.read(gymOverviewControllerProvider).error ??
                'Could not remove the exercise.'
          : removal.archived
          ? 'Removed “${exercise.name}”. Your logged workouts still show it.'
          : 'Deleted “${exercise.name}”.',
    );
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
    // The whole library, which is what merging and renaming reason about: a
    // name is taken whether or not the current search happens to show it.
    final library =
        overview?.exercises
            .where((exercise) => !exercise.archived)
            .toList(growable: false) ??
        const <GymExercise>[];
    final exercises = query.isEmpty
        ? library
        : library
              .where(
                (exercise) => exercise.name.toLowerCase().contains(query),
              )
              .toList(growable: false);

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
                                        enabled: _mergingExerciseId == null,
                                        onSelected: (value) => switch (value) {
                                          'rename' => _renameExercise(
                                            exercise,
                                            library,
                                          ),
                                          'merge' => _mergeExercise(
                                            exercise,
                                            library,
                                          ),
                                          'delete' => _deleteExercise(exercise),
                                          _ => null,
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'rename',
                                            child: _MenuItem(
                                              icon: Icons.edit_rounded,
                                              label: 'Rename…',
                                            ),
                                          ),
                                          // Nothing to merge into when this is
                                          // the only exercise there is.
                                          if (library.length > 1)
                                            const PopupMenuItem(
                                              value: 'merge',
                                              child: _MenuItem(
                                                icon: Icons.merge_rounded,
                                                label: 'Merge into another…',
                                              ),
                                            ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: _MenuItem(
                                              icon: Icons.delete_outline_rounded,
                                              label: 'Delete',
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

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: LuqaSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _RenameExerciseDialog extends StatefulWidget {
  const _RenameExerciseDialog({required this.exercise, required this.taken});

  final GymExercise exercise;

  /// Every other exercise's name, keyed the way a clash is judged.
  final Map<String, String> taken;

  @override
  State<_RenameExerciseDialog> createState() => _RenameExerciseDialogState();
}

class _RenameExerciseDialogState extends State<_RenameExerciseDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.exercise.name,
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(_redraw);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_redraw)
      ..dispose();
    super.dispose();
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final name = _controller.text.trim();
    final clash = widget.taken[_nameKey(name)];
    final canSave = name.isNotEmpty && clash == null;

    return AlertDialog(
      title: const Text('Rename exercise'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('rename-exercise-field'),
            controller: _controller,
            autofocus: true,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Name'),
            onSubmitted: (_) {
              if (canSave) Navigator.pop(context, name);
            },
          ),
          if (clash != null)
            Text(
              '“$clash” already uses that name. Merge the two instead to put '
              'their history together.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            )
          else
            Text(
              'The new name shows on every workout this exercise appears in.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm-exercise-rename'),
          onPressed: canSave ? () => Navigator.pop(context, name) : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// How two spellings are judged to be the same name. Matches the server's
/// rule, so a rename this screen accepts is not merged away behind the user.
String _nameKey(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

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
