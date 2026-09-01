import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/network/network_failure.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/habits/application/habits_sync_engine.dart';
import 'package:luqa/features/habits/data/habits_providers.dart';
import 'package:luqa/features/habits/data/habits_repository.dart';
import 'package:luqa/features/habits/data/local_first_habits_repository.dart';
import 'package:luqa/features/habits/data/tracked_time.dart';
import 'package:luqa/features/habits/domain/habit.dart';
import 'package:luqa/features/habits/domain/habit_day.dart';
import 'package:luqa/features/habits/domain/habit_schedule.dart';
import 'package:luqa/features/today/application/timeline_controller.dart';
import 'package:luqa/features/today/data/today_providers.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

final habitsControllerProvider =
    NotifierProvider<HabitsController, HabitsState>(HabitsController.new);

/// What the habit screens are looking at.
class HabitsState {
  const HabitsState({
    required this.selectedDate,
    this.habits = const [],
    this.day = const [],
    this.facts = const HabitDayFacts(),
    this.dayStartHour = 3,
    this.weekStartsOn = 1,
    this.isLoading = true,
    this.isRefreshing = false,
    this.isOffline = false,
    this.pendingWrites = 0,
    this.discarded = const [],
    this.error,
  });

  /// The logical day being shown, as a date key.
  final String selectedDate;

  /// Every live habit, in the order they are shown. Archived ones are not
  /// here; nothing on these screens acts on one.
  final List<Habit> habits;

  /// The habits [selectedDate] actually holds, with their progress resolved.
  final List<HabitDay> day;

  /// The rows the day was resolved from, kept so a week strip or an insights
  /// grid can resolve their own days without another round of queries.
  final HabitDayFacts facts;

  final int dayStartHour;
  final int weekStartsOn;

  final bool isLoading;
  final bool isRefreshing;

  /// The last catch-up could not reach the server. What is on screen is this
  /// device's own copy, which is still worth showing.
  final bool isOffline;

  final int pendingWrites;
  final List<DiscardedWrite> discarded;
  final String? error;

  bool get isEmpty => habits.isEmpty;

  HabitDay? dayFor(String habitId) {
    for (final entry in day) {
      if (entry.habit.id == habitId) return entry;
    }
    return null;
  }

  /// How many of the day's habits are done, for the strip's summary.
  int get doneCount => day.where((entry) => entry.done).length;

  HabitsState copyWith({
    String? selectedDate,
    List<Habit>? habits,
    List<HabitDay>? day,
    HabitDayFacts? facts,
    int? dayStartHour,
    int? weekStartsOn,
    bool? isLoading,
    bool? isRefreshing,
    bool? isOffline,
    int? pendingWrites,
    List<DiscardedWrite>? discarded,
    String? error,
    bool clearError = false,
  }) => HabitsState(
    selectedDate: selectedDate ?? this.selectedDate,
    habits: habits ?? this.habits,
    day: day ?? this.day,
    facts: facts ?? this.facts,
    dayStartHour: dayStartHour ?? this.dayStartHour,
    weekStartsOn: weekStartsOn ?? this.weekStartsOn,
    isLoading: isLoading ?? this.isLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isOffline: isOffline ?? this.isOffline,
    pendingWrites: pendingWrites ?? this.pendingWrites,
    discarded: discarded ?? this.discarded,
    error: clearError ? null : error ?? this.error,
  );
}

/// The habits, the day they are being looked at, and everything that can be
/// done to them.
///
/// Every tap is answered from this device: the new state is resolved here,
/// written to the local rows, and queued. Nothing waits for a network, which
/// is the point — habits are ticked on runs, in bed, and underground.
class HabitsController extends Notifier<HabitsState> {
  late HabitsRepository _repository;

  /// The window of logs currently loaded, as date keys.
  String? _loadedFrom;
  String? _loadedTo;

  /// Blocks of tracked time behind the category-linked habits, for the same
  /// window.
  List<TimeEntry> _entries = const [];

  int _generation = 0;

