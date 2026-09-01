import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/gym/application/gym_overview_controller.dart';
import 'package:luqa/features/gym/application/workout_controller.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';
import 'package:luqa/features/gym/presentation/exercise_picker_sheet.dart';
import 'package:luqa/features/gym/presentation/gym_formatters.dart';
import 'package:luqa/features/gym/presentation/gym_picker_sheet.dart';
import 'package:luqa/features/gym/presentation/widgets/progress_sparkline.dart';
import 'package:luqa/features/gym/presentation/widgets/workout_set_row.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen>
    with WidgetsBindingObserver {
  bool _showExerciseNotes = false;

  WorkoutController get _controller =>
      ref.read(workoutControllerProvider(widget.sessionId).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_controller.flush());
    }
  }

  Future<void> _pickGym(WorkoutState state) async {
    final overview = state.overview;
    if (overview == null) return;
    final result = await showGymPickerSheet(
      context,
      locations: overview.locations,
      selectedId: state.draft?.locationId,
    );
    if (result == null || !mounted) return;
    if (result.manage) {
      await context.push('/gym/locations');
      await _controller.refreshOverview();
      return;
    }
    _controller.changeLocation(result.locationId);
  }

  Future<void> _addExercise(WorkoutState state) async {
    final overview = state.overview;
    if (overview == null) return;
    final selection = await showExercisePickerSheet(
      context,
      overview: overview,
      locationId: state.draft?.locationId,
    );
    if (selection == null || !mounted) return;
    _controller.addExercise(exercise: selection.exercise, name: selection.name);
    unawaited(HapticFeedback.selectionClick());
  }

  /// Throws the whole workout away — the one being logged right now included.
  ///
  /// The autosave is stopped before anything else, or the flush that runs as
  /// this screen closes would queue a save for a workout that is already
  /// gone.
  Future<void> _deleteWorkout(WorkoutState state) async {
    final draft = state.draft;
    final logged = draft?.exercises.length ?? 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this workout?'),
        content: Text(
          logged == 0
              ? 'Nothing has been logged in it yet.'
              : 'Its $logged ${logged == 1 ? 'exercise' : 'exercises'} and '
                    'every set in them go with it. Your exercise list is not '
                    'touched. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-workout-delete'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _controller.abandon();
    final deleted = await ref
        .read(gymOverviewControllerProvider.notifier)
        .deleteSession(widget.sessionId);
    if (!mounted) return;
    if (!deleted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              ref.read(gymOverviewControllerProvider).error ??
                  'Could not delete the workout.',
            ),
          ),
        );
      return;
    }
    if (context.canPop()) context.pop();
  }

  void _openHistory(WorkoutState state) {
    final exercise = state.activeExercise;
    if (exercise?.exerciseId == null) return;
    final locationId = state.draft?.locationId;
    final query = locationId == null
        ? ''
        : '?locationId=${Uri.encodeQueryComponent(locationId)}';
    context.push('/gym/exercises/${exercise!.exerciseId}/history$query');
  }

  @override
  Widget build(BuildContext context) {
    final provider = workoutControllerProvider(widget.sessionId);
    final state = ref.watch(provider);

    ref.listen(provider, (previous, next) {
      final error = next.saveError;
      if (error == null || error == previous?.saveError) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _controller.retrySave,
            ),
          ),
        );
    });

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        final controller = _controller;
        final overview = ref.read(gymOverviewControllerProvider.notifier);
        unawaited(controller.flush().whenComplete(overview.refresh));
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Workout'),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Workout options',
              onSelected: (value) {
                if (value == 'remove') _controller.removeActiveExercise();
                if (value == 'notes') {
                  setState(() => _showExerciseNotes = true);
                }
                if (value == 'delete') unawaited(_deleteWorkout(state));
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'notes',
                  child: Text('Exercise note'),
                ),
                if (state.activeExercise != null)
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove exercise'),
                  ),
                if (state.draft != null)
                  const PopupMenuItem(
                    key: ValueKey('delete-workout'),
                    value: 'delete',
                    child: Text('Delete workout'),
                  ),
              ],
            ),
          ],
        ),
        body: state.isLoading
            ? const _WorkoutSkeleton()
            : state.loadError != null || state.draft == null
            ? _WorkoutLoadError(
                message: state.loadError ?? 'Workout not found.',
                onRetry: _controller.load,
              )
            : Column(
                children: [
                  _WorkoutContextRow(
                    state: state,
                    onPickGym: () => _pickGym(state),
                    onRetry: _controller.retrySave,
                  ),
                  const Divider(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final expanded =
                            constraints.maxWidth >= 720 &&
                            state.draft!.exercises.length > 1;
                        if (!expanded) {
                          return _PhoneWorkoutBody(
                            state: state,
                            showExerciseNotes: _showExerciseNotes,
                            onShowNotes: () =>
                                setState(() => _showExerciseNotes = true),
                            onOpenHistory: () => _openHistory(state),
                            controller: _controller,
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _FocusedExerciseScroll(
                                state: state,
                                showExerciseNotes: _showExerciseNotes,
                                onShowNotes: () =>
                                    setState(() => _showExerciseNotes = true),
                                onOpenHistory: () => _openHistory(state),
                                controller: _controller,
                              ),
                            ),
                            const VerticalDivider(),
                            SizedBox(
                              width: 300,
                              child: _ExerciseQueue(
                                state: state,
                                controller: _controller,
                                embedded: false,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(
                      LuqaSpacing.lg,
                      LuqaSpacing.sm,
                      LuqaSpacing.lg,
                      LuqaSpacing.sm,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () => _addExercise(state),
                        child: const Text('Add exercise'),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _WorkoutContextRow extends StatelessWidget {
  const _WorkoutContextRow({
    required this.state,
    required this.onPickGym,
    required this.onRetry,
  });

  final WorkoutState state;
  final VoidCallback onPickGym;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = state.location;
    // "Saved" means saved on this phone, which is the promise the app can
    // actually keep in a basement. Reaching the server is reported separately
    // and never as a failure the user has to act on.
    final status = state.saveError != null
        ? 'Save failed'
        : state.hasUnsavedChanges || state.isSaving
        ? 'Saving…'
        : state.pendingWrites > 0
        ? 'Saved · syncing'
        : 'Saved';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LuqaSpacing.lg),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onPickGym,
                borderRadius: BorderRadius.circular(LuqaRadii.compact),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: location == null
                            ? theme.colorScheme.outline
                            : Color(location.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: LuqaSpacing.sm),
                    Flexible(
                      child: Text(
                        location?.name ?? 'Choose gym',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: LuqaSpacing.xs),
                    const Icon(Icons.expand_more_rounded, size: 20),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: state.saveError == null ? null : onRetry,
              child: Text(
                status,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: state.saveError == null
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneWorkoutBody extends StatelessWidget {
  const _PhoneWorkoutBody({
    required this.state,
    required this.showExerciseNotes,
    required this.onShowNotes,
    required this.onOpenHistory,
    required this.controller,
  });

  final WorkoutState state;
  final bool showExerciseNotes;
  final VoidCallback onShowNotes;
  final VoidCallback onOpenHistory;
  final WorkoutController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        LuqaSpacing.lg,
        LuqaSpacing.xxl,
        LuqaSpacing.lg,
        LuqaSpacing.xl,
      ),
      children: [
        ..._focusedExerciseChildren(
          context,
          state: state,
          showExerciseNotes: showExerciseNotes,
          onShowNotes: onShowNotes,
          onOpenHistory: onOpenHistory,
          controller: controller,
        ),
        if (state.draft!.exercises.length > 1) ...[
          const SizedBox(height: LuqaSpacing.section),
          const Divider(),
          _ExerciseQueue(state: state, controller: controller, embedded: true),
        ],
      ],
    );
  }
}

class _FocusedExerciseScroll extends StatelessWidget {
  const _FocusedExerciseScroll({
    required this.state,
    required this.showExerciseNotes,
    required this.onShowNotes,
    required this.onOpenHistory,
    required this.controller,
  });

  final WorkoutState state;
  final bool showExerciseNotes;
  final VoidCallback onShowNotes;
  final VoidCallback onOpenHistory;
  final WorkoutController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        LuqaSpacing.xl,
        LuqaSpacing.xxl,
        LuqaSpacing.xl,
        LuqaSpacing.xl,
      ),
      children: _focusedExerciseChildren(
        context,
        state: state,
        showExerciseNotes: showExerciseNotes,
        onShowNotes: onShowNotes,
        onOpenHistory: onOpenHistory,
        controller: controller,
      ),
    );
  }
}

List<Widget> _focusedExerciseChildren(
  BuildContext context, {
  required WorkoutState state,
  required bool showExerciseNotes,
  required VoidCallback onShowNotes,
  required VoidCallback onOpenHistory,
  required WorkoutController controller,
}) {
  final exercise = state.activeExercise;
  if (exercise == null) {
    return [
      const SizedBox(height: LuqaSpacing.section),
      Text(
        'Ready when you are',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: LuqaSpacing.md),
      Text(
        'Add whatever exercise you choose next. Nothing else is required.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ];
  }

  final lastPoint = state.activeHistory?.lastPoint;
  final referenceSets = lastPoint?.sets ?? const <GymSet>[];
  final summary = gymReferenceSummary(lastPoint);
  final hasOtherGymHistory =
      state.activeHistory?.points.isEmpty != false &&
      exercise.exerciseId != null &&
      state.overview?.recentReferences.any(
            (reference) =>
                reference.exerciseId == exercise.exerciseId &&
                reference.locationId != state.draft?.locationId,
          ) ==
          true;

  return [
    Text(
      exercise.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.headlineLarge,
    ),
    const SizedBox(height: LuqaSpacing.xl),
    if (state.isLoadingHistory)
      const SizedBox(
        height: 72,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      )
    else
      ProgressSparkline(points: state.activeHistory?.points ?? const []),
    const SizedBox(height: LuqaSpacing.md),
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            summary.isNotEmpty
                ? 'Last time · $summary'
                : hasOtherGymHistory
                ? 'No history at this gym · available elsewhere'
                : 'No history at this gym',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (exercise.exerciseId != null)
          TextButton(onPressed: onOpenHistory, child: const Text('History')),
      ],
    ),
    const SizedBox(height: LuqaSpacing.xl),
    Padding(
      padding: const EdgeInsets.only(left: 32, right: 48),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'kg',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: LuqaSpacing.sm),
          Expanded(
            child: Text(
              'reps',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: LuqaSpacing.xs),
    for (var index = 0; index < exercise.sets.length; index += 1)
      WorkoutSetRow(
        key: ValueKey('${exercise.exerciseId ?? exercise.name}-$index'),
        index: index,
        set: exercise.sets[index],
        reference: index < referenceSets.length ? referenceSets[index] : null,
        canRemove: exercise.sets.length > 1,
        onChanged: ({weight, reps}) =>
            controller.updateSet(index, weight: weight, reps: reps),
        onRemove: () => controller.removeSet(index),
      ),
    SizedBox(
      height: 48,
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: controller.addSet,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add set'),
        ),
      ),
    ),
    if (showExerciseNotes || exercise.notes.isNotEmpty) ...[
      const SizedBox(height: LuqaSpacing.lg),
      _ExerciseNotesField(
        key: ValueKey('notes-${exercise.exerciseId ?? exercise.name}'),
        notes: exercise.notes,
        onChanged: controller.updateExerciseNotes,
      ),
    ] else
      SizedBox(
        height: 48,
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onShowNotes,
            child: const Text('Add note'),
          ),
        ),
      ),
  ];
}

