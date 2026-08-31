import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/sync/sync_engine.dart';
import 'package:luqa/features/today/data/outbox.dart';
import 'package:luqa/features/today/data/remote_today_repository.dart';
import 'package:luqa/features/today/data/today_providers.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

/// Sends what the device has already done to the timeline.
///
/// It is deliberately not tied to a screen: a block logged on the way into a
/// tunnel has to reach the server even if the timeline was closed long ago, so
/// this provider is never auto-disposed.
final syncEngineProvider = NotifierProvider<SyncEngine, SyncState>(
  SyncEngine.new,
);

class SyncEngine extends Notifier<SyncState> with SyncQueue<TimelineMutation> {
  /// Read at the moment of sending rather than held: an engine whose queue is
  /// empty should never cause a network stack to be built at all.
  RemoteTodayRepository get _remote => ref.read(remoteTodayRepositoryProvider);

  @override
  SyncState build() {
    adoptOutbox(ref.watch(outboxProvider));
    return const SyncState();
  }

  @override
  List<TimelineMutation> fold(
    List<TimelineMutation> queue,
    TimelineMutation mutation,
  ) => foldInto(queue, mutation);

  @override
  Future<void> send(TimelineMutation mutation) async {
    switch (mutation) {
      case CreateEntry(:final entry):
        await _remote.addEntry(
          NewTimeEntry(
            id: entry.id,
            description: entry.description,
            categoryId: entry.categoryId,
            start: entry.start,
            end: entry.end,
          ),
        );
      case UpdateEntry(:final entryId, :final patch):
        await _remote.updateEntryById(entryId, patch);
      case DeleteEntry(:final entryId):
        await _remote.deleteEntry(entryId);
      case CreateCategory(:final category):
        final saved = await _remote.addCategoryWithId(category);
        // The server may have matched an existing category by name. Everything
        // still queued behind this points at the id we made up.
        if (saved.id != category.id) {
          await rewriteQueue(
            (queue) => remapCategoryId(queue, category.id, saved.id),
          );
        }
    }
  }
}
