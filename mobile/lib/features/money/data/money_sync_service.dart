import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/money/data/money_local_store.dart';
import 'package:luqa/features/money/data/remote_money_repository.dart';
import 'package:luqa_api/api.dart' as api;

/// Brings this device's copy of the money data up to date.
///
/// Pulls only what changed since the cursors the store holds, so the second
/// sync of the day costs a few rows rather than a year of history. A first
/// sync pages through everything, which is why this loops rather than making
/// one request.
class MoneySyncService {
  MoneySyncService({required this.client, required this.store});

  /// Which collections the money screen is built from. Named explicitly so a
  /// money sync never drags the gym and timeline down with it.
  static const collections = ['people', 'groups', 'expenses', 'settlements'];

  /// A first sync on a busy account walks a lot of pages; this is the ceiling
  /// on how many one call will walk before giving the app back its turn. The
  /// cursors are saved as it goes, so the next call resumes rather than
  /// restarts.
  static const maxPages = 50;

  final LuqaApi client;
  final MoneyLocalStore store;

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

      await store.setCurrency(response.settings.currency);
      final more = await _apply(response.collections);
      if (!more) return;
    }
  }

  /// Applies one page. Returns true when at least one collection says another
  /// page is waiting.
  ///
  /// Order matters: people and groups land before the expenses and payments
  /// that point at them, so the device is never briefly holding a bill whose
  /// participants it does not know.
  Future<bool> _apply(api.SyncCollections page) async {
    var more = false;

    final people = page.people.orElse(null);
    if (people != null) {
      await store.applyPeople(
        people.rows.map(personFromApi).toList(growable: false),
        people.deleted.toList(growable: false),
      );
      more |= await _advance('people', people.cursor.orElse(null), people.hasMore);
    }

    final groups = page.groups.orElse(null);
    if (groups != null) {
      await store.applyGroups(
        groups.rows.map(groupFromApi).toList(growable: false),
        groups.deleted.toList(growable: false),
      );
      more |= await _advance('groups', groups.cursor.orElse(null), groups.hasMore);
    }

    final expenses = page.expenses.orElse(null);
    if (expenses != null) {
      await store.applyExpenses(
        expenses.rows.map(expenseFromApi).toList(growable: false),
        expenses.deleted.toList(growable: false),
      );
      more |= await _advance('expenses', expenses.cursor.orElse(null), expenses.hasMore);
    }

    final settlements = page.settlements.orElse(null);
    if (settlements != null) {
      await store.applySettlements(
        settlements.rows.map(settlementFromApi).toList(growable: false),
        settlements.deleted.toList(growable: false),
      );
      more |= await _advance(
        'settlements',
        settlements.cursor.orElse(null),
        settlements.hasMore,
      );
    }

    return more;
  }

  /// Saves where a collection got to, before anything else can fail.
  ///
  /// A null cursor means the collection has never had a row; there is nothing
  /// to remember and the one already held — if any — stays.
  Future<bool> _advance(String name, String? cursor, bool hasMore) async {
    if (cursor != null) await store.setCursor(name, cursor);
    return hasMore;
  }
}
