import 'package:luqa/features/habits/data/habits_repository.dart';
import 'package:luqa/features/habits/domain/habit.dart';

/// A habits repository that lives entirely in memory.
///
/// Stands in for the device's own rows, so a widget test exercises the same
/// path a real one does — write, then read back — without a database or a
/// network anywhere near it.
class FakeHabitsRepository implements HabitsRepository {
  FakeHabitsRepository({
    List<Habit> habits = const [],
    List<HabitLog> logs = const [],
    DateTime? now,
  }) : _habits = [...habits],
       _logs = [...logs],
       _now = now ?? DateTime(2026, 8, 27, 15);

  /// The sample the flow tests read: one of each kind of goal, and one habit
  /// that is not due today at all.
  factory FakeHabitsRepository.sample({DateTime? now}) {
    final at = now ?? DateTime(2026, 8, 27, 15);
    return FakeHabitsRepository(
      now: at,
      habits: [
        _habit(
          'read',
          'Read',
          icon: 'bookOpen',
          order: 0,
        ),
        _habit(
          'water',
          'Water',
          icon: 'droplet',
          order: 1,
          goalType: HabitGoalType.count,
          targetCount: 4,
        ),
        _habit(
          'focus',
          'Deep work',
          icon: 'brain',
          order: 2,
          goalType: HabitGoalType.time,
          targetSeconds: 1800,
        ),
        // Mondays only; 27 August 2026 is a Thursday.
        _habit(
          'stretch',
          'Stretch',
          icon: 'sprout',
          order: 3,
          scheduleType: HabitScheduleType.weekdays,
          weekdays: const [1],
        ),
      ],
      logs: [
        const HabitLog(
          habitId: 'water',
          date: '2026-08-27',
          count: 2,
          seconds: 0,
          runningSince: null,
          completedAt: null,
        ),
      ],
    );
  }

  final List<Habit> _habits;
  final List<HabitLog> _logs;
  final DateTime _now;

  var _minted = 0;

  /// Everything written through this repository, for a test to assert on.
  final List<HabitLog> written = [];

  @override
  Future<List<Habit>> loadHabits() async =>
      [..._habits]..sort((a, b) => a.order.compareTo(b.order));

  @override
  Future<List<HabitLog>> loadLogs({
    required String from,
    required String to,
  }) async => [
    for (final log in _logs)
      if (log.date.compareTo(from) >= 0 && log.date.compareTo(to) <= 0) log,
  ];

  @override
  Future<Habit> createHabit(HabitDraft draft, {String? id}) async {
    final habit = draft.toHabit(
      id: id ?? 'new-${++_minted}',
      order: _habits.where((habit) => !habit.archived).length,
      createdAt: _now,
    );
    _habits.add(habit);
    return habit;
  }

  @override
  Future<Habit> saveHabit(Habit habit) async {
    _habits
      ..removeWhere((existing) => existing.id == habit.id)
      ..add(habit);
    return habit;
  }

  @override
  Future<void> archiveHabit(String id) async {
    final index = _habits.indexWhere((habit) => habit.id == id);
    if (index < 0) return;
    _habits[index] = _habits[index].copyWith(archived: true);
  }

  @override
  Future<void> reorderHabits(List<String> ids) async {
    for (var index = 0; index < ids.length; index++) {
      final at = _habits.indexWhere((habit) => habit.id == ids[index]);
      if (at >= 0) _habits[at] = _habits[at].copyWith(order: index);
    }
  }

  @override
  Future<HabitLog> writeLog(HabitLog log) async {
    written.add(log);
    _logs
      ..removeWhere(
        (existing) =>
            existing.habitId == log.habitId && existing.date == log.date,
      )
      ..add(log);
    return log;
  }
}

Habit _habit(
  String id,
  String name, {
  required int order,
  String? icon,
  HabitGoalType goalType = HabitGoalType.task,
  HabitGoalPeriod goalPeriod = HabitGoalPeriod.day,
  int targetCount = 1,
  int targetSeconds = 0,
  String? categoryId,
  HabitScheduleType scheduleType = HabitScheduleType.daily,
  List<int> weekdays = const [],
}) => Habit(
  id: id,
  name: name,
  icon: icon,
  colorValue: 0xFF6366F1,
  order: order,
  goalType: goalType,
  goalPeriod: goalPeriod,
  targetCount: targetCount,
  targetSeconds: targetSeconds,
  categoryId: categoryId,
  scheduleType: scheduleType,
  weekdays: weekdays,
  weekInterval: 1,
  intervalDays: 2,
  intervalFromLastDone: false,
  timesPerPeriod: 3,
  anchorDate: null,
  dates: const [],
  excludedDates: const [],
  archived: false,
  createdAt: DateTime(2026, 1, 1),
);
