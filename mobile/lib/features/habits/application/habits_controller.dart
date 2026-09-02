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
    required this.todayDate,
    required this.stripDate,
    this.habits = const [],
    this.day = const [],
    this.stripDay = const [],
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

  /// The logical day the habits screen is showing, as a date key.
  final String selectedDate;

  /// Today, whatever day either screen has been left on.
  final String todayDate;

  /// The logical day the strip above the timeline is showing — the day the
  /// timeline itself is scrolled to.
  ///
  /// A third axis rather than a second use of [selectedDate], because the two
  /// screens browse independently: the habits screen being left on last Monday
  /// must not decide what the timeline's row shows, and vice versa.
  final String stripDate;

  /// Every live habit, in the order they are shown. Archived ones are not
  /// here; nothing on these screens acts on one.
  final List<Habit> habits;

  /// The habits [selectedDate] actually holds, with their progress resolved.
  final List<HabitDay> day;

  /// The same for [stripDate].
  final List<HabitDay> stripDay;

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

  /// How many of the strip day's habits are done, for its summary ring.
  int get stripDoneCount => stripDay.where((entry) => entry.done).length;

  /// Whether the strip is showing today, or a day the timeline was scrolled to.
  bool get stripIsToday => stripDate == todayDate;

  HabitsState copyWith({
    String? selectedDate,
    String? todayDate,
    String? stripDate,
    List<Habit>? habits,
    List<HabitDay>? day,
    List<HabitDay>? stripDay,
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
    todayDate: todayDate ?? this.todayDate,
    stripDate: stripDate ?? this.stripDate,
    habits: habits ?? this.habits,
    day: day ?? this.day,
    stripDay: stripDay ?? this.stripDay,
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

  /// Today, as a date key. Held here as well as in the state because the
  /// first load starts before `build` has returned a state to read it from.
  late String _today;

  /// The day the timeline's strip is showing. Same reason as [_today]: the
  /// first load has to know what to cover before there is a state to ask.
  late String _stripDate;

  /// The window of logs currently loaded, as date keys.
  String? _loadedFrom;
  String? _loadedTo;

  /// Widening the window for a day scrolled to is debounced: a fling across
  /// the timeline crosses every day between here and there, and none of the
  /// ones passed over is worth a round of queries.
  Timer? _windowDebounce;
  static const _windowSettleDelay = Duration(milliseconds: 250);

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
      // replaced, most of all — so the whole window is re-read once it lands,
      // logs included: a remap moves those too.
      if (previous?.rounds != next.rounds) {
        unawaited(_load(state.selectedDate, force: true));
      }
      state = state.copyWith(
        pendingWrites: next.pending,
        discarded: next.discarded,
      );
    });

    ref.onDispose(() => _windowDebounce?.cancel());

    // Three in the morning is the server's default day start, and the right
    // guess until a sync reports what this account actually uses.
    _today = logicalDateKey(ref.watch(currentTimeProvider), 3);
    _stripDate = _today;
    unawaited(_initialise(_today));

    return HabitsState(
      selectedDate: _today,
      todayDate: _today,
      stripDate: _today,
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

  /// The window the loaded habits need before a day can be resolved.
  ///
  /// Wider than the day itself, because almost nothing about a habit is about
  /// one day: a monthly duration goal counts across its month, the insights
  /// grid across the last four weeks, and the week strip across its week. One
  /// range covering the worst of those is cheaper than four queries that each
  /// cover their own.
  ///
  /// Today is always inside it, whatever day is being browsed, because the
  /// insights grid is counted from today whichever screen asked.
  ///
  /// Every day on screen anywhere is an anchor: the habits screen's selected
  /// day, the day the timeline's strip is scrolled to, and today. All three
  /// browse independently, and one window covering the lot is cheaper than
  /// reloading whenever the active screen changes.
  ///
  /// A yearly quota is the one thing that needs a year, so it is the one thing
  /// that gets one. Loading twelve months of history for an account whose
  /// habits are all daily would be paying a rare case's price on every screen.
  static ({String from, String to}) _windowFor(
    List<String> anchors,
    String today,
    List<Habit> habits,
  ) {
    final dates = [for (final key in anchors) parseDateKey(key)];
    final yearly = habits.any(
      (habit) => habit.scheduleType == HabitScheduleType.timesPerYear,
    );

    final starts = [
      // Far enough back for the insights grid, which counts four weeks from
      // today rather than from whatever day is on screen.
      addDaysToKey(today, -35),
      for (final date in dates) dateKeyOf(DateTime(date.year, date.month, 1)),
      if (yearly)
        for (final date in dates) dateKeyOf(DateTime(date.year, 1, 1)),
    ];
    final ends = [
      // Through the end of the month, so moving a day forward inside it never
      // needs the window reloaded.
      for (final date in dates)
        dateKeyOf(DateTime(date.year, date.month + 1, 0)),
      if (yearly)
        for (final date in dates) dateKeyOf(DateTime(date.year, 12, 31)),
    ];

    starts.sort();
    ends.sort();

    // A rolling interval decides its first day from the days before it, so the
    // window needs a run-up of its own — bounded by the longest interval in
    // play, which is the most any of them can look back.
    final lookback = habits.fold(
      0,
      (widest, habit) =>
          habit.rollingLookbackDays > widest ? habit.rollingLookbackDays : widest,
    );
    return (
      from: lookback == 0 ? starts.first : addDaysToKey(starts.first, -lookback),
      to: ends.last,
    );
  }

  bool _covers(String from, String to) =>
      _loadedFrom != null &&
      _loadedTo != null &&
      _loadedFrom!.compareTo(from) <= 0 &&
      _loadedTo!.compareTo(to) >= 0;

  Future<void> _load(String dateKey, {bool force = false}) async {
    final generation = ++_generation;

    try {
      // The habits decide how far back the window has to reach, so they are
      // read before it is worked out rather than alongside it.
      final habits = await _repository.loadHabits();
      if (!ref.mounted || generation != _generation) return;

      final window = _windowFor([dateKey, _today, _stripDate], _today, habits);
      if (force || !_covers(window.from, window.to)) {
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
  ///
  /// Two sources for one answer, and they are not redundant. The store holds
  /// the whole window — which can be a month or a year, far more than the three
  /// weeks the timeline keeps in memory. [_liveEntries] holds what the timeline
  /// is showing right now, including a block saved a moment ago. The store is
  /// the base and the live rows are laid over it by id, so a block created a
  /// second ago counts immediately and one from last March still counts at all.
  Future<List<TimeEntry>> _trackedEntries(String from, String to) async {
    final start = parseDateKey(from);
    final end = parseDateKey(to);
    // Exclusive, and a day past the end so a block begun late on the last day
    // of the window is still inside it.
    final until = DateTime(end.year, end.month, end.day + 2);
    final since = DateTime(start.year, start.month, start.day);

    final store = ref.read(timelineLocalStoreProvider);
    final stored = store == null
        ? const <TimeEntry>[]
        : (await store.window(since, until)).entries;

    final byId = {
      for (final entry in stored) entry.id: entry,
      for (final entry in _liveEntries)
        if (!entry.start.isBefore(since) && entry.start.isBefore(until))
          entry.id: entry,
    };
    return byId.values.toList(growable: false);
  }

  /// What the timeline is currently showing, pushed in rather than read.
  ///
  /// Read from here it would have to come through the timeline's own provider,
  /// which is autoDispose: asking it for its entries while nobody is looking at
  /// the timeline would build it back up and set it loading, for an answer the
  /// store already has. The screen that owns both hands them over instead.
  List<TimeEntry> _liveEntries = const [];

  /// Re-resolves the tracked time behind category-linked habits from the blocks
  /// the timeline is showing.
  ///
  /// What the timeline does to a block changes what those habits have achieved,
  /// immediately — a "two hours of focus" habit is a claim about the blocks on
  /// screen, and a claim that only caught up on the next sync round would be
  /// wrong for exactly as long as somebody was watching it.
  ///
  /// No habit query, no log query, no network: only the rows that changed.
  Future<void> syncTrackedTime(List<TimeEntry> entries) async {
    _liveEntries = entries;
    final from = _loadedFrom;
    final to = _loadedTo;
    if (from == null || to == null) return;
    final generation = _generation;
    final tracked = await _trackedEntries(from, to);
    // A load in flight is about to publish a fresher answer than this one.
    if (!ref.mounted || generation != _generation) return;
    _entries = tracked;
    _publish(habits: state.habits, dateKey: state.selectedDate);
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

    List<HabitDay> resolve(String key) => resolveHabitDay(
      habits: live,
      dateKey: key,
      facts: facts,
      weekStartsOn: weekStartsOn,
    );

    // Recomputed rather than fixed at build: the account's own day start
    // arrives with the first sync, and three in the morning is only the guess
    // made before it. Read through the shared clock, so a test that pins the
    // date gets the day it pinned.
    _today = logicalDateKey(ref.read(currentTimeProvider), dayStartHour);
    final todayDate = _today;
    final day = resolve(dateKey);

    state = state.copyWith(
      selectedDate: dateKey,
      todayDate: todayDate,
      stripDate: _stripDate,
      habits: live,
      facts: facts,
      day: day,
      stripDay: _stripDate == dateKey ? day : resolve(_stripDate),
      dayStartHour: dayStartHour,
      weekStartsOn: weekStartsOn,
      isLoading: false,
      clearError: true,
    );
  }

  /// The timeline has scrolled onto another day, so the strip moves with it.
  ///
  /// [day] is a logical day the timeline has already resolved — midnight of the
  /// day it belongs to, not a wall-clock instant inside it — so it is named
  /// directly rather than put back through [logicalDateKey], which would push
  /// every day one earlier by reading that midnight as the small hours of the
  /// day before.
  ///
  /// Answered from the facts already held rather than through [_publish],
  /// which would rebuild the whole window's fact maps. The timeline reports
  /// every day boundary it crosses, so a fling across a month would rebuild
  /// them dozens of times over for an answer that never needed them rebuilt.
  void viewStripDay(DateTime day) {
    final dateKey = dateKeyOf(day);
    if (dateKey == _stripDate) return;
    _stripDate = dateKey;
    state = state.copyWith(
      stripDate: dateKey,
      stripDay: resolveHabitDay(
        habits: state.habits,
        dateKey: dateKey,
        facts: state.facts,
        weekStartsOn: state.weekStartsOn,
      ),
    );

    // Scrolled clean out of what is loaded — off the end of the month, most
    // likely. Widen once the scrolling stops rather than at every day passed.
    _windowDebounce?.cancel();
    _windowDebounce = Timer(_windowSettleDelay, () {
      if (!ref.mounted) return;
      final window = _windowFor(
        [state.selectedDate, _today, _stripDate],
        _today,
        state.habits,
      );
      if (_covers(window.from, window.to)) return;
      unawaited(_load(state.selectedDate));
    });
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
  //
  // Every one of these names the day it acts on. The strip on Today and the
  // habits screen are looking at different days whenever the screen has been
  // browsed back through the week, and a tap has to land on the day the person
  // tapping it can see — not on whichever was selected last.

  /// Marks a TASK done, or takes it back.
  Future<void> toggle(String habitId, {required String dateKey}) => _amend(
    habitId,
    dateKey,
    (habit, log) => log.copyWith(count: log.count >= 1 ? 0 : 1),
  );

  /// Adds one to a COUNT, stopping at the target.
  Future<void> increment(String habitId, {required String dateKey}) =>
      _amend(habitId, dateKey, (habit, log) {
        final target = habit.targetCount < 1 ? 1 : habit.targetCount;
        return log.copyWith(
          count: log.count + 1 > target ? target : log.count + 1,
        );
      });

  Future<void> decrement(String habitId, {required String dateKey}) => _amend(
    habitId,
    dateKey,
    (habit, log) => log.copyWith(count: log.count < 1 ? 0 : log.count - 1),
  );

  /// Starts the timer behind a habit.
  ///
  /// A habit linked to a category has no timer of its own: its progress is the
  /// time tracked on that category, so starting it starts a real block on the
  /// timeline. Anything else banks its seconds against the day's log.
  Future<void> startTimer(String habitId, {required String dateKey}) async {
    final habit = _habitById(habitId);
    if (habit == null) return;
    if (habit.isCategoryLinked) {
      await _trackCategory(habit);
      return;
    }
    await _amend(
      habitId,
      dateKey,
      (habit, log) => log.isRunning
          ? log
          : log.copyWith(runningSince: () => DateTime.now()),
    );
  }

  Future<void> stopTimer(String habitId, {required String dateKey}) async {
    final habit = _habitById(habitId);
    if (habit == null) return;
    if (habit.isCategoryLinked) {
      await _stopTracking();
      return;
    }
    await _amend(habitId, dateKey, (habit, log) {
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
    String dateKey,
    HabitLog Function(Habit habit, HabitLog log) amend,
  ) async {
    final habit = _habitById(habitId);
    if (habit == null) return;
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
    // Already holding the timeline, so its rows come straight back with us.
    await syncTrackedTime(ref.read(timelineControllerProvider).entries);
  }

  Future<void> _stopTracking() async {
    await ref.read(timelineControllerProvider.notifier).stopTimer();
    if (!ref.mounted) return;
    await syncTrackedTime(ref.read(timelineControllerProvider).entries);
  }

  void _fail(Object error, String whileDoing) {
    state = state.copyWith(
      error: describeNetworkFailure(error, whileDoing: whileDoing),
    );
  }
}
