import 'dart:convert';

import 'package:luqa/features/gym/data/gym_json.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class SharedPreferencesGymCache implements GymCache {
  SharedPreferencesGymCache({
    required String namespace,
    SharedPreferencesAsync? preferences,
  }) : _namespace = base64Url.encode(utf8.encode(namespace)),
       _injected = preferences;

  static const _version = 'v1';

  /// Only the workouts recently opened are worth keeping; the overview already
  /// carries enough of the rest to render a list.
  static const _sessionLimit = 10;

  final String _namespace;
  final SharedPreferencesAsync? _injected;

  // Deferred, so building the cache does not require the platform channel.
  late final SharedPreferencesAsync _preferences =
      _injected ?? SharedPreferencesAsync();

  String get _overviewKey => 'luqa.gym.$_version.$_namespace.overview';
  String get _sessionsKey => 'luqa.gym.$_version.$_namespace.sessions';

  @override
  Future<GymOverview?> readOverview() async {
    final encoded = await _preferences.getString(_overviewKey);
    if (encoded == null) return null;
    try {
      return gymOverviewFromJson(jsonDecode(encoded) as Map<String, Object?>);
    } on Object {
      await _preferences.remove(_overviewKey);
      return null;
    }
  }

  @override
  Future<void> writeOverview(GymOverview overview) => _preferences.setString(
    _overviewKey,
    jsonEncode(gymOverviewToJson(overview)),
  );

  @override
  Future<GymSession?> readSession(String id) async {
    final stored = await _readSessions();
    return stored[id];
  }

  @override
  Future<void> writeSession(GymSession session) async {
    final stored = await _readSessions();
    stored.remove(session.id);
    stored[session.id] = session;
    // Insertion-ordered, so dropping from the front discards the least
    // recently touched workout.
    final keys = stored.keys.toList();
    for (final key in keys.take(
      keys.length <= _sessionLimit ? 0 : keys.length - _sessionLimit,
    )) {
      stored.remove(key);
    }
    await _preferences.setString(
      _sessionsKey,
      jsonEncode([for (final entry in stored.values) gymSessionToJson(entry)]),
    );
  }

  Future<Map<String, GymSession>> _readSessions() async {
    final encoded = await _preferences.getString(_sessionsKey);
    if (encoded == null) return {};
    try {
      return {
        for (final item in jsonDecode(encoded) as List<Object?>)
          if (gymSessionFromJson(item! as Map<String, Object?>)
              case final session)
            session.id: session,
      };
    } on Object {
      await _preferences.remove(_sessionsKey);
      return {};
    }
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
