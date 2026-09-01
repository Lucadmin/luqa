import 'dart:async';

import 'package:luqa/core/id/local_id.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/today/data/outbox.dart';
import 'package:luqa/features/today/data/timeline_local_store.dart';
import 'package:luqa/features/today/data/timeline_sync_service.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

/// Makes the timeline the phone's own.
///
/// Every read comes from the device's rows and every write lands in them
/// first, so drawing a block updates the screen at the speed of the phone and
/// scrolling back through last month works with no signal at all.
class LocalFirstTodayRepository implements TodayRepository {
  LocalFirstTodayRepository({
    required this.store,
    required this.sync,
    required this.queue,
    String Function()? mintId,
    DateTime Function()? now,
  }) : _mintId = mintId ?? newLocalId,
       _now = now ?? DateTime.now;

  final TimelineLocalStore store;
  final TimelineSyncService sync;
  final MutationQueue<TimelineMutation> queue;

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

  // ----------------------------------------------------------------- reads

  /// Kept on the interface because the timeline paints from it before it does
  /// anything else. It is no longer a cache, though — it is the same rows the
  /// full read returns, so the two can never disagree.
  @override
  Future<List<Category>?> loadCachedCategories() async {
    await queue.ready;
    final categories = await store.categories();
    return categories.isEmpty ? null : categories;
  }

  @override
  Future<TimelineWindow?> loadCachedWindow(DateTime from, DateTime to) async {
    await queue.ready;
    if (await store.isEmpty) return null;
    return store.window(from, to);
  }

  @override
  Future<List<Category>> loadCategories() async {
    await queue.ready;
    return store.categories();
  }

  @override
  Future<TimelineWindow> loadWindow(DateTime from, DateTime to) async {
    await queue.ready;
    return store.window(from, to);
  }

  /// Catches up with the server. Not on the path between a tap and the screen.
  Future<void> pull() => sync.pull();

  // ---------------------------------------------------------------- writes

  /// Queues the mutation, writes the row, and only then lets the queue drain.
  ///
  /// Queueing first survives a crash between the two: the write still sends.
  /// Holding the drain until the row exists matters just as much — sending
  /// straight away would let the server rename a category while the block
  /// that refers to it is still being written.
  Future<void> _write(
    TimelineMutation mutation,
    Future<void> Function() apply,
  ) async {
    await queue.enqueue(mutation, sendNow: false);
    await apply();
    unawaited(queue.sync());
  }

  @override
  Future<TimeEntry> addEntry(NewTimeEntry draft) async {
    await queue.ready;
    final entry = TimeEntry(
      id: draft.id ?? _mintId(),
      description: draft.description,
      // The screen may be holding a category id this device invented moments
      // ago and the server has since replaced with its own.
      categoryId: await store.resolveCategoryId(draft.categoryId),
      start: draft.start,
      end: draft.end,
      pendingSync: true,
      personIds: draft.personIds,
    );

    // Starting a timer stops whichever one was running, the same rule the
    // server applies. Doing it here too keeps the two from disagreeing about
    // which block is open.
    if (entry.end == null) {
      final running = await store.runningEntry();
      if (running != null && running.id != entry.id) {
        await updateEntry(running, EntryPatch(end: entry.start));
      }
    }

    await _write(
      CreateEntry(entry: entry, queuedAt: _now()),
      () => store.putEntry(entry),
    );
    return entry;
  }

  @override
  Future<TimeEntry> updateEntry(TimeEntry entry, EntryPatch patch) async {
    await queue.ready;
    final resolved = patch.categoryId == null
        ? patch
        : EntryPatch(
            description: patch.description,
            categoryId: await store.resolveCategoryId(patch.categoryId),
            clearCategory: patch.clearCategory,
            start: patch.start,
            end: patch.end,
          );
    final updated = applyPatch(entry, resolved).copyWith(pendingSync: true);
    await _write(
      UpdateEntry(entryId: entry.id, patch: resolved, queuedAt: _now()),
      () => store.putEntry(updated),
    );
    return updated;
  }

  @override
  Future<void> deleteEntry(String id) async {
    await queue.ready;
    await _write(
      DeleteEntry(entryId: id, queuedAt: _now()),
      () => store.remove('timeline_entry', id),
    );
  }

  @override
  Future<Category> addCategory(String name) async {
    await queue.ready;
    final trimmed = name.trim();
    // A name the device already knows is the same category, whichever screen
    // asked for it. Reusing it keeps the queue from carrying two creates the
    // server would collapse into one anyway.
    final known = await store.categories();
    for (final existing in known) {
      if (existing.name.toLowerCase() == trimmed.toLowerCase()) return existing;
    }

    final category = Category(
      id: _mintId(),
      name: trimmed,
      colorValue: _palette[known.length % _palette.length],
    );
    await _write(
      CreateCategory(category: category, queuedAt: _now()),
      () => store.putCategory(category),
    );
    return category;
  }
}
