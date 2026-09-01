import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/habits/data/habit_json.dart';
import 'package:luqa/features/habits/domain/habit.dart';

/// The writes habits can make while offline.
///
/// Check-ins are the high-frequency half of this and the reason the queue
/// exists at all: tapping a habit four times on a train is one request by the
/// time there is a network, because a log is sent as the day's state rather
/// than as four increments.
sealed class HabitMutation implements PendingMutation {
  const HabitMutation({required this.queuedAt});

  @override
  final DateTime queuedAt;

  /// Named the way the user would name it, because this is only ever read
  /// when they are being told the change did not survive.
  @override
  String describe() => switch (this) {
    CreateHabit(:final habit) => 'the habit ${habit.name}',
    UpdateHabit(:final name) => 'your edit to ${name ?? 'a habit'}',
    ArchiveHabit(:final name) => 'archiving ${name ?? 'a habit'}',
    ReorderHabits() => 'the order of your habits',
    WriteHabitLog(:final log) => "${log.date}'s progress",
  };

  static HabitMutation? fromJson(Map<String, Object?> json) {
    final queuedAt = DateTime.tryParse(json['queuedAt'] as String? ?? '');
    if (queuedAt == null) return null;
    return switch (json['op']) {
      'createHabit' => CreateHabit(
        habit: habitFromJson(json['habit']! as Map<String, Object?>),
        queuedAt: queuedAt,
      ),
      'updateHabit' => UpdateHabit(
        habit: habitFromJson(json['habit']! as Map<String, Object?>),
        name: json['name'] as String?,
        queuedAt: queuedAt,
      ),
      'archiveHabit' => ArchiveHabit(
        habitId: json['habitId']! as String,
        name: json['name'] as String?,
        queuedAt: queuedAt,
      ),
      'reorderHabits' => ReorderHabits(
        ids: [for (final id in json['ids']! as List<Object?>) id! as String],
        queuedAt: queuedAt,
      ),
      'writeHabitLog' => WriteHabitLog(
        log: _logFromJson(json['log']! as Map<String, Object?>),
        queuedAt: queuedAt,
      ),
      // An op written by a newer build is not something this one can replay.
      _ => null,
    };
  }
}

final class CreateHabit extends HabitMutation {
  const CreateHabit({required this.habit, required super.queuedAt});

  final Habit habit;

  @override
  String get subjectId => habit.id;

  @override
  Map<String, Object?> toJson() => {
    'op': 'createHabit',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'habit': habitToJson(habit),
  };
}

/// A habit as the user has just left it.
///
/// The whole row rather than the fields that changed. A habit is edited in one
/// sheet and saved once, so there is nothing a field-level patch would buy —
/// and sending the whole thing means the newest save simply replaces any
/// earlier one still in the queue.
final class UpdateHabit extends HabitMutation {
  const UpdateHabit({
    required this.habit,
    required this.name,
    required super.queuedAt,
  });

  final Habit habit;

  /// What it was called when the edit was made, for the discard notice. Taken
  /// at queue time because by the time anyone reads it the habit may be gone.
  final String? name;

  @override
  String get subjectId => habit.id;

  @override
  Map<String, Object?> toJson() => {
    'op': 'updateHabit',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'habit': habitToJson(habit),
    'name': name,
  };
}

final class ArchiveHabit extends HabitMutation {
  const ArchiveHabit({
    required this.habitId,
    required this.name,
    required super.queuedAt,
  });

  final String habitId;
  final String? name;

  @override
  String get subjectId => habitId;

  @override
  Map<String, Object?> toJson() => {
    'op': 'archiveHabit',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'habitId': habitId,
    'name': name,
  };
}

/// The whole ordering, not one habit's new position — so a replay restates the
/// order instead of shuffling it again.
final class ReorderHabits extends HabitMutation {
  const ReorderHabits({required this.ids, required super.queuedAt});

