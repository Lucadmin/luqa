import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/gym/data/gym_local_store.dart';
import 'package:luqa/features/gym/data/remote_gym_repository.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';
import 'package:luqa_api/api.dart' as api;

/// Brings this device's copy of the gym log up to date.
///
/// The same shape as the money sync: only what changed since the cursors this
/// device holds, paged, with the cursors saved as it goes so an interrupted
/// sync resumes rather than starting again.
class GymSyncService {
  GymSyncService({required this.client, required this.store});

  static const collections = ['gymLocations', 'exercises', 'gymSessions'];

  static const maxPages = 50;

  final LuqaApi client;
  final GymLocalStore store;

  Future<void> pull() async {
    for (var page = 0; page < maxPages; page++) {
      final cursors = <String, String>{};
      for (final name in collections) {
        final saved = await store.cursor(name);
        if (saved != null) cursors[name] = saved;
      }

      final response = await client.syncChanges(
        collections: collections.join(','),
        cursors: cursors,
      );
      if (!await _apply(response.collections)) return;
    }
  }

  /// Gyms and exercises land before the workouts that point at them, so the
  /// device is never briefly holding a session whose lifts it cannot name.
  Future<bool> _apply(api.SyncCollections page) async {
    var more = false;

    final locations = page.gymLocations.orElse(null);
    if (locations != null) {
      await store.applyLocations(
        locations.rows.map(gymLocationFromApi).toList(growable: false),
        locations.deleted.toList(growable: false),
      );
      more |= await _advance(
        'gymLocations',
        locations.cursor.orElse(null),
        locations.hasMore,
      );
    }

    final exercises = page.exercises.orElse(null);
    if (exercises != null) {
      await store.applyExercises([
        // The feed sends the stored row; the counts and dates the overview
        // shows are derived from the sessions on this device.
        for (final row in exercises.rows)
          GymExercise(
            id: row.id,
            name: row.name,
            notes: row.notes,
            archived: row.archived,
            sessionCount: 0,
            lastPerformed: null,
            locationIds: const [],
          ),
      ], exercises.deleted.toList(growable: false));
      more |= await _advance(
        'exercises',
        exercises.cursor.orElse(null),
        exercises.hasMore,
      );
    }

    final sessions = page.gymSessions.orElse(null);
    if (sessions != null) {
      await store.applySessions(
        sessions.rows.map(gymSessionFromApi).toList(growable: false),
        sessions.deleted.toList(growable: false),
      );
      more |= await _advance(
        'gymSessions',
        sessions.cursor.orElse(null),
        sessions.hasMore,
      );
    }

    return more;
  }

  Future<bool> _advance(String name, String? cursor, bool hasMore) async {
    if (cursor != null) await store.setCursor(name, cursor);
    return hasMore;
  }
}
