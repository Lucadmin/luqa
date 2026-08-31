import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

class ExerciseSelection {
  const ExerciseSelection({required this.exercise, required this.name});

  final GymExercise? exercise;
  final String name;
}

Future<ExerciseSelection?> showExercisePickerSheet(
  BuildContext context, {
  required GymOverview overview,
  required String? locationId,
}) {
  return showModalBottomSheet<ExerciseSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.88,
      child: _ExercisePickerSheet(overview: overview, locationId: locationId),
    ),
  );
}

class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet({
    required this.overview,
    required this.locationId,
  });

  final GymOverview overview;
  final String? locationId;

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  final _search = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _search.addListener(_redraw);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _search
      ..removeListener(_redraw)
      ..dispose();
    _focus.dispose();
    super.dispose();
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  List<GymExercise> get _results {
    final query = _search.text.trim().toLowerCase();
    final results = widget.overview.exercises
        .where(
          (exercise) =>
              !exercise.archived &&
              (query.isEmpty || exercise.name.toLowerCase().contains(query)),
        )
        .toList(growable: false);
    results.sort((left, right) {
      final leftReference = widget.overview.referenceFor(
        left.id,
        widget.locationId,
      );
      final rightReference = widget.overview.referenceFor(
        right.id,
        widget.locationId,
      );
      if (leftReference != null && rightReference == null) return -1;
      if (leftReference == null && rightReference != null) return 1;
      final leftDate = leftReference?.dateKey ?? left.lastPerformed ?? '';
      final rightDate = rightReference?.dateKey ?? right.lastPerformed ?? '';
      final byDate = rightDate.compareTo(leftDate);
      return byDate != 0 ? byDate : left.name.compareTo(right.name);
    });
    return results;
  }

  bool get _canCreate {
    final query = _search.text.trim();
    if (query.isEmpty) return false;
    return widget.overview.exercises.every(
      (exercise) => exercise.name.trim().toLowerCase() != query.toLowerCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        LuqaSpacing.lg,
        LuqaSpacing.sm,
        LuqaSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + LuqaSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: LuqaSpacing.sm),
          Text('Add exercise', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: LuqaSpacing.lg),
          TextField(
            controller: _search,
            focusNode: _focus,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search your exercises',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: LuqaSpacing.lg),
          Expanded(
            child: results.isEmpty && !_canCreate
                ? Center(
                    child: Text(
                      'Start typing to add your first exercise.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: results.length + (_canCreate ? 1 : 0),
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      if (index == results.length) {
                        final name = _search.text.trim();
                        return _ExerciseRow(
                          name: 'Add “$name”',
                          detail: 'New exercise',
                          onTap: () => Navigator.pop(
                            context,
                            ExerciseSelection(exercise: null, name: name),
                          ),
                        );
                      }
                      final exercise = results[index];
                      final reference = widget.overview.referenceFor(
                        exercise.id,
                        widget.locationId,
                      );
                      final hasOtherGymHistory =
                          reference == null &&
                          widget.overview.recentReferences.any(
                            (item) => item.exerciseId == exercise.id,
                          );
                      return _ExerciseRow(
                        name: exercise.name,
                        detail: reference?.raw.isNotEmpty == true
                            ? 'Last here · ${reference!.raw}'
                            : hasOtherGymHistory
                            ? 'History at another gym'
                            : 'No history here yet',
                        onTap: () => Navigator.pop(
                          context,
                          ExerciseSelection(
                            exercise: exercise,
                            name: exercise.name,
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

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.name,
    required this.detail,
    required this.onTap,
  });

  final String name;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: LuqaSpacing.xs),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_rounded),
          ],
        ),
      ),
    );
  }
}
