import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/sync/sync_engine.dart';
import 'package:luqa/features/habits/data/habits_local_store.dart';
import 'package:luqa/features/habits/data/habits_outbox.dart';
import 'package:luqa/features/habits/data/habits_providers.dart';
import 'package:luqa/features/habits/data/habits_repository.dart';

/// Sends the check-ins this device has already made.
///
/// Not tied to a screen: a habit ticked on a run has to reach the server
/// whenever signal returns, long after Today was closed.
final habitsSyncEngineProvider = NotifierProvider<HabitsSyncEngine, SyncState>(
  HabitsSyncEngine.new,
);

class HabitsSyncEngine extends Notifier<SyncState>
    with SyncQueue<HabitMutation> {
  /// Read at the moment of sending rather than held, so an empty queue never
  /// causes a network stack to be built at all.
  HabitsRepository get _remote => ref.read(remoteHabitsRepositoryProvider);

  /// This device's own rows, so a write that has landed stops being treated as
  /// newer than the server's copy of it.
  HabitsLocalStore? get _store => ref.read(habitsLocalStoreProvider);

  @override
  SyncState build() {
    adoptOutbox(
      ref.watch(habitsOutboxProvider),
      ref.watch(habitsDiscardLogProvider),
    );
    return const SyncState();
  }

  @override
  List<HabitMutation> fold(List<HabitMutation> queue, HabitMutation mutation) =>
      foldHabits(queue, mutation);

  @override
  Future<void> send(HabitMutation mutation) async {
    switch (mutation) {
      case CreateHabit(:final habit):
        final saved = await _remote.createHabit(
          HabitDraft(
            name: habit.name,
            icon: habit.icon,
            colorValue: habit.colorValue,
            goalType: habit.goalType,
            goalPeriod: habit.goalPeriod,
            targetCount: habit.targetCount,
            targetSeconds: habit.targetSeconds,
            categoryId: habit.categoryId,
            scheduleType: habit.scheduleType,
            weekdays: habit.weekdays,
            weekInterval: habit.weekInterval,
            intervalDays: habit.intervalDays,
            intervalFromLastDone: habit.intervalFromLastDone,
            timesPerPeriod: habit.timesPerPeriod,
            anchorDate: habit.anchorDate,
            dates: habit.dates,
            excludedDates: habit.excludedDates,
          ),
          id: habit.id,
        );
        // The server keeps the id this device minted unless something else
        // already holds it. When it does not, everything queued behind this
        // still points at the one we made up — and so does every log already
        // written against it.
        if (saved.id != habit.id) {
          // Recorded first: a write being made right now resolves through it,
          // one already queued is caught by the rewrite below.
          await _store?.remapHabit(habit.id, saved.id);
          await rewriteQueue(
            (queue) => remapHabitId(queue, habit.id, saved.id),
          );
        }
        await _store?.settleHabit(saved.id);
      case UpdateHabit(:final habit):
        await _remote.saveHabit(habit);
        await _store?.settleHabit(habit.id);
      case ArchiveHabit(:final habitId):
        await _remote.archiveHabit(habitId);
        await _store?.settleHabit(habitId);
      case ReorderHabits(:final ids):
        await _remote.reorderHabits(ids);
        for (final id in ids) {
          await _store?.settleHabit(id);
        }
      case WriteHabitLog(:final log):
        await _remote.writeLog(log);
        await _store?.settleLog(log.habitId, log.date);
    }
  }
}
