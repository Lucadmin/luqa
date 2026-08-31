import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/network/network_failure.dart';
import 'package:luqa/features/gym/application/gym_sync_engine.dart';
import 'package:luqa/features/gym/data/gym_providers.dart';
import 'package:luqa/features/gym/data/gym_repository.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

final workoutControllerProvider =
    NotifierProvider.family<WorkoutController, WorkoutState, String>(
      (sessionId) => WorkoutController(sessionId),
    );

class WorkoutSetDraft {
  const WorkoutSetDraft({this.weight = '', this.reps = '', this.note = ''});

  final String weight;
  final String reps;
  final String note;

  bool get hasContent =>
      weight.trim().isNotEmpty ||
      reps.trim().isNotEmpty ||
      note.trim().isNotEmpty;

  WorkoutSetDraft copyWith({String? weight, String? reps, String? note}) =>
      WorkoutSetDraft(
        weight: weight ?? this.weight,
        reps: reps ?? this.reps,
        note: note ?? this.note,
      );
}

class WorkoutExerciseDraft {
  const WorkoutExerciseDraft({
    required this.exerciseId,
    required this.name,
    required this.notes,
    required this.sets,
  });

  final String? exerciseId;
  final String name;
  final String notes;
  final List<WorkoutSetDraft> sets;

  int get completedSetCount => sets.where((set) => set.hasContent).length;

  WorkoutExerciseDraft copyWith({
    String? exerciseId,
    String? name,
    String? notes,
    List<WorkoutSetDraft>? sets,
  }) => WorkoutExerciseDraft(
    exerciseId: exerciseId ?? this.exerciseId,
    name: name ?? this.name,
    notes: notes ?? this.notes,
    sets: sets ?? this.sets,
  );
}

class WorkoutDraft {
  const WorkoutDraft({
    required this.id,
    required this.dateKey,
    required this.locationId,
    required this.notes,
    required this.exercises,
  });

  factory WorkoutDraft.fromSession(GymSession session) => WorkoutDraft(
    id: session.id,
    dateKey: session.dateKey,
    locationId: session.locationId,
    notes: session.notes,
    exercises: [
      for (final exercise in session.exercises)
        WorkoutExerciseDraft(
          exerciseId: exercise.exerciseId,
          name: exercise.name,
          notes: exercise.notes,
          sets: exercise.sets.isEmpty
              ? const [WorkoutSetDraft()]
              : [
                  for (final set in exercise.sets)
                    WorkoutSetDraft(
                      weight: set.weight == null
                          ? ''
                          : formatGymNumber(set.weight!),
                      reps: set.reps?.toString() ?? '',
                      note: set.note ?? '',
                    ),
                ],
        ),
    ],
  );

  final String id;
  final String dateKey;
  final String? locationId;
  final String notes;
  final List<WorkoutExerciseDraft> exercises;

  WorkoutDraft copyWith({
    String? dateKey,
    Object? locationId = _unset,
    String? notes,
    List<WorkoutExerciseDraft>? exercises,
  }) => WorkoutDraft(
    id: id,
    dateKey: dateKey ?? this.dateKey,
    locationId: identical(locationId, _unset)
        ? this.locationId
        : locationId as String?,
    notes: notes ?? this.notes,
    exercises: exercises ?? this.exercises,
  );

  GymSessionWrite toWrite() => GymSessionWrite(
    dateKey: dateKey,
    locationId: locationId,
    notes: notes,
    exercises: [
      for (final exercise in exercises)
        GymExerciseWrite(
          exerciseId: exercise.exerciseId,
          name: exercise.name,
          notes: exercise.notes,
          sets: [
            for (final set in exercise.sets)
              GymSetWrite(
                weight: parseGymWeight(set.weight),
                reps: parseGymReps(set.reps),
                note: set.note.trim().isEmpty ? null : set.note.trim(),
              ),
          ],
        ),
    ],
  );
}

const _unset = Object();

