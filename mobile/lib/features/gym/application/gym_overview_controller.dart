import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/network/network_failure.dart';
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
    this.error,
  });

  final GymOverview? overview;
  final bool isLoading;
  final bool isRefreshing;

  /// Workouts and gyms recorded here that the server has not acknowledged yet.
  /// Nothing waits on them; the count exists so the screen can say so quietly.
  final int pendingWrites;

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
    String? error,
    bool clearError = false,
  }) => GymOverviewState(
    overview: overview ?? this.overview,
    isLoading: isLoading ?? this.isLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    pendingWrites: pendingWrites ?? this.pendingWrites,
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
      if (next.pending != state.pendingWrites) {
        state = state.copyWith(pendingWrites: next.pending);
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

    if (allowCache) {
      // Painting the phone's copy first is what makes opening the gym screen
      // in a basement feel like opening a local app.
      try {
        final cached = await ref
            .read(localFirstGymRepositoryProvider)
            ?.cachedOverview();
        if (!ref.mounted || generation != _generation) return;
        if (cached != null) {
          state = state.copyWith(
            overview: cached,
            isLoading: false,
            isRefreshing: true,
          );
        }
      } on Object {
        // A broken read cache must never block a fresh load.
      }
    }

    try {
      final overview = await _repository.loadOverview();
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        overview: overview,
        isLoading: false,
        isRefreshing: false,
        clearError: true,
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      // Something already on screen beats an error page: the repository only
      // throws once it has no cached copy either.
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: state.overview != null
            ? null
            : describeNetworkFailure(error, whileDoing: 'loading gym data'),
        clearError: state.overview != null,
      );
    }
  }

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
}