class _ExerciseQueue extends StatelessWidget {
  const _ExerciseQueue({
    required this.state,
    required this.controller,
    required this.embedded,
  });

  final WorkoutState state;
  final WorkoutController controller;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final exercises = state.draft!.exercises;
    if (exercises.length <= 1) return const SizedBox.shrink();
    final others = <({int index, WorkoutExerciseDraft exercise})>[
      for (var index = 0; index < exercises.length; index += 1)
        if (index != state.activeExerciseIndex)
          (index: index, exercise: exercises[index]),
    ];
    Widget row(({int index, WorkoutExerciseDraft exercise}) item) {
      final index = item.index;
      final exercise = item.exercise;
      final reference = exercise.exerciseId == null
          ? null
          : state.overview?.referenceFor(
              exercise.exerciseId!,
              state.draft!.locationId,
            );
      return InkWell(
        onTap: () => controller.selectExercise(index),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: LuqaSpacing.xs),
                    Text(
                      exercise.completedSetCount > 0
                          ? '${exercise.completedSetCount} sets'
                          : reference?.raw.isNotEmpty == true
                          ? 'Last here · ${reference!.raw}'
                          : 'Not started',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      );
    }

    if (embedded) {
      return Column(
        children: [
          for (var index = 0; index < others.length; index += 1) ...[
            row(others[index]),
            if (index < others.length - 1) const Divider(),
          ],
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: LuqaSpacing.lg,
        vertical: LuqaSpacing.lg,
      ),
      itemCount: others.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) => row(others[index]),
    );
  }
}

