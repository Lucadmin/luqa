import 'package:luqa/core/id/local_id.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/gym/data/gym_cache.dart';
import 'package:luqa/features/gym/data/gym_outbox.dart';
import 'package:luqa/features/gym/data/gym_repository.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

/// Makes the gym log work on the phone.
///
/// Starting a workout, adding a set and naming a gym all complete without a
/// round trip: the row is given an id here, recorded in the queue, and handed
/// straight back. Reads come back as the server's last known state with the
/// queue laid over the top — the only view that is true both before and after
/// a write lands.
class LocalFirstGymRepository implements GymRepository {
  LocalFirstGymRepository({
    required this.remote,
    required this.cache,
    required this.queue,
    String Function()? mintId,
    DateTime Function()? now,
  }) : _mintId = mintId ?? newLocalId,
       _now = now ?? DateTime.now;

  final GymRepository remote;
  final GymCache cache;
  final MutationQueue<GymMutation> queue;

  final String Function() _mintId;
  final DateTime Function() _now;

  /// Mirrors the server's palette so a gym invented offline usually keeps the
  /// colour it was given once it syncs.
  static const _fallbackColor = 0xFF6366F1;

  @override
  Future<GymOverview> loadOverview({int limit = 30}) async {
    await queue.ready;
    try {
      final overview = await remote.loadOverview(limit: limit);
      await cache.writeOverview(overview);
      return overlayGym(overview, queue.pending);
    } on Object {
      // Offline is the normal case in a gym, not an error page. The cached
      // overview with local work on top is a complete, usable screen.
      final cached = await cache.readOverview();
      if (cached == null) rethrow;
      return overlayGym(cached, queue.pending);
    }
  }

  /// The cached overview alone, so a screen can paint before the network is
  /// even attempted. Null when this device has never loaded one.
  Future<GymOverview?> cachedOverview() async {
    await queue.ready;
    final cached = await cache.readOverview();
    if (cached == null) {
      // A workout started offline on a fresh install still has to be openable.
      final pending = overlayGym(_emptyOverview, queue.pending);
      return pending.sessions.isEmpty && pending.locations.isEmpty
          ? null
          : pending;
    }
    return overlayGym(cached, queue.pending);
  }

  static const _emptyOverview = GymOverview(
    locations: [],
    exercises: [],
    recentReferences: [],
    sessions: [],
    totalSessions: 0,
  );

  @override
  Future<GymSession> createSession({
    String? id,
    required String dateKey,
    required String? locationId,
  }) async {
    final session = GymSession(
      id: id ?? _mintId(),
      dateKey: dateKey,
      locationId: locationId,
      notes: '',
      exercises: const [],
      createdAt: _now(),
    );
    await queue.enqueue(CreateSession(session: session, queuedAt: _now()));
    await cache.writeSession(session);
    return session;
  }

  @override
  Future<GymSession> loadSession(String id) async {
    await queue.ready;
    try {
      final session = await remote.loadSession(id);
      await cache.writeSession(session);
      return overlayGymSession(session, queue.pending) ?? session;
    } on Object {
      final cached = await cache.readSession(id);
      final overlaid = overlayGymSession(cached, queue.pending);
      // A workout that only exists in the queue is still a workout.
      if (overlaid == null) rethrow;
      return overlaid;
    }
  }

  @override
  Future<GymSession> saveSession(String id, GymSessionWrite write) async {
    await queue.ready;
    final base =
        overlayGymSession(await cache.readSession(id), queue.pending) ??
        GymSession(
          id: id,
          dateKey: write.dateKey,
          locationId: write.locationId,
          notes: write.notes,
          exercises: const [],
          createdAt: _now(),
        );
    final saved = applyWrite(base, write);
    await queue.enqueue(
      SaveSession(sessionId: id, write: write, queuedAt: _now()),
    );
    await cache.writeSession(saved);
    return saved;
  }

  @override
  Future<GymSessionPage> loadSessions({String? cursor, int limit = 20}) async {
    await queue.ready;
    final page = await remote.loadSessions(cursor: cursor, limit: limit);
    // Only the first page can meaningfully carry unsent work; a cursor into
    // history is asking about rows the server already holds.
    if (cursor != null) return page;
    final overlaid = overlayGym(
      _emptyOverview.copyWith(sessions: page.sessions),
      queue.pending,
    );
    return GymSessionPage(
      sessions: overlaid.sessions,
      nextCursor: page.nextCursor,
    );
  }

  @override
  Future<GymExerciseHistory> loadExerciseHistory(
    String exerciseId, {
    String? locationId,
    String? beforeSessionId,
  }) => remote.loadExerciseHistory(
    exerciseId,
    locationId: locationId,
    beforeSessionId: beforeSessionId,
  );

  @override
  Future<GymLocation> createLocation({
    String? id,
    required String name,
    required String code,
    required int colorValue,
  }) async {
    await queue.ready;
    final known = await cache.readOverview();
    final locations = overlayGym(
      known ?? _emptyOverview,
      queue.pending,
    ).locations;
    // A gym is identified by its code, so re-adding one the device already
    // knows is the same gym rather than a second row for the server to merge.
    for (final existing in locations) {
      if (existing.code.toLowerCase() == code.toLowerCase()) return existing;
    }

    final location = GymLocation(
      id: id ?? _mintId(),
      code: code,
      name: name,
      colorValue: colorValue == 0 ? _fallbackColor : colorValue,
      order: locations.length,
      archived: false,
    );
    await queue.enqueue(CreateLocation(location: location, queuedAt: _now()));
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
    await queue.enqueue(mutation);

    final known = await cache.readOverview();
    for (final existing in overlayGym(
      known ?? _emptyOverview,
      queue.pending,
    ).locations) {
      if (existing.id == id) return existing;
    }
    return mutation.applyTo(
      GymLocation(
        id: id,
        code: code ?? '',
        name: name ?? '',
        colorValue: colorValue ?? _fallbackColor,
        order: 0,
        archived: archived ?? false,
      ),
    );
  }
}