class WorkoutState {
  const WorkoutState({
    required this.sessionId,
    this.draft,
    this.overview,
    this.activeExerciseIndex = 0,
    this.activeHistory,
    this.isLoading = true,
    this.isLoadingHistory = false,
    this.isSaving = false,
    this.pendingWrites = 0,
    this.revision = 0,
    this.persistedRevision = 0,
    this.loadError,
    this.saveError,
  });

  final String sessionId;
  final WorkoutDraft? draft;
  final GymOverview? overview;
  final int activeExerciseIndex;
  final GymExerciseHistory? activeHistory;
  final bool isLoading;

  final bool isLoadingHistory;

  /// True only while the draft is being written to the device, which is
  /// measured in milliseconds. Reaching the server is [pendingWrites].
  final bool isSaving;

  /// Changes recorded on this device that the server has not acknowledged.
  final int pendingWrites;

  final int revision;
  final int persistedRevision;
  final String? loadError;
  final String? saveError;

  /// Edits not yet written to the device. Distinct from [pendingWrites],
  /// which is about the server.
  bool get hasUnsavedChanges => revision > persistedRevision;

  /// Everything the user typed is on the phone and, eventually, on the server.
  bool get isFullySynced =>
      !hasUnsavedChanges && !isSaving && pendingWrites == 0;

  WorkoutExerciseDraft? get activeExercise {
    final exercises = draft?.exercises;
    if (exercises == null || exercises.isEmpty) return null;
    final index = activeExerciseIndex.clamp(0, exercises.length - 1);
    return exercises[index];
  }

  GymLocation? get location => overview?.locationById(draft?.locationId);

  WorkoutState copyWith({
    WorkoutDraft? draft,
    GymOverview? overview,
    int? activeExerciseIndex,
    Object? activeHistory = _unset,
    bool? isLoading,
    bool? isLoadingHistory,
    bool? isSaving,
    int? pendingWrites,
    int? revision,
    int? persistedRevision,
    Object? loadError = _unset,
    Object? saveError = _unset,
  }) => WorkoutState(
    sessionId: sessionId,
    draft: draft ?? this.draft,
    overview: overview ?? this.overview,
    activeExerciseIndex: activeExerciseIndex ?? this.activeExerciseIndex,
    activeHistory: identical(activeHistory, _unset)
        ? this.activeHistory
        : activeHistory as GymExerciseHistory?,
    isLoading: isLoading ?? this.isLoading,
    isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    isSaving: isSaving ?? this.isSaving,
    pendingWrites: pendingWrites ?? this.pendingWrites,
    revision: revision ?? this.revision,
    persistedRevision: persistedRevision ?? this.persistedRevision,
    loadError: identical(loadError, _unset)
        ? this.loadError
        : loadError as String?,
    saveError: identical(saveError, _unset)
        ? this.saveError
        : saveError as String?,
  );
}

class WorkoutController extends Notifier<WorkoutState> {
  WorkoutController(this._sessionId);

  late GymRepository _repository;
  final String _sessionId;
  Timer? _autosaveTimer;
  Future<void>? _saveFuture;
  int _loadGeneration = 0;
  int _historyGeneration = 0;

  static const autosaveDelay = Duration(milliseconds: 600);

  @override
  WorkoutState build() {
    _repository = ref.watch(gymRepositoryProvider);
    ref.onDispose(() => _autosaveTimer?.cancel());

    ref.listen(gymSyncEngineProvider, (previous, next) {
      if (!ref.mounted || next.pending == state.pendingWrites) return;
      state = state.copyWith(pendingWrites: next.pending);
    });

    Future<void>.microtask(load);
    return WorkoutState(sessionId: _sessionId);
  }

