import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/today/data/remote_today_repository.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa/features/today/domain/timeline_geometry.dart';

final todayRepositoryProvider = Provider<TodayRepository>((ref) {
  final userId = ref.watch(authControllerProvider).value?.user?.id;
  return RemoteTodayRepository(
    client: ref.watch(luqaApiProvider),
    cache: SharedPreferencesTimelineCache(namespace: userId ?? 'signed-out'),
  );
});

/// The clock the screen opens on. Overridden in tests so every date-dependent
/// widget is deterministic.
final currentTimeProvider = Provider<DateTime>((ref) => DateTime.now());

final timelineControllerProvider =
    NotifierProvider.autoDispose<TimelineController, TimelineState>(
      TimelineController.new,
    );

/// A block being created or reshaped directly on the grid. It floats above the
/// timeline until it is saved, so dragging it never disturbs the entries
/// underneath.
class TimelineDraft {
  const TimelineDraft({
    required this.start,
    required this.end,
    this.entryId,
    this.description = '',
    this.categoryId,
  });

  /// Set while an existing entry is being reshaped in place.
  final String? entryId;
  final DateTime start;
  final DateTime end;
  final String description;
  final String? categoryId;

  bool get isNew => entryId == null;

  Duration get duration => end.difference(start);

  TimelineDraft copyWith({
    DateTime? start,
    DateTime? end,
    String? description,
    String? categoryId,
    bool clearCategory = false,
  }) => TimelineDraft(
    entryId: entryId,
    start: start ?? this.start,
    end: end ?? this.end,
    description: description ?? this.description,
    categoryId: clearCategory ? null : categoryId ?? this.categoryId,
  );
}

class TimelineState {
  const TimelineState({
    required this.visibleDay,
    required this.windowFrom,
    required this.windowTo,
    required this.entries,
    required this.sleep,
    required this.categories,
    this.draft,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isOffline = false,
    this.isSaving = false,
    this.error,
  });

  factory TimelineState.initial(DateTime now) {
    final day = startOfLogicalDay(now);
    final from = windowFromFor(day);
    return TimelineState(
      visibleDay: day,
      windowFrom: from,
      windowTo: addDays(from, windowDays),
      entries: const [],
      sleep: const [],
      categories: const [],
      isLoading: true,
    );
  }

  static const windowDays = 21;

  /// Three weeks of data, quantised to whole weeks, so the window key only
  /// changes every seventh day of scrolling and always keeps a week of slack
  /// on either side of the screen.
  static DateTime windowFromFor(DateTime day) {
    final weekday = ((dayNumber(day) % 7) + 7) % 7;
    return addDays(startOfDay(day), -weekday - 7);
  }

  /// The logical day shown at the top of the viewport.
  final DateTime visibleDay;
  final DateTime windowFrom;
  final DateTime windowTo;
  final List<TimeEntry> entries;
  final List<SleepEntry> sleep;
  final List<Category> categories;
  final TimelineDraft? draft;
  final bool isLoading;
  final bool isRefreshing;
  final bool isOffline;
  final bool isSaving;
  final String? error;

  TimeEntry? get runningEntry {
    for (final entry in entries) {
      if (entry.isRunning) return entry;
    }
    return null;
  }

