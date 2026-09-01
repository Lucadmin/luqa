import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/habits/data/habit_json.dart';
import 'package:luqa/features/habits/data/habits_repository.dart';
import 'package:luqa/features/habits/domain/habit.dart';
import 'package:luqa_api/api.dart' as api;

/// The habits, over the network.
///
/// The sync engine and the local-first repository talk to this; screens do
/// not. It has no `loadLogs` of its own worth having — logs arrive through the
/// delta feed rather than by range — so a caller with no cache gets an empty
/// history rather than a page that cannot be asked for.
class RemoteHabitsRepository implements HabitsRepository {
  const RemoteHabitsRepository(this.client);

  final LuqaApi client;

  @override
  Future<List<Habit>> loadHabits() async =>
      (await client.listHabits()).map(habitFromApi).toList(growable: false);

  @override
  Future<List<HabitLog>> loadLogs({
    required String from,
    required String to,
  }) async => const [];

  @override
  Future<Habit> createHabit(HabitDraft draft, {String? id}) async =>
      habitFromApi(
        await client.createHabit(
          api.CreateHabitRequest(
            id: _optional(id),
            name: draft.name,
            icon: api.Optional.present(draft.icon),
            color: api.Optional.present(hexColor(draft.colorValue)),
            goalType: api.Optional.present(goalTypeToApi(draft.goalType)),
            goalPeriod: api.Optional.present(goalPeriodToApi(draft.goalPeriod)),
            targetCount: api.Optional.present(draft.targetCount),
            targetSeconds: api.Optional.present(draft.targetSeconds),
            categoryId: api.Optional.present(
              draft.goalType == HabitGoalType.time ? draft.categoryId : null,
            ),
            scheduleType: api.Optional.present(
              scheduleTypeToApi(draft.scheduleType),
            ),
            weekdays: api.Optional.present(draft.weekdays),
            weekInterval: api.Optional.present(draft.weekInterval),
            intervalDays: api.Optional.present(draft.intervalDays),
            timesPerPeriod: api.Optional.present(draft.timesPerPeriod),
            anchorDate: api.Optional.present(draft.anchorDate),
            dates: api.Optional.present(draft.dates),
            excludedDates: api.Optional.present(draft.excludedDates),
          ),
        ),
      );

  @override
  Future<Habit> saveHabit(Habit habit) async => habitFromApi(
    await client.updateHabit(
      habit.id,
      api.UpdateHabitRequest(
        name: api.Optional.present(habit.name),
        icon: api.Optional.present(habit.icon),
        color: api.Optional.present(hexColor(habit.colorValue)),
        order: api.Optional.present(habit.order),
        goalType: api.Optional.present(goalTypeToApi(habit.goalType)),
        goalPeriod: api.Optional.present(goalPeriodToApi(habit.goalPeriod)),
        targetCount: api.Optional.present(habit.targetCount),
        targetSeconds: api.Optional.present(habit.targetSeconds),
        categoryId: api.Optional.present(habit.categoryId),
        scheduleType: api.Optional.present(
          scheduleTypeToApi(habit.scheduleType),
        ),
        weekdays: api.Optional.present(habit.weekdays),
        weekInterval: api.Optional.present(habit.weekInterval),
        intervalDays: api.Optional.present(habit.intervalDays),
        timesPerPeriod: api.Optional.present(habit.timesPerPeriod),
        anchorDate: api.Optional.present(habit.anchorDate),
        dates: api.Optional.present(habit.dates),
        excludedDates: api.Optional.present(habit.excludedDates),
        archived: api.Optional.present(habit.archived),
      ),
    ),
  );

  @override
  Future<void> archiveHabit(String id) => client.archiveHabit(id);

  @override
  Future<void> reorderHabits(List<String> ids) async {
    await client.reorderHabits(ids);
  }

  @override
  Future<HabitLog> writeLog(HabitLog log) async => habitLogFromApi(
    await client.putHabitLog(
      log.habitId,
      log.date,
      api.PutHabitLogRequest(
        count: log.count,
        seconds: log.seconds,
        runningSince: api.Optional.present(log.runningSince?.toUtc()),
      ),
    ),
  );
}

api.Optional<String> _optional(String? value) => value == null
    ? const api.Optional.absent()
    : api.Optional.present(value);
