import 'package:luqa/core/storage/document_cache.dart';
import 'package:luqa/core/storage/luqa_store.dart';
import 'package:luqa/features/gym/data/gym_json.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

/// App-private, user-scoped read cache for the gym log.
///
/// It exists because a gym is the worst place on earth for a network. The
/// overview and the open workout are kept on disk so the screen paints from
/// the phone and the last workout can be reopened in a basement.
abstract interface class GymCache {
  Future<GymOverview?> readOverview();

  Future<void> writeOverview(GymOverview overview);

  Future<GymSession?> readSession(String id);

  Future<void> writeSession(GymSession session);
}

class SqliteGymCache implements GymCache {
  SqliteGymCache({required String namespace, LuqaStore? store})
    : _overview = DocumentCache(
        namespace: namespace,
        collection: 'gym',
        store: store,
      ),
      // Workouts are addressed by id and kept as a recency window, so they
      // get a collection of their own to trim independently.
      _sessions = DocumentCache(
        namespace: namespace,
        collection: 'gym.sessions',
        store: store,
      );

  /// Only the workouts recently opened are worth keeping; the overview already
  /// carries enough of the rest to render a list.
  static const _sessionLimit = 10;

  final DocumentCache _overview;
  final DocumentCache _sessions;

  @override
  Future<GymOverview?> readOverview() async {
    final value = await _overview.read<Map<String, Object?>>('overview');
    if (value == null) return null;
    try {
      return gymOverviewFromJson(value);
    } on Object {
      await _overview.remove('overview');
      return null;
    }
  }

  @override
  Future<void> writeOverview(GymOverview overview) =>
      _overview.write('overview', gymOverviewToJson(overview));

  @override
  Future<GymSession?> readSession(String id) async {
    final value = await _sessions.read<Map<String, Object?>>(id);
    if (value == null) return null;
    try {
      return gymSessionFromJson(value);
    } on Object {
      await _sessions.remove(id);
      return null;
    }
  }

  @override
  Future<void> writeSession(GymSession session) async {
    await _sessions.write(session.id, gymSessionToJson(session));
    // Ordered by when each was last written, so trimming discards the least
    // recently touched workout.
    await _sessions.trim(_sessionLimit);
  }
}

/// A cache that keeps nothing, for signed-out and test contexts.
class NullGymCache implements GymCache {
  const NullGymCache();

  @override
  Future<GymOverview?> readOverview() async => null;

  @override
  Future<void> writeOverview(GymOverview overview) async {}

  @override
  Future<GymSession?> readSession(String id) async => null;

  @override
  Future<void> writeSession(GymSession session) async {}
}
