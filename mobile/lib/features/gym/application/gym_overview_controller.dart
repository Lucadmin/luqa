import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/network/network_failure.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/gym/application/gym_sync_engine.dart';
import 'package:luqa/features/gym/data/gym_providers.dart';
import 'package:luqa/features/gym/data/gym_repository.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

final gymNowProvider = Provider<DateTime>((ref) => DateTime.now());

final gymOverviewControllerProvider =
    NotifierProvider<GymOverviewController, GymOverviewState>(
      GymOverviewController.new,
    );

class GymOverviewState {
  const GymOverviewState({
    this.overview,
    this.isLoading = true,
    this.isRefreshing = false,
    this.pendingWrites = 0,
    this.discarded = const [],
    this.error,
  });

  final GymOverview? overview;
  final bool isLoading;
  final bool isRefreshing;

  /// Workouts and gyms recorded here that the server has not acknowledged yet.
  /// Nothing waits on them; the count exists so the screen can say so quietly.
  final int pendingWrites;

  /// Writes the server refused outright, which this device has given up on.
  /// The user has to be told; there is nothing to retry.
  final List<DiscardedWrite> discarded;

  final String? error;

  GymSession? currentSession(DateTime now) {
    final today = gymDateKey(now);
    final sessions = overview?.sessions ?? const <GymSession>[];
    for (final session in sessions) {
      if (session.dateKey == today) return session;
    }
    return null;
  }

  GymOverviewState copyWith({
    GymOverview? overview,
    bool? isLoading,
    bool? isRefreshing,
    int? pendingWrites,
    List<DiscardedWrite>? discarded,
    String? error,
    bool clearError = false,
  }) => GymOverviewState(
    overview: overview ?? this.overview,
    isLoading: isLoading ?? this.isLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    pendingWrites: pendingWrites ?? this.pendingWrites,
    discarded: discarded ?? this.discarded,
    error: clearError ? null : error ?? this.error,
  );
}

class GymOverviewController extends Notifier<GymOverviewState> {
  late GymRepository _repository;
  int _generation = 0;

  @override
  GymOverviewState build() {
    _repository = ref.watch(gymRepositoryProvider);

    // Local work is already on screen; this is about what came back. Once a
    // round of the queue reaches the server, its rows are canonical there, so
    // pull them down and drop the local overlay.
    ref.listen(gymSyncEngineProvider, (previous, next) {
      if (!ref.mounted) return;
      if (next.pending != state.pendingWrites ||
          next.discarded != state.discarded) {
        state = state.copyWith(
          pendingWrites: next.pending,
          discarded: next.discarded,
        );
      }
      if (previous != null && next.rounds > previous.rounds) {
        unawaited(load(refresh: true));
      }
    });

    Future<void>.microtask(() => load(allowCache: true));
    return const GymOverviewState();
  }

  Future<void> load({bool refresh = false, bool allowCache = false}) async {
    final generation = ++_generation;
    state = state.copyWith(
      isLoading: state.overview == null,
      isRefreshing: refresh && state.overview != null,
      clearError: true,
    );

    // The device's own rows. This is the answer, not a placeholder for one.
    try {
      final overview = await _repository.loadOverview();
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        overview: overview,
        isLoading: false,
        clearError: true,
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: describeNetworkFailure(error, whileDoing: 'loading gym data'),
      );
      return;
    }