  @override
  HabitsState build() {
    _repository = ref.watch(habitsRepositoryProvider);

    final sync = ref.watch(habitsSyncEngineProvider);
    ref.listen(habitsSyncEngineProvider, (previous, next) {
      // A drain that reached the server may have been answered with rows this
      // device does not have — a habit created here under an id the server
      // replaced, most of all — so the cache is re-read once it lands.
      if (previous?.rounds != next.rounds) unawaited(_reload());
      state = state.copyWith(
        pendingWrites: next.pending,
        discarded: next.discarded,
      );
    });

    final today = dateKeyOf(ref.watch(currentTimeProvider));
    unawaited(_initialise(today));

    return HabitsState(
      selectedDate: today,
      pendingWrites: sync.pending,
      discarded: sync.discarded,
    );
  }

  LocalFirstHabitsRepository? get _localFirst =>
      ref.read(localFirstHabitsRepositoryProvider);

  // --------------------------------------------------------------- loading

  Future<void> _initialise(String dateKey) async {
    await _load(dateKey);
    // The cache paints first; catching up with the server is what happens
    // next, not what the first frame waits for.
    await refresh();
  }

  /// The window a day needs before it can be resolved.
  ///
  /// Wider than the day itself because almost nothing about a habit is about
  /// one day: a yearly quota counts across its year, a monthly duration goal
  /// across its month, and the insights grid across the last four weeks. One
  /// range covering the worst of those is cheaper than four queries that each
  /// cover their own.
  static ({String from, String to}) _windowFor(String dateKey) {
    final date = parseDateKey(dateKey);
    return (
      from: dateKeyOf(DateTime(date.year, 1, 1)),
      // Through the end of the month, so moving a day forward inside it never
      // needs the window reloaded.
      to: dateKeyOf(DateTime(date.year, date.month + 1, 0)),
    );
  }

  bool _covers(String from, String to) =>
      _loadedFrom != null &&
      _loadedTo != null &&
      _loadedFrom!.compareTo(from) <= 0 &&
      _loadedTo!.compareTo(to) >= 0;