  Future<void> load() async {
    final generation = ++_loadGeneration;
    state = state.copyWith(isLoading: true, loadError: null);

    // The two are loaded independently on purpose. The workout is the screen;
    // the overview only supplies gym names and exercise suggestions, and a
    // phone that has never loaded one must still be able to log a session.
    final overview = _repository
        .loadOverview()
        .then<GymOverview?>((value) => value)
        .catchError((Object _) => null);

    try {
      final session = await _repository.loadSession(_sessionId);
      if (!ref.mounted || generation != _loadGeneration) return;
      state = state.copyWith(
        overview: await overview,
        draft: WorkoutDraft.fromSession(session),
        activeExerciseIndex: 0,
        activeHistory: null,
        isLoading: false,
        loadError: null,
        saveError: null,
      );
      await _loadActiveHistory();
    } on Object catch (error) {
      if (!ref.mounted || generation != _loadGeneration) return;
      state = state.copyWith(
        overview: await overview,
        isLoading: false,
        loadError: describeNetworkFailure(
          error,
          whileDoing: 'opening the workout',
        ),
      );
    }
  }

  void selectExercise(int index) {
    final exercises = state.draft?.exercises ?? const <WorkoutExerciseDraft>[];
    if (index < 0 ||
        index >= exercises.length ||
        index == state.activeExerciseIndex) {
      return;
    }
    state = state.copyWith(
      activeExerciseIndex: index,
      activeHistory: null,
      isLoadingHistory: true,
    );
    unawaited(_loadActiveHistory());
  }

  void changeLocation(String? locationId) {
    final draft = state.draft;
    if (draft == null || draft.locationId == locationId) return;
    _edit(draft.copyWith(locationId: locationId));
    state = state.copyWith(activeHistory: null, isLoadingHistory: true);
    unawaited(_loadActiveHistory());
  }

  void addExercise({GymExercise? exercise, required String name}) {
    final draft = state.draft;
    if (draft == null) return;
    if (exercise != null) {
      final existing = draft.exercises.indexWhere(
        (item) => item.exerciseId == exercise.id,
      );
      if (existing >= 0) {
        selectExercise(existing);
        return;
      }
    }
    final exercises = [
      ...draft.exercises,
      WorkoutExerciseDraft(
        exerciseId: exercise?.id,
        name: exercise?.name ?? name.trim(),
        notes: exercise?.notes ?? '',
        sets: const [WorkoutSetDraft()],
      ),
    ];
    _edit(draft.copyWith(exercises: exercises));
    state = state.copyWith(
      activeExerciseIndex: exercises.length - 1,
      activeHistory: null,
      isLoadingHistory: exercise != null,
    );
    if (exercise != null) unawaited(_loadActiveHistory());
  }

  void removeActiveExercise() {
    final draft = state.draft;
    if (draft == null || draft.exercises.isEmpty) return;
    final exercises = [...draft.exercises]..removeAt(state.activeExerciseIndex);
    final nextIndex = exercises.isEmpty
        ? 0
        : state.activeExerciseIndex.clamp(0, exercises.length - 1);
    _edit(draft.copyWith(exercises: exercises));
    state = state.copyWith(
      activeExerciseIndex: nextIndex,
      activeHistory: null,
      isLoadingHistory: exercises.isNotEmpty,
    );
    if (exercises.isNotEmpty) unawaited(_loadActiveHistory());
  }

  void addSet() {
    final active = state.activeExercise;
    if (active == null) return;
    var carriedWeight = '';
    for (final set in active.sets.reversed) {
      if (set.weight.trim().isNotEmpty) {
        carriedWeight = set.weight;
        break;
      }
    }
    _replaceActive(
      active.copyWith(
        sets: [
          ...active.sets,
          WorkoutSetDraft(weight: carriedWeight),
        ],
      ),
    );
  }

  void updateSet(int index, {String? weight, String? reps, String? note}) {
    final active = state.activeExercise;
    if (active == null || index < 0 || index >= active.sets.length) return;
    final sets = [...active.sets];
    sets[index] = sets[index].copyWith(weight: weight, reps: reps, note: note);
    _replaceActive(active.copyWith(sets: sets));
  }

  void removeSet(int index) {
    final active = state.activeExercise;
    if (active == null || active.sets.length <= 1) return;
    final sets = [...active.sets]..removeAt(index);
    _replaceActive(active.copyWith(sets: sets));
  }

  void updateExerciseNotes(String notes) {
    final active = state.activeExercise;
    if (active != null) _replaceActive(active.copyWith(notes: notes));
  }

