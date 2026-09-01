import 'dart:async';

import 'package:luqa/core/id/local_id.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/habits/data/habits_local_store.dart';
import 'package:luqa/features/habits/data/habits_outbox.dart';
import 'package:luqa/features/habits/data/habits_repository.dart';
import 'package:luqa/features/habits/data/habits_sync_service.dart';
import 'package:luqa/features/habits/domain/habit.dart';

/// Makes checking a habit off work with no network at all.
///
/// Habits are ticked in exactly the places a phone has no signal — mid-run,
/// last thing at night, underground — so every read comes from this device's
/// rows and every write lands in them first. Which habits a day holds, and
/// whether each is done, is worked out here rather than asked for.
class LocalFirstHabitsRepository implements HabitsRepository {
  LocalFirstHabitsRepository({
    required this.store,
    required this.sync,
    required this.queue,
    String Function()? mintId,
    DateTime Function()? now,
  }) : _mintId = mintId ?? newLocalId,
       _now = now ?? DateTime.now;

  final HabitsLocalStore store;
  final HabitsSyncService sync;
  final MutationQueue<HabitMutation> queue;

  final String Function() _mintId;
  final DateTime Function() _now;

  // ----------------------------------------------------------------- reads

  @override
  Future<List<Habit>> loadHabits() async {
    await queue.ready;
    return store.habits();
  }

  @override
  Future<List<HabitLog>> loadLogs({
    required String from,
    required String to,
  }) async {
    await queue.ready;
    return store.logsBetween(from, to);
  }

  /// Catches up with the server. Not on the path between a tap and the screen.
  Future<void> pull() => sync.pull();

  /// What the last sync said about the account, for the day and week
  /// boundaries habits are counted against.
  int? get dayStartHour => sync.dayStartHour;
  int? get weekStartsOn => sync.weekStartsOn;

  // ---------------------------------------------------------------- writes

  /// Queues the mutation, writes the row, and only then lets the queue drain.
  ///
  /// Queueing first survives a crash between the two: the write still sends.
  /// Holding the drain until the row exists matters just as much — sending
  /// straight away would let the server rename an id while the write that
  /// refers to it is still being made.
  Future<void> _write(
    HabitMutation mutation,
    Future<void> Function() apply,
  ) async {
    await queue.enqueue(mutation, sendNow: false);
    await apply();
    unawaited(queue.sync());
  }

  @override
  Future<Habit> createHabit(HabitDraft draft, {String? id}) async {
    await queue.ready;
    final existing = await store.habits();
    final habit = draft.toHabit(
      id: id ?? _mintId(),
      // Appended, the same as the server would: a new habit belongs at the
      // bottom of the list, not in the middle of one already in an order.
      order: existing.where((habit) => !habit.archived).length,
      createdAt: _now(),
    );
    await _write(
      CreateHabit(habit: habit, queuedAt: _now()),
      () => store.putHabit(habit),
    );
    return habit;
  }

  @override
  Future<Habit> saveHabit(Habit habit) async {
    await queue.ready;
    await _write(
      UpdateHabit(habit: habit, name: habit.name, queuedAt: _now()),
      () => store.putHabit(habit),
    );
    return habit;
  }

  @override
  Future<void> archiveHabit(String id) async {
    await queue.ready;
    final habit = await store.habit(id);
    // Archived rather than removed, here as on the server: the logs behind a
    // habit are a record of a stretch of someone's life.
    final archived = habit?.copyWith(archived: true);
    await _write(
      ArchiveHabit(habitId: id, name: habit?.name, queuedAt: _now()),
      () async {
        if (archived != null) await store.putHabit(archived);
      },
    );
  }

  @override
  Future<void> reorderHabits(List<String> ids) async {
    await queue.ready;
    await _write(
      ReorderHabits(ids: ids, queuedAt: _now()),
      () => store.putOrder(ids),
    );
  }

  @override
  Future<HabitLog> writeLog(HabitLog log) async {
    await queue.ready;
    await _write(
      WriteHabitLog(log: log, queuedAt: _now()),
      () => store.putLog(log),
    );
    return log;
  }
}