  Category? categoryById(String? id) {
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// Time logged on a logical day. An entry counts towards the day it started
  /// in, so a block running past midnight is never counted twice.
  Duration trackedOn(DateTime day, DateTime now) {
    final key = dayNumber(day);
    var minutes = 0;
    for (final entry in entries) {
      if (dayNumber(startOfLogicalDay(entry.start)) != key) continue;
      minutes += entry.endOrNow(now).difference(entry.start).inMinutes;
    }
    return Duration(minutes: minutes < 0 ? 0 : minutes);
  }

  /// Sleep is attributed to the logical day it woke up in.
  Duration sleepOn(DateTime day) {
    final key = dayNumber(day);
    var total = Duration.zero;
    for (final entry in sleep) {
      if (dayNumber(startOfLogicalDay(entry.end)) != key) continue;
      total += entry.asleep;
    }
    return total;
  }

  /// Most recently finished activities, newest first, one row per distinct
  /// description-and-category pair.
  List<RecentActivity> get recentActivities {
    final sorted = [...entries]
      ..sort((left, right) => right.start.compareTo(left.start));
    final seen = <String>{};
    final recent = <RecentActivity>[];
    for (final entry in sorted) {
      if (entry.description.trim().isEmpty) continue;
      final key = '${entry.description.trim()}#${entry.categoryId ?? ''}';
      if (!seen.add(key)) continue;
      recent.add(
        RecentActivity(
          description: entry.description.trim(),
          categoryId: entry.categoryId,
        ),
      );
      if (recent.length == 6) break;
    }
    return recent;
  }

  TimelineState copyWith({
    DateTime? visibleDay,
    DateTime? windowFrom,
    DateTime? windowTo,
    List<TimeEntry>? entries,
    List<SleepEntry>? sleep,
    List<Category>? categories,
    TimelineDraft? draft,
    bool clearDraft = false,
    bool? isLoading,
    bool? isRefreshing,
    bool? isOffline,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) => TimelineState(
    visibleDay: visibleDay ?? this.visibleDay,
    windowFrom: windowFrom ?? this.windowFrom,
    windowTo: windowTo ?? this.windowTo,
    entries: entries ?? this.entries,
    sleep: sleep ?? this.sleep,
    categories: categories ?? this.categories,
    draft: clearDraft ? null : draft ?? this.draft,
    isLoading: isLoading ?? this.isLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isOffline: isOffline ?? this.isOffline,
    isSaving: isSaving ?? this.isSaving,
    error: clearError ? null : error ?? this.error,
  );
}

class TimelineController extends Notifier<TimelineState> {
  late TodayRepository _repository;
  Timer? _windowDebounce;
  int _loadGeneration = 0;

  /// Fast scrolling crosses many days; let it settle before asking the server
  /// for a window the user has already scrolled past.
  static const _windowSettleDelay = Duration(milliseconds: 250);

  @override
  TimelineState build() {
    _repository = ref.watch(todayRepositoryProvider);
    final now = ref.watch(currentTimeProvider);
    ref.onDispose(() => _windowDebounce?.cancel());
    final initial = TimelineState.initial(now);
    Future<void>.microtask(
      () => _load(initial.windowFrom, initial.windowTo, allowCache: true),
    );
    return initial;
  }

  Future<void> _load(
    DateTime from,
    DateTime to, {
    bool allowCache = false,
  }) async {
    final generation = ++_loadGeneration;
    var painted = false;

    if (allowCache) {
      try {
        final categories = await _repository.loadCachedCategories();
        final window = await _repository.loadCachedWindow(from, to);
        if (!ref.mounted || generation != _loadGeneration) return;
        if (window != null) {
          painted = true;
          state = state.copyWith(
            windowFrom: from,
            windowTo: to,
            entries: window.entries,
            sleep: window.sleep,
            categories: categories ?? state.categories,
            isLoading: false,
            isRefreshing: true,
          );
        }
      } on Object {
        // A broken read cache must never block a fresh server load.
      }
    }

    try {
      final results = await Future.wait<Object>([
        _repository.loadCategories(),
        _repository.loadWindow(from, to),
      ]);
      if (!ref.mounted || generation != _loadGeneration) return;
      final window = results[1] as TimelineWindow;
      state = state.copyWith(
        windowFrom: from,
        windowTo: to,
        entries: window.entries,
        sleep: window.sleep,
        categories: results[0] as List<Category>,
        isLoading: false,
        isRefreshing: false,
        isOffline: false,
        clearError: true,
      );
    } on Object {
      if (!ref.mounted || generation != _loadGeneration) return;
      final hasSomethingToShow = painted || state.entries.isNotEmpty;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isOffline: hasSomethingToShow,
        error: hasSomethingToShow
            ? null
            : 'The timeline could not load. Check the connection and try again.',
        clearError: hasSomethingToShow,
      );
    }
  }

  /// Reported by the timeline as it scrolls. Cheap while the day stays inside
  /// the loaded window; past its edge it schedules the next fetch.
  void setVisibleDay(DateTime day) {
    final normalized = startOfDay(day);
    if (dayNumber(normalized) == dayNumber(state.visibleDay)) return;
    state = state.copyWith(visibleDay: normalized);

    final from = TimelineState.windowFromFor(normalized);
    if (dayNumber(from) == dayNumber(state.windowFrom)) return;

    _windowDebounce?.cancel();
    _windowDebounce = Timer(_windowSettleDelay, () {
      if (!ref.mounted) return;
      final target = TimelineState.windowFromFor(state.visibleDay);
      if (dayNumber(target) == dayNumber(state.windowFrom)) return;
      state = state.copyWith(isRefreshing: true);
      _load(target, addDays(target, TimelineState.windowDays));
    });
  }

  Future<void> refresh() async {
    state = state.copyWith(
      isRefreshing: true,
      isOffline: false,
      clearError: true,
    );
    await _load(state.windowFrom, state.windowTo);
  }

  // Draft block ---------------------------------------------------------------

  void beginDraft(DateTime start, DateTime end) {
    state = state.copyWith(
      draft: TimelineDraft(start: start, end: end),
      clearError: true,
    );
  }

  /// Reshape an existing entry on the grid rather than in a form.
  void beginReshaping(TimeEntry entry) {
    if (entry.isRunning) return;
    state = state.copyWith(
      draft: TimelineDraft(
        entryId: entry.id,
        start: entry.start,
        end: entry.end!,
        description: entry.description,
        categoryId: entry.categoryId,
      ),
      clearError: true,
    );
  }

  void moveDraft(DateTime start, DateTime end) {
    final draft = state.draft;
    if (draft == null) return;
    state = state.copyWith(draft: draft.copyWith(start: start, end: end));
  }

  void describeDraft(String description) {
    final draft = state.draft;
    if (draft == null) return;
    state = state.copyWith(draft: draft.copyWith(description: description));
  }

  void categoriseDraft(String? categoryId) {
    final draft = state.draft;
    if (draft == null) return;
    state = state.copyWith(
      draft: draft.copyWith(
        categoryId: categoryId,
        clearCategory: categoryId == null,
      ),
    );
  }

  void cancelDraft() {
    state = state.copyWith(clearDraft: true, clearError: true);
  }

  /// Commit the draft, whether it is a new block or an entry being reshaped.
  Future<bool> commitDraft() async {
    final draft = state.draft;
    if (draft == null || state.isSaving) return false;
    if (!draft.end.isAfter(draft.start)) {
      state = state.copyWith(error: 'End must be after start.');
      return false;
    }

    final previous = state.entries;
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      if (draft.isNew) {
        final created = await _repository.addEntry(
          NewTimeEntry(
            description: draft.description.trim(),
            categoryId: draft.categoryId,
            start: draft.start,
            end: draft.end,
          ),
        );
        if (!ref.mounted) return false;
        state = state.copyWith(
          entries: _sorted([...state.entries, created]),
          isSaving: false,
          clearDraft: true,
        );
      } else {
        final updated = await _repository.updateEntry(
          draft.entryId!,
          EntryPatch(
            description: draft.description.trim(),
            categoryId: draft.categoryId,
            clearCategory: draft.categoryId == null,
            start: draft.start,
            end: draft.end,
          ),
        );
        if (!ref.mounted) return false;
        state = state.copyWith(
          entries: _replace(state.entries, updated),
          isSaving: false,
          clearDraft: true,
        );
      }
      return true;
    } on Object {
      if (!ref.mounted) return false;
      state = state.copyWith(
        entries: previous,
        isSaving: false,
        error: 'That could not be saved. Try again.',
      );
      return false;
    }
  }