  final List<String> ids;

  /// One ordering at a time, whichever habits it names.
  @override
  String get subjectId => 'order';

  @override
  Map<String, Object?> toJson() => {
    'op': 'reorderHabits',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'ids': ids,
  };
}

/// A day's progress, as state rather than as an action.
///
/// This is what makes a check-in safe to queue. "Increment" replayed after a
/// lost response adds two; the numbers replayed land on the numbers.
final class WriteHabitLog extends HabitMutation {
  const WriteHabitLog({required this.log, required super.queuedAt});

  final HabitLog log;

  @override
  String get subjectId => '${log.habitId}|${log.date}';

  @override
  Map<String, Object?> toJson() => {
    'op': 'writeHabitLog',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'log': _logToJson(log),
  };
}

Map<String, Object?> _logToJson(HabitLog log) => {
  'habitId': log.habitId,
  'date': log.date,
  'count': log.count,
  'seconds': log.seconds,
  'runningSince': log.runningSince?.toUtc().toIso8601String(),
  'completedAt': log.completedAt?.toUtc().toIso8601String(),
};

HabitLog _logFromJson(Map<String, Object?> json) => HabitLog(
  habitId: json['habitId']! as String,
  date: json['date']! as String,
  count: json['count']! as int,
  seconds: json['seconds']! as int,
  runningSince: _instant(json['runningSince']),
  completedAt: _instant(json['completedAt']),
);

