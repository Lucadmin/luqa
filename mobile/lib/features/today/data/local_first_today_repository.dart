import 'package:luqa/core/id/local_id.dart';
import 'package:luqa/features/today/data/outbox.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

/// Makes every write local.
///
/// Nothing here awaits the network. A change is given an id, recorded in the
/// queue and handed straight back, so the screen updates at the speed of the
/// phone; the sync engine drains the queue behind it. Reads come back as the
/// server's last known state with the queue laid over the top, which is the
/// only view that is true both before and after a write lands.
class LocalFirstTodayRepository implements TodayRepository {
  LocalFirstTodayRepository({
    required this.remote,
    required this.queue,
    String Function()? mintId,
    DateTime Function()? now,
  }) : _mintId = mintId ?? newLocalId,
       _now = now ?? DateTime.now;

  /// The server, reached only for reads and by the sync engine.
  final TodayRepository remote;
  final MutationQueue queue;

  final String Function() _mintId;
  final DateTime Function() _now;

  /// Mirrors the server's palette so a category invented offline usually keeps
  /// the colour it was drawn with once it syncs.
  static const _palette = [
    0xFF6366F1,
    0xFFEC4899,
    0xFFF59E0B,
    0xFF10B981,
    0xFF3B82F6,
    0xFF8B5CF6,
    0xFFEF4444,
    0xFF14B8A6,
    0xFFF97316,
    0xFF06B6D4,
  ];

  @override
  Future<List<Category>?> loadCachedCategories() async {
    final cached = await remote.loadCachedCategories();
    await queue.ready;
    if (cached == null) {
      // Nothing from the server yet, but a category invented offline still has
      // to be pickable.
      final pending = overlayPendingCategories(const [], queue.pending);
      return pending.isEmpty ? null : pending;
    }
    return overlayPendingCategories(cached, queue.pending);
  }

  @override
  Future<TimelineWindow?> loadCachedWindow(DateTime from, DateTime to) async {
    final cached = await remote.loadCachedWindow(from, to);
    await queue.ready;
    if (cached == null) return null;
    return overlayPending(cached, queue.pending);
  }

  @override
  Future<List<Category>> loadCategories() async {
    final categories = await remote.loadCategories();
    return overlayPendingCategories(categories, queue.pending);
  }

  @override
  Future<TimelineWindow> loadWindow(DateTime from, DateTime to) async {
    final window = await remote.loadWindow(from, to);
    return overlayPending(window, queue.pending);
  }

  @override
  Future<TimeEntry> addEntry(NewTimeEntry draft) async {
    final entry = TimeEntry(
      id: _mintId(),
      description: draft.description,
      categoryId: draft.categoryId,
      start: draft.start,
      end: draft.end,
      pendingSync: true,
    );
    await queue.enqueue(CreateEntry(entry: entry, queuedAt: _now()));
    return entry;
  }

  @override
  Future<TimeEntry> updateEntry(TimeEntry entry, EntryPatch patch) async {
    await queue.enqueue(
      UpdateEntry(entryId: entry.id, patch: patch, queuedAt: _now()),
    );
    return applyPatch(entry, patch).copyWith(pendingSync: true);
  }

  @override
  Future<void> deleteEntry(String id) =>
      queue.enqueue(DeleteEntry(entryId: id, queuedAt: _now()));

  @override
  Future<Category> addCategory(String name) async {
    final trimmed = name.trim();
    // A name the device already knows is the same category, whichever screen
    // asked for it. Reusing it keeps the queue from carrying two creates that
    // the server would collapse into one anyway.
    final known = await loadCachedCategories();
    for (final existing in known ?? const <Category>[]) {
      if (existing.name.toLowerCase() == trimmed.toLowerCase()) return existing;
    }

    final category = Category(
      id: _mintId(),
      name: trimmed,
      colorValue: _palette[(known?.length ?? 0) % _palette.length],
    );
    await queue.enqueue(CreateCategory(category: category, queuedAt: _now()));
    return category;
  }
}
