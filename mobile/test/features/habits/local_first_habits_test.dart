import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/core/storage/luqa_store.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/habits/data/habits_local_store.dart';
import 'package:luqa/features/habits/data/habits_outbox.dart';
import 'package:luqa/features/habits/data/habits_repository.dart';
import 'package:luqa/features/habits/data/habits_sync_service.dart';
import 'package:luqa/features/habits/data/local_first_habits_repository.dart';
import 'package:luqa/features/habits/domain/habit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _TestQueue implements MutationQueue<HabitMutation> {
  List<HabitMutation> _queue = const [];

  @override
  Future<void> get ready async {}

  @override
  List<HabitMutation> get pending => _queue;

  /// Nothing is ever sent in these tests; the queue is only here so a write
  /// has somewhere to go.
  @override
  Future<void> sync() async {}

  @override
  Future<void> enqueue(HabitMutation mutation, {bool sendNow = true}) async {
    _queue = foldHabits(_queue, mutation);
  }
}

/// A network that is never reached: every read in these tests is answered from
/// the device, which is the claim being tested.
class _UnreachableApi implements LuqaApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final _now = DateTime(2026, 3, 11, 9);

HabitDraft draft({
  String name = 'Read',
  HabitGoalType goalType = HabitGoalType.task,
  HabitGoalPeriod goalPeriod = HabitGoalPeriod.day,
  int targetCount = 1,
  int targetSeconds = 0,
  String? categoryId,
}) => HabitDraft(
  name: name,
  icon: 'bookOpen',
  colorValue: 0xFFF5C451,
  goalType: goalType,
  goalPeriod: goalPeriod,
  targetCount: targetCount,
  targetSeconds: targetSeconds,
  categoryId: categoryId,
  scheduleType: HabitScheduleType.daily,
  weekdays: const [],
  weekInterval: 1,
  intervalDays: 2,
  timesPerPeriod: 3,
  anchorDate: null,
  dates: const [],
  excludedDates: const [],
);