DateTime? _instant(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toLocal();

/// Appends [next], folding it into what is already queued for the same row.
List<HabitMutation> foldHabits(
  List<HabitMutation> queue,
  HabitMutation next,
) {
  switch (next) {
    case WriteHabitLog(:final log):
      // Four taps on one habit are one request. The newest state supersedes
      // every earlier one for the same habit and day, which is exactly what
      // makes tapping a counter feel free.
      return _replaceOrAppend(
        queue,
        next,
        (pending) =>
            pending is WriteHabitLog &&
            pending.log.habitId == log.habitId &&
            pending.log.date == log.date,
      );

    case UpdateHabit(:final habit):
      // An edit to a habit that has not been created yet belongs *in* the
      // create: sending a patch for a row the server has never seen would be
      // refused, and the create already carries every field the patch does.
      final folded = <HabitMutation>[];
      var absorbed = false;
      for (final pending in queue) {
        switch (pending) {
          case CreateHabit(habit: final queued) when queued.id == habit.id:
            folded.add(CreateHabit(habit: habit, queuedAt: pending.queuedAt));
            absorbed = true;
          case UpdateHabit(habit: final queued) when queued.id == habit.id:
            folded.add(
              UpdateHabit(
                habit: habit,
                name: next.name,
                queuedAt: pending.queuedAt,
              ),
            );
            absorbed = true;
          case _:
            folded.add(pending);
        }
      }
      return absorbed ? folded : [...folded, next];

    case ArchiveHabit(:final habitId):
      // Archiving something this device made and has not sent yet drops the
      // create as well: there is nothing for the server to be told about.
      final survivors = [
        for (final pending in queue)
          if (!(pending is CreateHabit && pending.habit.id == habitId) &&
              !(pending is UpdateHabit && pending.habit.id == habitId))
            pending,
      ];
      final wasUnsentCreate = queue.any(
        (pending) => pending is CreateHabit && pending.habit.id == habitId,
      );
      return wasUnsentCreate ? survivors : [...survivors, next];

    case ReorderHabits():
      // Only the latest ordering matters; the ones before it are states the
      // list passed through, not states the server needs to be walked through.
      return _replaceOrAppend(
        queue,
        next,
        (pending) => pending is ReorderHabits,
      );

    case CreateHabit():
      return [...queue, next];
  }
}

/// Replaces the queued mutation [matches] finds with [next], keeping its place
/// in the queue, or appends [next] when there is nothing to replace.
///
/// Keeping the place matters: the order writes are replayed in is the order
/// they happened in, and a superseded write must not be able to jump the
/// create it depends on.
List<HabitMutation> _replaceOrAppend(
  List<HabitMutation> queue,
  HabitMutation next,
  bool Function(HabitMutation pending) matches,
) {
  final folded = <HabitMutation>[];
  var absorbed = false;
  for (final pending in queue) {
    if (matches(pending)) {
      folded.add(_withQueuedAt(next, pending.queuedAt));
      absorbed = true;
    } else {
      folded.add(pending);
    }
  }
  return absorbed ? folded : [...folded, next];
}

HabitMutation _withQueuedAt(HabitMutation mutation, DateTime queuedAt) =>
    switch (mutation) {
      CreateHabit(:final habit) => CreateHabit(
        habit: habit,
        queuedAt: queuedAt,
      ),
      UpdateHabit(:final habit, :final name) => UpdateHabit(
        habit: habit,
        name: name,
        queuedAt: queuedAt,
      ),
      ArchiveHabit(:final habitId, :final name) => ArchiveHabit(
        habitId: habitId,
        name: name,
        queuedAt: queuedAt,
      ),
      ReorderHabits(:final ids) => ReorderHabits(
        ids: ids,
        queuedAt: queuedAt,
      ),
      WriteHabitLog(:final log) => WriteHabitLog(
        log: log,
        queuedAt: queuedAt,
      ),
    };

/// Repoints a queue at the id the server chose, when it did not accept the one
/// this device invented.
List<HabitMutation> remapHabitId(
  List<HabitMutation> queue,
  String from,
  String to,
) {
  if (from == to) return queue;
  return [
    for (final pending in queue)
      switch (pending) {
        CreateHabit(:final habit) when habit.id == from => CreateHabit(
          habit: _reidentify(habit, to),
          queuedAt: pending.queuedAt,
        ),
        UpdateHabit(:final habit, :final name) when habit.id == from =>
          UpdateHabit(
            habit: _reidentify(habit, to),
            name: name,
            queuedAt: pending.queuedAt,
          ),
        ArchiveHabit(:final habitId, :final name) when habitId == from =>
          ArchiveHabit(habitId: to, name: name, queuedAt: pending.queuedAt),
        ReorderHabits(:final ids) when ids.contains(from) => ReorderHabits(
          ids: [for (final id in ids) id == from ? to : id],
          queuedAt: pending.queuedAt,
        ),
        WriteHabitLog(:final log) when log.habitId == from => WriteHabitLog(
          log: HabitLog(
            habitId: to,
            date: log.date,
            count: log.count,
            seconds: log.seconds,
            runningSince: log.runningSince,
            completedAt: log.completedAt,
          ),
          queuedAt: pending.queuedAt,
        ),
        _ => pending,
      },
  ];
}

Habit _reidentify(Habit habit, String id) => Habit(
  id: id,
  name: habit.name,
  icon: habit.icon,
  colorValue: habit.colorValue,
  order: habit.order,
  goalType: habit.goalType,
  goalPeriod: habit.goalPeriod,
  targetCount: habit.targetCount,
  targetSeconds: habit.targetSeconds,
  categoryId: habit.categoryId,
  scheduleType: habit.scheduleType,
  weekdays: habit.weekdays,
  weekInterval: habit.weekInterval,
  intervalDays: habit.intervalDays,
  timesPerPeriod: habit.timesPerPeriod,
  anchorDate: habit.anchorDate,
  dates: habit.dates,
  excludedDates: habit.excludedDates,
  archived: habit.archived,
  createdAt: habit.createdAt,
);

/// The habits feature's durable queue.
class SqliteHabitsOutbox extends SqliteOutbox<HabitMutation> {
  SqliteHabitsOutbox({required super.namespace, super.store})
    : super(key: 'habits', decode: HabitMutation.fromJson);
}
