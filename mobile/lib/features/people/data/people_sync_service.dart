import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/money/data/money_local_store.dart';
import 'package:luqa/features/money/data/remote_money_repository.dart'
    show personFromApi;

/// Brings this device's copy of the people up to date.
///
/// The same shape as the money and gym syncs: only what changed since the
/// cursor this device holds, paged, with the cursor saved as it goes so an
/// interrupted sync resumes rather than starting again.
///
/// It pulls one collection, and it is the same `people` collection Money
/// syncs — one row, one feed. Opening the People tab and opening the Money tab
/// therefore refresh the same rows through the same cursor; whichever ran last
/// simply finds nothing new.
class PeopleSyncService {
  PeopleSyncService({required this.client, required this.store});

  static const collections = ['people'];

  static const maxPages = 50;

  final LuqaApi client;
  final MoneyLocalStore store;

  Future<void> pull() async {
    for (var page = 0; page < maxPages; page++) {
      final saved = await store.cursor('people');

      final response = await client.syncChanges(
        collections: collections.join(','),
        cursors: saved == null ? const {} : {'people': saved},
      );

      final people = response.collections.people.orElse(null);
      if (people == null) return;

      // The profile children arrive inside each person, so applying a page
      // writes the whole record. There is no second collection to keep in step
      // and no window in which a person exists here without their notes.
      await store.applyPeople(
        people.rows.map(personFromApi).toList(growable: false),
        people.deleted.toList(growable: false),
      );

      final cursor = people.cursor.orElse(null);
      if (cursor != null) await store.setCursor('people', cursor);
      if (!people.hasMore) return;
    }
  }
}
