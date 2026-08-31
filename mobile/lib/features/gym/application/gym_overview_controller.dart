import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/network/network_failure.dart';
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
    this.isCreatingWorkout = false,
    this.error,
  });

  final GymOverview? overview;
  final bool isLoading;
  final bool isRefreshing;
  final bool isCreatingWorkout;
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
    bool? isCreatingWorkout,
    String? error,
    bool clearError = false,
  }) => GymOverviewState(
    overview: overview ?? this.overview,
    isLoading: isLoading ?? this.isLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isCreatingWorkout: isCreatingWorkout ?? this.isCreatingWorkout,
    error: clearError ? null : error ?? this.error,
  );
}

class GymOverviewController extends Notifier<GymOverviewState> {
  late GymRepository _repository;
  int _generation = 0;

  @override
  GymOverviewState build() {
    _repository = ref.watch(gymRepositoryProvider);
    Future<void>.microtask(load);
    return const GymOverviewState();
  }

  Future<void> load({bool refresh = false}) async {
    final generation = ++_generation;
    state = state.copyWith(
      isLoading: state.overview == null,
      isRefreshing: refresh && state.overview != null,
      clearError: true,
    );
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
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: describeNetworkFailure(error, whileDoing: 'loading gym data'),
      );
    }
  }

  Future<void> refresh() => load(refresh: true);

  Future<GymSession?> startWorkout({String? locationId}) async {
    if (state.isCreatingWorkout) return null;
    state = state.copyWith(isCreatingWorkout: true, clearError: true);
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
        isCreatingWorkout: false,
        clearError: true,
      );
      return session;
    } on Object catch (error) {
      if (!ref.mounted) return null;
      state = state.copyWith(
        isCreatingWorkout: false,
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
        state = state.copyWith(
          overview: overview.copyWith(
            locations: [...overview.locations, location],
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