  void updateWorkoutNotes(String notes) {
    final draft = state.draft;
    if (draft != null) _edit(draft.copyWith(notes: notes));
  }

  void _replaceActive(WorkoutExerciseDraft exercise) {
    final draft = state.draft;
    if (draft == null) return;
    final exercises = [...draft.exercises];
    exercises[state.activeExerciseIndex] = exercise;
    _edit(draft.copyWith(exercises: exercises));
  }

  void _edit(WorkoutDraft draft) {
    state = state.copyWith(
      draft: draft,
      revision: state.revision + 1,
      saveError: null,
    );
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(autosaveDelay, () => unawaited(flush()));
  }

  Future<void> _loadActiveHistory() async {
    final exercise = state.activeExercise;
    final draft = state.draft;
    final exerciseId = exercise?.exerciseId;
    if (exerciseId == null || draft == null) {
      if (ref.mounted) {
        state = state.copyWith(activeHistory: null, isLoadingHistory: false);
      }
      return;
    }
    final generation = ++_historyGeneration;
    state = state.copyWith(isLoadingHistory: true);
    try {
      final history = await _repository.loadExerciseHistory(
        exerciseId,
        locationId: draft.locationId,
        beforeSessionId: draft.id,
      );
      if (!ref.mounted || generation != _historyGeneration) return;
      if (state.activeExercise?.exerciseId != exerciseId) return;
      state = state.copyWith(activeHistory: history, isLoadingHistory: false);
    } on Object {
      if (!ref.mounted || generation != _historyGeneration) return;
      state = state.copyWith(activeHistory: null, isLoadingHistory: false);
    }
  }

  Future<void> flush() {
    _autosaveTimer?.cancel();
    final existing = _saveFuture;
    if (existing != null) return existing;
    final future = _drainSaves();
    _saveFuture = future;
    return future.whenComplete(() {
      if (identical(_saveFuture, future)) _saveFuture = null;
    });
  }

  Future<void> retrySave() => flush();

  Future<void> refreshOverview() async {
    try {
      final overview = await _repository.loadOverview();
      if (ref.mounted) state = state.copyWith(overview: overview);
    } on Object {
      // The workout draft remains fully usable with the gyms/exercises already
      // loaded. The next explicit retry or screen open will refresh them.
    }
  }

  Future<void> _drainSaves() async {
    while (ref.mounted && state.hasUnsavedChanges) {
      final draft = state.draft;
      if (draft == null) return;
      final revision = state.revision;
      state = state.copyWith(isSaving: true, saveError: null);
      try {
        final saved = await _repository.saveSession(draft.id, draft.toWrite());
        if (!ref.mounted) return;
        final local = state.draft;
        state = state.copyWith(
          draft: local == null ? null : _mergeExerciseIds(local, saved),
          persistedRevision: revision,
          isSaving: false,
          saveError: null,
        );
      } on Object catch (error) {
        if (!ref.mounted) return;
        state = state.copyWith(
          isSaving: false,
          saveError: describeNetworkFailure(
            error,
            whileDoing: 'saving the workout',
          ),
        );
        return;
      }
    }
    if (ref.mounted && state.isSaving) {
      state = state.copyWith(isSaving: false);
    }
  }
}

WorkoutDraft _mergeExerciseIds(WorkoutDraft local, GymSession saved) {
  final exercises = <WorkoutExerciseDraft>[];
  for (var index = 0; index < local.exercises.length; index += 1) {
    final exercise = local.exercises[index];
    if (exercise.exerciseId != null) {
      exercises.add(exercise);
      continue;
    }
    GymSessionExercise? match;
    if (index < saved.exercises.length &&
        saved.exercises[index].name.toLowerCase() ==
            exercise.name.toLowerCase()) {
      match = saved.exercises[index];
    } else {
      for (final candidate in saved.exercises) {
        if (candidate.name.toLowerCase() == exercise.name.toLowerCase()) {
          match = candidate;
          break;
        }
      }
    }
    exercises.add(
      match == null
          ? exercise
          : exercise.copyWith(exerciseId: match.exerciseId),
    );
  }
  return local.copyWith(exercises: exercises);
}
