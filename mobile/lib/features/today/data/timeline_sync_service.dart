import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/today/data/remote_today_repository.dart';
import 'package:luqa/features/today/data/timeline_local_store.dart';
import 'package:luqa_api/api.dart' as api;

/// Brings this device's copy of the timeline up to date.
class TimelineSyncService {
  TimelineSyncService({required this.client, required this.store});

  static const collections = ['categories', 'timeEntries', 'sleepEntries'];

  static const maxPages = 80;

  final LuqaApi client;
  final TimelineLocalStore store;

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

  /// Categories land before the blocks filed under them.
  Future<bool> _apply(api.SyncCollections page) async {
    var more = false;

    final categories = page.categories.orElse(null);
    if (categories != null) {
      await store.applyCategories(
        categories.rows.map(categoryFromApi).toList(growable: false),
        categories.deleted.toList(growable: false),
        // An archived category keeps resolving on the blocks that already use
        // it, but stops being offered for new ones.
        archived: {
          for (final row in categories.rows)
            if (row.archived) row.id,
        },
      );
      more |= await _advance(
        'categories',
        categories.cursor.orElse(null),
        categories.hasMore,
      );
    }

    final entries = page.timeEntries.orElse(null);
    if (entries != null) {
      await store.applyEntries(
        entries.rows.map(entryFromApi).toList(growable: false),
        entries.deleted.toList(growable: false),
      );
      more |= await _advance(
        'timeEntries',
        entries.cursor.orElse(null),
        entries.hasMore,
      );
    }

    final sleep = page.sleepEntries.orElse(null);
    if (sleep != null) {
      await store.applySleep(
        sleep.rows.map(sleepFromApi).toList(growable: false),
        sleep.deleted.toList(growable: false),
      );
      more |= await _advance(
        'sleepEntries',
        sleep.cursor.orElse(null),
        sleep.hasMore,
      );
    }

    return more;
  }

  Future<bool> _advance(String name, String? cursor, bool hasMore) async {
    if (cursor != null) await store.setCursor(name, cursor);
    return hasMore;
  }
}
