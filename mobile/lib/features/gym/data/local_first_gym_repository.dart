import 'dart:async';

import 'package:luqa/core/id/local_id.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/gym/data/gym_local_store.dart';
import 'package:luqa/features/gym/data/gym_outbox.dart';
import 'package:luqa/features/gym/data/gym_repository.dart';
import 'package:luqa/features/gym/data/gym_sync_service.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

/// Makes the gym tab work in a basement.
///
/// Every read comes from this device's rows and every write lands in them
/// first. Nothing a workout screen shows — the last time you did this lift,
/// what the bar was loaded to, whether that was a record — waits on a network
/// that a gym almost never has.
class LocalFirstGymRepository implements GymRepository {
  LocalFirstGymRepository({
    required this.store,
    required this.sync,
    required this.remote,
    required this.queue,
    String Function()? mintId,
    DateTime Function()? now,
  }) : _mintId = mintId ?? newLocalId,
       _now = now ?? DateTime.now;

  final GymLocalStore store;
  final GymSyncService sync;

  /// Only for merging, which is the one thing a device cannot decide alone.
  final GymRepository remote;

  final MutationQueue<GymMutation> queue;

  final String Function() _mintId;
  final DateTime Function() _now;

  static const _fallbackColor = 0xFF6366F1;

  // ----------------------------------------------------------------- reads

  @override
  Future<GymOverview> loadOverview({int limit = 30}) async {
    await queue.ready;
    return store.overview(limit: limit);
  }

  @override
  Future<GymSession> loadSession(String id) async {
    await queue.ready;
    final session = await store.session(id);
    if (session == null) throw StateError('No workout $id on this device');
    return session;
  }

  @override
  Future<GymSessionPage> loadSessions({String? cursor, int limit = 20}) async {
    await queue.ready;
    return store.sessions(cursor: cursor, limit: limit);
  }

  @override
  Future<GymExerciseHistory> loadExerciseHistory(
    String exerciseId, {
    String? locationId,
    String? beforeSessionId,
  }) async {
    await queue.ready;
    final history = await store.exerciseHistory(
      exerciseId,
      locationId: locationId,
      beforeSessionId: beforeSessionId,
    );
    if (history == null) {
      throw StateError('No exercise $exerciseId on this device');
    }
    return history;
  }

  /// Catches up with the server. Not on the path between a tap and the screen.
  Future<void> pull() => sync.pull();

  // ---------------------------------------------------------------- writes

  /// Queues the mutation, writes the row, and only then lets the queue drain.
  ///
  /// Queueing first survives a crash between the two: the write still sends.
  /// Holding the drain until the row exists matters just as much — sending
  /// straight away would let the server rename an id while the write that
  /// refers to it is still being made.
  Future<void> _write(
    GymMutation mutation,
    Future<void> Function() apply,
  ) async {
    await queue.enqueue(mutation, sendNow: false);
    await apply();
    unawaited(queue.sync());
  }

  @override
  Future<GymSession> createSession({
    String? id,
    required String dateKey,
    required String? locationId,
  }) async {
    await queue.ready;
    final session = GymSession(
      id: id ?? _mintId(),
      dateKey: dateKey,
      // The picker may be holding a gym id the server has since replaced with
      // its own, having matched the code.
      locationId: await store.resolve('gym_location', locationId),
      notes: '',
      exercises: const [],
      createdAt: _now(),
    );
    await _write(
      CreateSession(session: session, queuedAt: _now()),
      () => store.putSession(session),
    );
    return session;
  }

  @override
  Future<GymSession> saveSession(String id, GymSessionWrite write) async {
    await queue.ready;
    final base =
        await store.session(id) ??
        GymSession(
          id: id,
          dateKey: write.dateKey,
          locationId: write.locationId,
          notes: write.notes,
          exercises: const [],
          createdAt: _now(),
        );
    final saved = applyWrite(base, await _resolveExercises(write));
    await _write(
      SaveSession(sessionId: id, write: write, queuedAt: _now()),
      () => store.putSession(saved),
    );
    return saved;
  }

  /// Repoints anything in the workout at an exercise that has since been
  /// merged into another.
  Future<GymSessionWrite> _resolveExercises(GymSessionWrite write) async {
    final exercises = <GymExerciseWrite>[];
    var changed = false;
    for (final exercise in write.exercises) {
      final resolved = await store.resolve('gym_exercise', exercise.exerciseId);
      if (resolved != exercise.exerciseId) changed = true;
      exercises.add(
        GymExerciseWrite(
          exerciseId: resolved,
          name: exercise.name,
          sets: exercise.sets,
          notes: exercise.notes,
        ),
      );
    }
    if (!changed) return write;
    return GymSessionWrite(
      dateKey: write.dateKey,
      locationId: write.locationId,
      notes: write.notes,
      exercises: exercises,
    );
  }

  @override
  Future<GymLocation> createLocation({
    String? id,
    required String name,
    required String code,
    required int colorValue,
  }) async {
    await queue.ready;
    // A gym is identified by its code, so re-adding one this device knows is
    // the same gym rather than a second row for the server to merge.
    for (final existing in await store.locations()) {
      if (existing.code.toLowerCase() == code.toLowerCase()) return existing;
    }

    final location = GymLocation(
      id: id ?? _mintId(),
      code: code,
      name: name,
      colorValue: colorValue == 0 ? _fallbackColor : colorValue,
      order: (await store.locations()).length,
      archived: false,
    );
    await _write(
      CreateLocation(location: location, queuedAt: _now()),
      () => store.putLocation(location),
    );
    return location;
  }

  @override
  Future<GymLocation> updateLocation({
    required String id,
    String? name,
    String? code,
    int? colorValue,
    bool? archived,
  }) async {
    await queue.ready;
    final mutation = UpdateLocation(
      locationId: id,
      name: name,
      code: code,
      colorValue: colorValue,
      archived: archived,
      queuedAt: _now(),
    );

    GymLocation? existing;
    for (final location in await store.locations()) {
      if (location.id == id) existing = location;
    }
    final updated = mutation.applyTo(
      existing ??
          GymLocation(
            id: id,
            code: code ?? '',
            name: name ?? '',
            colorValue: colorValue ?? _fallbackColor,
            order: 0,
            archived: archived ?? false,
          ),
    );

    await _write(mutation, () => store.putLocation(updated));
    return updated;
  }

  /// Folding two exercises into one is the server's decision: it owns which
  /// rows survive, and every workout that referenced the loser has to be
  /// repointed at once. Doing it locally and replaying would be guessing.
  @override
  Future<GymExercise> mergeExercise({
    required String sourceExerciseId,
    required String targetExerciseId,
  }) async {
    await queue.ready;
    if (queue.pending.isNotEmpty) {
      throw StateError('Sync pending workout changes before merging.');
    }
    final target = await remote.mergeExercise(
      sourceExerciseId: sourceExerciseId,
      targetExerciseId: targetExerciseId,
    );
    // Recorded before the pull, so a workout being written right now resolves
    // the retired id rather than referring to an exercise about to vanish.
    await store.recordMerge(sourceExerciseId, target.id);
    // The sessions that pointed at the loser now point at the winner, and the
    // loser is tombstoned — both of which the next delta carries.
    await sync.pull();
    return target;
  }
}