  // Entry edits ---------------------------------------------------------------

  Future<bool> editEntry(String id, EntryPatch patch) async {
    if (patch.isEmpty) return true;
    final previous = state.entries;
    // Show the edit immediately; the server's copy replaces it a moment later.
    state = state.copyWith(
      entries: _sorted(_applyLocally(previous, id, patch)),
      isSaving: true,
      clearError: true,
    );
    try {
      final updated = await _repository.updateEntry(id, patch);
      if (!ref.mounted) return false;
      state = state.copyWith(
        entries: _replace(state.entries, updated),
        isSaving: false,
      );
      return true;
    } on Object {
      if (!ref.mounted) return false;
      state = state.copyWith(
        entries: previous,
        isSaving: false,
        error: 'That change could not be saved.',
      );
      return false;
    }
  }

  /// Removes the entry locally first and hands back what was deleted, so the
  /// caller can offer an undo without another round trip.
  Future<TimeEntry?> deleteEntry(String id) async {
    final previous = state.entries;
    TimeEntry? removed;
    for (final entry in previous) {
      if (entry.id == id) removed = entry;
    }
    if (removed == null) return null;

    state = state.copyWith(
      entries: previous
          .where((entry) => entry.id != id)
          .toList(growable: false),
      clearDraft: true,
      clearError: true,
    );
    try {
      await _repository.deleteEntry(id);
      return removed;
    } on Object {
      if (!ref.mounted) return null;
      state = state.copyWith(
        entries: previous,
        error: 'That entry could not be deleted.',
      );
      return null;
    }
  }

