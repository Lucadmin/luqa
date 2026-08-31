import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/sync/sync_engine.dart';
import 'package:luqa/features/gym/data/gym_outbox.dart';
import 'package:luqa/features/gym/data/gym_local_store.dart';
import 'package:luqa/features/gym/data/gym_providers.dart';
import 'package:luqa/features/gym/data/gym_repository.dart';

/// Sends the workouts this device has already logged.
///
/// Not tied to a screen: a session finished in a basement has to reach the
/// server whenever signal returns, long after the workout screen was closed.
final gymSyncEngineProvider = NotifierProvider<GymSyncEngine, SyncState>(
  GymSyncEngine.new,
);

class GymSyncEngine extends Notifier<SyncState> with SyncQueue<GymMutation> {
  /// Read at the moment of sending rather than held, so an empty queue never
  /// causes a network stack to be built at all.
  GymRepository get _remote => ref.read(remoteGymRepositoryProvider);

  /// This device's own rows, so a workout that has landed stops being treated
  /// as newer than the server's copy of it.
  GymLocalStore? get _store => ref.read(gymLocalStoreProvider);

  @override
  SyncState build() {
    adoptOutbox(ref.watch(gymOutboxProvider), ref.watch(gymDiscardLogProvider));
    return const SyncState();
  }

  @override
  List<GymMutation> fold(List<GymMutation> queue, GymMutation mutation) =>
      foldGym(queue, mutation);

  @override
  Future<void> send(GymMutation mutation) async {
    switch (mutation) {
      case CreateSession(:final session):
        await _remote.createSession(
          id: session.id,
          dateKey: session.dateKey,
          locationId: session.locationId,
        );
        await _store?.settle('gym_session', session.id);
      case SaveSession(:final sessionId, :final write):
        await _remote.saveSession(sessionId, write);
        await _store?.settle('gym_session', sessionId);
      case CreateLocation(:final location):
        final saved = await _remote.createLocation(
          id: location.id,
          name: location.name,
          code: location.code,
          colorValue: location.colorValue,
        );
        // A gym with this code may already exist server-side under another id.
        // Everything still queued behind this points at the one we made up,
        // and so does every workout already logged there.
        if (saved.id != location.id) {
          // Recorded first: a write being made right now resolves through it,
          // one already queued is caught by the rewrite below.
          await _store?.remapId('gym_location', location.id, saved.id);
          await rewriteQueue(
            (queue) => remapLocationId(queue, location.id, saved.id),
          );
        }
        await _store?.settle('gym_location', saved.id);
      case UpdateLocation(:final locationId):
        await _remote.updateLocation(
          id: locationId,
          name: mutation.name,
          code: mutation.code,
          colorValue: mutation.colorValue,
          archived: mutation.archived,
        );
        await _store?.settle('gym_location', locationId);
    }
  }
}