void main() {
  sqfliteFfiInit();

  late LuqaStore store;
  late HabitsLocalStore local;
  late _TestQueue queue;
  late LocalFirstHabitsRepository repository;
  var minted = 0;

  setUp(() {
    store = LuqaStore(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    addTearDown(store.close);
    local = HabitsLocalStore(namespace: 'user-1', store: store);
    queue = _TestQueue();
    minted = 0;
    repository = LocalFirstHabitsRepository(
      store: local,
      sync: HabitsSyncService(client: _UnreachableApi(), store: local),
      queue: queue,
      mintId: () => 'local-${++minted}',
      now: () => _now,
    );
  });

  test('a habit created offline is readable straight away', () async {
    final created = await repository.createHabit(draft());

    expect(created.id, 'local-1');
    final habits = await repository.loadHabits();
    expect(habits.map((habit) => habit.name), ['Read']);
    expect(queue.pending.single, isA<CreateHabit>());
  });

  test('a new habit lands at the bottom of the list', () async {
    await repository.createHabit(draft(name: 'One'));
    await repository.createHabit(draft(name: 'Two'));
    await repository.createHabit(draft(name: 'Three'));

    final habits = await repository.loadHabits();
    expect(habits.map((habit) => habit.name), ['One', 'Two', 'Three']);
    expect(habits.map((habit) => habit.order), [0, 1, 2]);
  });

  test('every part of a habit survives the round trip to disk', () async {
    final created = await repository.createHabit(
      draft(
        name: 'Exercise',
        goalType: HabitGoalType.time,
        goalPeriod: HabitGoalPeriod.week,
        targetSeconds: 5400,
        categoryId: 'fitness',
      ),
    );

    final stored = (await repository.loadHabits()).single;
    expect(stored.id, created.id);
    expect(stored.goalType, HabitGoalType.time);
    expect(stored.goalPeriod, HabitGoalPeriod.week);
    expect(stored.targetSeconds, 5400);
    expect(stored.categoryId, 'fitness');
    expect(stored.icon, 'bookOpen');
  });

  test('a category link is dropped when the goal is not a duration', () async {
    // The editor can be left with a stale link after switching goal type; the
    // draft is what decides, not what the fields happened to hold.
    final created = await repository.createHabit(
      draft(goalType: HabitGoalType.count, categoryId: 'fitness'),
    );
    expect(created.categoryId, isNull);
    expect(created.goalPeriod, HabitGoalPeriod.day);
  });

  test('progress written offline is readable offline', () async {
    final habit = await repository.createHabit(
      draft(goalType: HabitGoalType.count, targetCount: 4),
    );
    await repository.writeLog(
      HabitLog(
        habitId: habit.id,
        date: '2026-03-11',
        count: 3,
        seconds: 0,
        runningSince: null,
        completedAt: null,
      ),
    );

    final logs = await repository.loadLogs(
      from: '2026-03-01',
      to: '2026-03-31',
    );
    expect(logs.single.count, 3);
    expect(logs.single.date, '2026-03-11');
  });

  test('logs outside the range asked for are not returned', () async {
    final habit = await repository.createHabit(draft());
    for (final date in ['2026-02-28', '2026-03-11', '2026-04-01']) {
      await repository.writeLog(
        HabitLog(
          habitId: habit.id,
          date: date,
          count: 1,
          seconds: 0,
          runningSince: null,
          completedAt: null,
        ),
      );
    }

    final logs = await repository.loadLogs(
      from: '2026-03-01',
      to: '2026-03-31',
    );
    expect(logs.map((log) => log.date), ['2026-03-11']);
  });

  test('archiving keeps the habit and its logs, out of the live list', () async {
    final habit = await repository.createHabit(draft());
    await repository.writeLog(
      HabitLog(
        habitId: habit.id,
        date: '2026-03-11',
        count: 1,
        seconds: 0,
        runningSince: null,
        completedAt: _now,
      ),
    );

    await repository.archiveHabit(habit.id);

    final habits = await repository.loadHabits();
    expect(habits.single.archived, isTrue);
    // The record of what was done is not what was archived.
    final logs = await repository.loadLogs(
      from: '2026-03-01',
      to: '2026-03-31',
    );
    expect(logs, hasLength(1));
  });

  test('a reorder is reflected in the next read', () async {
    final one = await repository.createHabit(draft(name: 'One'));
    final two = await repository.createHabit(draft(name: 'Two'));

    await repository.reorderHabits([two.id, one.id]);

    final habits = await repository.loadHabits();
    expect(habits.map((habit) => habit.name), ['Two', 'One']);
  });

  test('a delta does not overwrite a write this device has not sent', () async {
    final habit = await repository.createHabit(draft(name: 'Read'));

    // The server's copy is older: it has not seen the rename yet.
    await local.applyHabits([habit.copyWith(name: 'Stale')]);

    expect((await repository.loadHabits()).single.name, 'Read');
  });

  test('a delta lands once the local write has been acknowledged', () async {
    final habit = await repository.createHabit(draft(name: 'Read'));
    await local.settleHabit(habit.id);

    await local.applyHabits([habit.copyWith(name: 'Read more')]);

    expect((await repository.loadHabits()).single.name, 'Read more');
  });

  test('an id the server replaced is repointed, logs and all', () async {
    final habit = await repository.createHabit(draft());
    await repository.writeLog(
      HabitLog(
        habitId: habit.id,
        date: '2026-03-11',
        count: 1,
        seconds: 0,
        runningSince: null,
        completedAt: null,
      ),
    );

    await local.remapHabit(habit.id, 'server-1');

    expect((await repository.loadHabits()).single.id, 'server-1');
    final logs = await repository.loadLogs(
      from: '2026-03-01',
      to: '2026-03-31',
    );
    expect(logs.single.habitId, 'server-1');
  });

  test('another account\'s habits are never read back', () async {
    await repository.createHabit(draft());

    final other = HabitsLocalStore(namespace: 'user-2', store: store);
    expect(await other.habits(), isEmpty);
    expect(await other.logsBetween('2026-01-01', '2026-12-31'), isEmpty);
  });
}