  Future<void> _load(String dateKey, {bool force = false}) async {
    final generation = ++_generation;
    final window = _windowFor(dateKey);
    final needsWindow = force || !_covers(window.from, window.to);

    try {
      final habits = await _repository.loadHabits();
      if (!ref.mounted || generation != _generation) return;

      if (needsWindow) {
        final logs = await _repository.loadLogs(
          from: window.from,
          to: window.to,
        );
        if (!ref.mounted || generation != _generation) return;
        _entries = await _trackedEntries(window.from, window.to);
        if (!ref.mounted || generation != _generation) return;
        _loadedFrom = window.from;
        _loadedTo = window.to;
        _cachedLogs = logs;
      }

      _publish(habits: habits, dateKey: dateKey);
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        isLoading: false,
        error: describeNetworkFailure(error, whileDoing: 'loading your habits'),
      );
    }
  }

  List<HabitLog> _cachedLogs = const [];

  /// The blocks behind any category-linked habit, read from the timeline's own
  /// rows rather than from a second copy.
  ///
  /// A linked habit's progress *is* tracked time; keeping a separate tally of
  /// it here would be a second answer to a question that already has one.
  Future<List<TimeEntry>> _trackedEntries(String from, String to) async {
    final store = ref.read(timelineLocalStoreProvider);
    if (store == null) return const [];
    final start = parseDateKey(from);
    final end = parseDateKey(to);
    final window = await store.window(
      DateTime(start.year, start.month, start.day),
      // Exclusive, and a day past the end so a block begun late on the last
      // day of the window is still inside it.
      DateTime(end.year, end.month, end.day + 2),
    );
    return window.entries;
  }

  void _publish({required List<Habit> habits, required String dateKey}) {
    final live = [for (final habit in habits) if (!habit.archived) habit];
    final settings = _localFirst;
    final dayStartHour = settings?.dayStartHour ?? state.dayStartHour;
    final weekStartsOn = settings?.weekStartsOn ?? state.weekStartsOn;

    final facts = habitDayFacts(
      logs: _cachedLogs,
      entries: _entries,
      dayStartHour: dayStartHour,
    );

    state = state.copyWith(
      selectedDate: dateKey,
      habits: live,
      facts: facts,
      day: resolveHabitDay(
        habits: live,
        dateKey: dateKey,
        facts: facts,
        weekStartsOn: weekStartsOn,
      ),
      dayStartHour: dayStartHour,
      weekStartsOn: weekStartsOn,
      isLoading: false,
      clearError: true,
    );
  }

  /// Re-resolves from the rows already loaded. No queries, no network — this
  /// is what a tap is answered with.
  Future<void> _reload() => _load(state.selectedDate);

  /// Catches up with the server, then re-reads this device's rows.
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, isOffline: false);
    // One gesture, one meaning. Sending first means the reload that follows
    // cannot overwrite a local change with an older server copy of it.
    await ref.read(habitsSyncEngineProvider.notifier).sync();
    if (!ref.mounted) return;
    try {
      await _localFirst?.pull();
    } on Object {
      // A catch-up that could not reach the server is not a failure worth
      // clearing the screen for; what is on it is this device's own copy.
      if (!ref.mounted) return;
      state = state.copyWith(isRefreshing: false, isOffline: true);
      return;
    }
    if (!ref.mounted) return;
    await _load(state.selectedDate, force: true);
    if (!ref.mounted) return;
    state = state.copyWith(isRefreshing: false, isOffline: false);
  }

  Future<void> selectDate(String dateKey) async {
    if (dateKey == state.selectedDate) return;
    await _load(dateKey);
  }

  Future<void> acknowledgeDiscarded() =>
      ref.read(habitsSyncEngineProvider.notifier).acknowledgeDiscarded();

  // ---------------------------------------------------------------- writes

  Future<Habit?> createHabit(HabitDraft draft) async {
    try {
      final habit = await _repository.createHabit(draft);
      if (!ref.mounted) return habit;
      await _reload();
      return habit;
    } on Object catch (error) {
      if (ref.mounted) _fail(error, 'saving the habit');
      return null;
    }
  }

  Future<void> saveHabit(Habit habit) async {
    try {
      await _repository.saveHabit(habit);
      if (!ref.mounted) return;
      await _reload();
    } on Object catch (error) {
      if (ref.mounted) _fail(error, 'saving the habit');
    }
  }

  Future<void> archiveHabit(String id) async {
    try {
      await _repository.archiveHabit(id);
      if (!ref.mounted) return;
      await _reload();
    } on Object catch (error) {
      if (ref.mounted) _fail(error, 'archiving the habit');
    }
  }

  Future<void> reorderHabits(List<String> ids) async {
    try {
      await _repository.reorderHabits(ids);
      if (!ref.mounted) return;
      await _reload();
    } on Object catch (error) {
      if (ref.mounted) _fail(error, 'reordering your habits');
    }
  }

  // ------------------------------------------------------------- check-ins

  /// Marks a TASK done, or takes it back.
  Future<void> toggle(String habitId) =>
      _amend(habitId, (habit, log) => log.copyWith(count: log.count >= 1 ? 0 : 1));

  /// Adds one to a COUNT, stopping at the target.
  Future<void> increment(String habitId) => _amend(habitId, (habit, log) {
    final target = habit.targetCount < 1 ? 1 : habit.targetCount;
    return log.copyWith(count: log.count + 1 > target ? target : log.count + 1);
  });

  Future<void> decrement(String habitId) => _amend(
    habitId,
    (habit, log) => log.copyWith(count: log.count < 1 ? 0 : log.count - 1),
  );

  Future<void> setCount(String habitId, int value) =>
      _amend(habitId, (habit, log) {
        final target = habit.targetCount < 1 ? 1 : habit.targetCount;
        return log.copyWith(count: value.clamp(0, target));
      });

  Future<void> addSeconds(String habitId, int seconds) => _amend(
    habitId,
    (habit, log) {
      final total = log.seconds + seconds;
      return log.copyWith(seconds: total < 0 ? 0 : total);
    },
  );

  /// Starts the timer behind a habit.
  ///
  /// A habit linked to a category has no timer of its own: its progress is the
  /// time tracked on that category, so starting it starts a real block on the
  /// timeline. Anything else banks its seconds against the day's log.
  Future<void> startTimer(String habitId) async {
    final habit = _habitById(habitId);
    if (habit == null) return;
    if (habit.isCategoryLinked) {
      await _trackCategory(habit);
      return;
    }
    await _amend(
      habitId,
      (habit, log) => log.isRunning
          ? log
          : log.copyWith(runningSince: () => DateTime.now()),
    );
  }

  Future<void> stopTimer(String habitId) async {
    final habit = _habitById(habitId);
    if (habit == null) return;
    if (habit.isCategoryLinked) {
      await _stopTracking();
      return;
    }
    await _amend(habitId, (habit, log) {
      final since = log.runningSince;
      if (since == null) return log;
      final elapsed = DateTime.now().difference(since).inSeconds;
      return log.copyWith(
        seconds: log.seconds + (elapsed < 0 ? 0 : elapsed),
        runningSince: () => null,
      );
    });
  }

  /// Applies a change to a habit's day, resolves what it means, and queues it.
  ///
  /// The resolved state is what is sent — never the action that produced it.
  /// A queued "add one" replayed after a lost response adds two; the numbers
  /// replayed land on the same numbers.
  Future<void> _amend(
    String habitId,
    HabitLog Function(Habit habit, HabitLog log) amend,
  ) async {
    final habit = _habitById(habitId);
    if (habit == null) return;
    final dateKey = state.selectedDate;
    final existing =
        state.facts.logFor(habitId, dateKey) ??
        HabitLog.empty(habitId, dateKey);

    final amended = amend(habit, existing);
    // Completion is recomputed rather than carried: it is what streaks are
    // counted from, and the server will reach the same answer from the same
    // numbers.
    final done = isGoalMet(
      habit,
      HabitProgress(count: amended.count, seconds: amended.seconds),
    );
    final next = amended.copyWith(
      // The first moment a day was completed stays put once it is known. A
      // seventh glass of water does not re-complete the day.
      completedAt: () => done ? (existing.completedAt ?? DateTime.now()) : null,
    );

    // Shown before it is written, so a tap is answered in the same frame.
    _applyLocally(next);

    try {
      await _repository.writeLog(next);
    } on Object catch (error) {
      if (ref.mounted) _fail(error, 'saving your progress');
    }
  }

  /// Folds a log into the loaded window and re-resolves the day from it.
  void _applyLocally(HabitLog log) {
    _cachedLogs = [
      for (final existing in _cachedLogs)
        if (existing.habitId != log.habitId || existing.date != log.date)
          existing,
      log,
    ];
    _publish(habits: state.habits, dateKey: state.selectedDate);
  }

  Habit? _habitById(String id) {
    for (final habit in state.habits) {
      if (habit.id == id) return habit;
    }
    return null;
  }

  /// Starts a real block against the habit's category.
  ///
  /// Routed through the timeline's own controller rather than written here, so
  /// there is one path that starts a timer in this app. When Today is on
  /// screen the block appears on the grid in the same frame; when it is not,
  /// the write still lands through the same repository and queue.
  Future<void> _trackCategory(Habit habit) async {
    await ref
        .read(timelineControllerProvider.notifier)
        .startTimer(description: habit.name, categoryId: habit.categoryId);
    if (!ref.mounted) return;
    await _load(state.selectedDate, force: true);
  }

  Future<void> _stopTracking() async {
    await ref.read(timelineControllerProvider.notifier).stopTimer();
    if (!ref.mounted) return;
    await _load(state.selectedDate, force: true);
  }

  void _fail(Object error, String whileDoing) {
    state = state.copyWith(
      error: describeNetworkFailure(error, whileDoing: whileDoing),
    );
  }
}