class _ExerciseNotesField extends StatefulWidget {
  const _ExerciseNotesField({
    required this.notes,
    required this.onChanged,
    super.key,
  });

  final String notes;
  final ValueChanged<String> onChanged;

  @override
  State<_ExerciseNotesField> createState() => _ExerciseNotesFieldState();
}

class _ExerciseNotesFieldState extends State<_ExerciseNotesField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.notes,
  );

  @override
  void didUpdateWidget(covariant _ExerciseNotesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text == widget.notes) return;
    _controller.value = TextEditingValue(
      text: widget.notes,
      selection: TextSelection.collapsed(offset: widget.notes.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLength: 2000,
      minLines: 1,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Exercise note',
        hintText: 'Seat, grip, cue…',
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _WorkoutSkeleton extends StatelessWidget {
  const _WorkoutSkeleton();

  @override
  Widget build(BuildContext context) {
    final raised = LuqaPalette.of(context).raised;
    return Padding(
      padding: const EdgeInsets.all(LuqaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 52, color: raised),
          const SizedBox(height: LuqaSpacing.xxl),
          Container(width: 220, height: 32, color: raised),
          const SizedBox(height: LuqaSpacing.xl),
          Container(height: 72, color: raised),
          const SizedBox(height: LuqaSpacing.xl),
          Container(height: 56, color: raised),
          const SizedBox(height: LuqaSpacing.sm),
          Container(height: 56, color: raised),
        ],
      ),
    );
  }
}

class _WorkoutLoadError extends StatelessWidget {
  const _WorkoutLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LuqaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: LuqaSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