  /// Puts a deleted entry back by recreating it, which is what an undo does.
  Future<void> restoreEntry(TimeEntry entry) async {
    try {
      final created = await _repository.addEntry(
        NewTimeEntry(
          description: entry.description,
          categoryId: entry.categoryId,
          start: entry.start,
          end: entry.end,
        ),
      );
      if (!ref.mounted) return;
      state = state.copyWith(entries: _sorted([...state.entries, created]));
    } on Object {
      if (!ref.mounted) return;
      state = state.copyWith(error: 'That entry could not be restored.');
    }
  }

  // Running timer -------------------------------------------------------------

  Future<bool> startTimer({
    required String description,
    String? categoryId,
    DateTime? at,
  }) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final started = await _repository.addEntry(
        NewTimeEntry(
          description: description.trim(),
          categoryId: categoryId,
          start: at ?? DateTime.now(),
          end: null,
        ),
      );
      if (!ref.mounted) return false;
      // The server closes whichever timer was already running, so mirror that
      // locally rather than showing two live blocks until the next refresh.
      final entries = [
        for (final entry in state.entries)
          if (entry.isRunning && entry.id != started.id)
            entry.copyWith(end: started.start)
          else
            entry,
        started,
      ];
      state = state.copyWith(entries: _sorted(entries), isSaving: false);
      return true;
    } on Object {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isSaving: false,
        error: 'The timer could not be started.',
      );
      return false;
    }
  }

  Future<bool> stopTimer({DateTime? at}) async {
    final running = state.runningEntry;
    if (running == null) return false;
    return editEntry(running.id, EntryPatch(end: at ?? DateTime.now()));
  }

  Future<Category?> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    try {
      final category = await _repository.addCategory(trimmed);
      if (!ref.mounted) return null;
      final categories =
          state.categories.any((existing) => existing.id == category.id)
          ? state.categories
          : ([...state.categories, category]
              ..sort((left, right) => left.name.compareTo(right.name)));
      state = state.copyWith(categories: categories, clearError: true);
      return category;
    } on Object {
      if (!ref.mounted) return null;
      state = state.copyWith(error: 'The category could not be created.');
      return null;
    }
  }

  static List<TimeEntry> _sorted(List<TimeEntry> entries) =>
      [...entries]..sort((left, right) => left.start.compareTo(right.start));

  static List<TimeEntry> _replace(List<TimeEntry> entries, TimeEntry updated) =>
      _sorted([
        for (final entry in entries)
          if (entry.id == updated.id) updated else entry,
      ]);

  static List<TimeEntry> _applyLocally(
    List<TimeEntry> entries,
    String id,
    EntryPatch patch,
  ) => [
    for (final entry in entries)
      if (entry.id == id)
        entry.copyWith(
          description: patch.description,
          categoryId: patch.categoryId,
          clearCategory: patch.clearCategory,
          start: patch.start,
          end: patch.end,
        )
      else
        entry,
  ];
}