    // Catching up happens behind the screen. Not reaching the server only
    // means nothing new arrived, which is not something to interrupt a
    // workout for.
    final local = ref.read(localFirstGymRepositoryProvider);
    if (local == null) {
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(isRefreshing: false);
      }
      return;
    }
    try {
      await local.pull();
      if (!ref.mounted || generation != _generation) return;
      final overview = await _repository.loadOverview();
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        overview: overview,
        isRefreshing: false,
        clearError: true,
      );
    } on Object {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(isRefreshing: false);
    }
  }

  /// The user has read the notice about a workout that could not be saved.
  Future<void> acknowledgeDiscarded() =>
      ref.read(gymSyncEngineProvider.notifier).acknowledgeDiscarded();

  Future<void> refresh() async {
    // One gesture, one meaning: catch up with the server. Sending first means
    // the reload that follows cannot overwrite local work with an older copy.
    await ref.read(gymSyncEngineProvider.notifier).sync();
    if (!ref.mounted) return;
    await load(refresh: true);
  }

  /// Starts a workout and returns it immediately. The server hears about it
  /// when it can; the user is already on the workout screen by then.
  Future<GymSession?> startWorkout({String? locationId}) async {
    state = state.copyWith(clearError: true);
    try {
      final session = await _repository.createSession(
        dateKey: gymDateKey(ref.read(gymNowProvider)),
        locationId: locationId,
      );
      if (!ref.mounted) return session;
      final current = state.overview;
      state = state.copyWith(
        overview: current?.copyWith(
          sessions: [
            session,
            ...current.sessions.where((item) => item.id != session.id),
          ],
          totalSessions: current.totalSessions + 1,
        ),
        clearError: true,
      );
      return session;
    } on Object catch (error) {
      // Only a failure to record it on the device reaches here.
      if (!ref.mounted) return null;
      state = state.copyWith(
        error: describeNetworkFailure(error, whileDoing: 'starting a workout'),
      );
      return null;
    }
  }

  /// Throws away a workout, including one started minutes ago. It leaves the
  /// screen at once; the server is told when it can be.
  Future<bool> deleteSession(String id) async {
    state = state.copyWith(clearError: true);
    final overview = state.overview;
    // Off the screen straight away, and put back if the device itself refuses
    // the write — the only failure that reaches here.
    if (overview != null) {
      final remaining = overview.sessions
          .where((session) => session.id != id)
          .toList(growable: false);
      state = state.copyWith(
        overview: overview.copyWith(
          sessions: remaining,
          totalSessions: overview.totalSessions -
              (overview.sessions.length - remaining.length),
        ),
      );
    }

    try {
      await _repository.deleteSession(id);
      return true;
    } on Object catch (error) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        overview: overview,
        error: describeNetworkFailure(
          error,
          whileDoing: 'deleting the workout',
        ),
      );
      return false;
    }
  }

  /// Renames an exercise everywhere it appears.
  Future<bool> renameExercise({
    required String id,
    required String name,
  }) async {
    state = state.copyWith(clearError: true);
    try {
      final update = await _repository.updateExercise(id: id, name: name);
      if (!ref.mounted) return true;
      final overview = state.overview;
      if (overview != null) {
        state = state.copyWith(
          overview: _withExercise(overview, update.exercise),
          clearError: true,
        );
      }
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          error: describeNetworkFailure(
            error,
            whileDoing: 'renaming the exercise',
          ),
        );
      }
      return false;
    }
  }

  /// Takes an exercise out of the library. One that workouts still reference
  /// is archived rather than erased; the result says which happened so the
  /// user can be told the truth about their history.
  Future<GymExerciseRemoval?> deleteExercise(String id) async {
    state = state.copyWith(clearError: true);
    try {
      final removal = await _repository.deleteExercise(id);
      if (!ref.mounted) return removal;
      final overview = state.overview;
      if (overview != null) {
        state = state.copyWith(
          overview: overview.copyWith(
            exercises: overview.exercises
                .where((exercise) => exercise.id != id)
                .toList(growable: false),
          ),
          clearError: true,
        );
      }
      return removal;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          error: describeNetworkFailure(
            error,
            whileDoing: 'removing the exercise',
          ),
        );
      }
      return null;
    }
  }

  GymOverview _withExercise(GymOverview overview, GymExercise exercise) =>
      overview.copyWith(
        exercises: [
          for (final item in overview.exercises)
            if (item.id == exercise.id) exercise else item,
        ],
        sessions: [
          for (final session in overview.sessions)
            GymSession(
              id: session.id,
              dateKey: session.dateKey,
              locationId: session.locationId,
              notes: session.notes,
              createdAt: session.createdAt,
              exercises: [
                for (final entry in session.exercises)
                  if (entry.exerciseId == exercise.id)
                    GymSessionExercise(
                      id: entry.id,
                      exerciseId: entry.exerciseId,
                      name: exercise.name,
                      order: entry.order,
                      raw: entry.raw,
                      notes: entry.notes,
                      sets: entry.sets,
                    )
                  else
                    entry,
              ],
            ),
        ],
      );

  Future<bool> createLocation({
    required String name,
    required String code,
    required int colorValue,
  }) async {
    try {
      final location = await _repository.createLocation(
        name: name,
        code: code,
        colorValue: colorValue,
      );
      if (!ref.mounted) return true;
      final overview = state.overview;
      if (overview != null) {
        // Adding a gym the device already knows returns the existing row, so
        // appending blindly would show it twice.
        final known = overview.locations.any((item) => item.id == location.id);
        state = state.copyWith(
          overview: overview.copyWith(
            locations: known
                ? overview.locations
                : [...overview.locations, location],
          ),
          clearError: true,
        );
      }
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          error: describeNetworkFailure(error, whileDoing: 'adding the gym'),
        );
      }
      return false;
    }
  }

  Future<bool> updateLocation({
    required String id,
    String? name,
    String? code,
    int? colorValue,
    bool? archived,
  }) async {
    try {
      final location = await _repository.updateLocation(
        id: id,
        name: name,
        code: code,
        colorValue: colorValue,
        archived: archived,
      );
      if (!ref.mounted) return true;
      final overview = state.overview;
      if (overview != null) {
        state = state.copyWith(
          overview: overview.copyWith(
            locations: [
              for (final item in overview.locations)
                if (item.id == id) location else item,
            ],
          ),
          clearError: true,
        );
      }
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          error: describeNetworkFailure(error, whileDoing: 'updating the gym'),
        );
      }
      return false;
    }
  }

  /// Exercise merges are intentionally online and ordered after the outbox.
  /// Otherwise an older queued workout could upload the source id again just
  /// after the server removed it.
  Future<bool> mergeExercise({
    required String sourceExerciseId,
    required String targetExerciseId,
  }) async {
    state = state.copyWith(clearError: true);
    await ref.read(gymSyncEngineProvider.notifier).sync();
    if (!ref.mounted) return false;
    if (ref.read(gymSyncEngineProvider).pending > 0) {
      state = state.copyWith(
        error:
            'Connect first so pending workout changes can sync before merging.',
      );
      return false;
    }

    try {
      final target = await _repository.mergeExercise(
        sourceExerciseId: sourceExerciseId,
        targetExerciseId: targetExerciseId,
      );
      if (!ref.mounted) return true;
      final overview = state.overview;
      if (overview != null) {
        state = state.copyWith(
          overview: applyExerciseMerge(
            overview,
            sourceExerciseId: sourceExerciseId,
            target: target,
          ),
          clearError: true,
        );
      }
      await load(refresh: true);
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          error: describeNetworkFailure(
            error,
            whileDoing: 'merging the exercises',
          ),
        );
      }
      return false;
    }
  }
}
