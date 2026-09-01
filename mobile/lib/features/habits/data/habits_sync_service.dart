import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/habits/data/habit_json.dart';
import 'package:luqa/features/habits/data/habits_local_store.dart';
import 'package:luqa_api/api.dart' as api;

/// Brings this device's copy of the habits up to date.
///
/// The same shape as the gym and money syncs: only what changed since the
/// cursors this device holds, paged, with the cursors saved as it goes so an
/// interrupted sync resumes rather than starting again.
class HabitsSyncService {
  HabitsSyncService({required this.client, required this.store});

  static const collections = ['habits', 'habitLogs'];

  static const maxPages = 50;

  final LuqaApi client;
  final HabitsLocalStore store;

  /// The account settings the last sync reported, or null before one has run.
  ///
  /// Both of these decide which day a check-in belongs to, so a screen that
  /// resolves habits locally has to be told rather than assume.
  int? get dayStartHour => _dayStartHour;
  int? get weekStartsOn => _weekStartsOn;

  int? _dayStartHour;
  int? _weekStartsOn;

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
      _dayStartHour = response.settings.dayStartHour;
      _weekStartsOn = response.settings.weekStartsOn;
      if (!await _apply(response.collections)) return;
    }
  }

  /// Habits land before the logs that point at them, so the device is never
  /// briefly holding progress against a habit it cannot name.
  Future<bool> _apply(api.SyncCollections page) async {
    var more = false;

    final habits = page.habits.orElse(null);
    if (habits != null) {
      await store.applyHabits(
        habits.rows.map(habitFromApi).toList(growable: false),
      );
      more |= await _advance(
        'habits',
        habits.cursor.orElse(null),
        habits.hasMore,
      );
    }

    final logs = page.habitLogs.orElse(null);
    if (logs != null) {
      await store.applyLogs(
        logs.rows.map(habitLogFromApi).toList(growable: false),
      );
      more |= await _advance(
        'habitLogs',
        logs.cursor.orElse(null),
        logs.hasMore,
      );
    }

    return more;
  }

  Future<bool> _advance(String name, String? cursor, bool hasMore) async {
    if (cursor != null) await store.setCursor(name, cursor);
    return hasMore;
  }
}
