import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/today/data/remote_today_repository.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

final todayRepositoryProvider = Provider<TodayRepository>((ref) {
  final userId = ref.watch(authControllerProvider).value?.user?.id;
  return RemoteTodayRepository(
    client: ref.watch(luqaApiProvider),
    cache: SharedPreferencesTodayCache(namespace: userId ?? 'signed-out'),
  );
});

final currentTimeProvider = Provider<DateTime>((ref) => DateTime.now());

final todayControllerProvider =
    NotifierProvider.autoDispose<TodayController, TodayState>(
      TodayController.new,
    );

class TodayState {
  const TodayState({
    required this.day,
    required this.entries,
    required this.categories,
    required this.recentActivities,
    required this.habits,
    required this.sleep,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isOffline = false,
    this.isSaving = false,
    this.error,
  });

  factory TodayState.initial(DateTime day) => TodayState(
    day: DateTime(day.year, day.month, day.day),
    entries: const [],
    categories: const [],
    recentActivities: const [],
    habits: const [],
    sleep: null,
    isLoading: true,
  );

  factory TodayState.fromSnapshot(TodaySnapshot snapshot) => TodayState(
    day: snapshot.day,
    entries: snapshot.entries,
    categories: snapshot.categories,
    recentActivities: snapshot.recentActivities,
    habits: snapshot.habits,
    sleep: snapshot.sleep,
  );

  final DateTime day;
  final List<TimeEntry> entries;
  final List<Category> categories;
  final List<RecentActivity> recentActivities;
  final List<HabitSnapshot> habits;
  final Duration? sleep;
  final bool isLoading;
  final bool isRefreshing;
  final bool isOffline;
  final bool isSaving;
  final String? error;

  TodayState copyWith({
    List<TimeEntry>? entries,
    List<Category>? categories,
    List<RecentActivity>? recentActivities,
    List<HabitSnapshot>? habits,
    Duration? sleep,
    bool keepSleep = true,
    bool? isLoading,
    bool? isRefreshing,
    bool? isOffline,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return TodayState(
      day: day,
      entries: entries ?? this.entries,
      categories: categories ?? this.categories,
      recentActivities: recentActivities ?? this.recentActivities,
      habits: habits ?? this.habits,
      sleep: keepSleep ? sleep ?? this.sleep : sleep,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isOffline: isOffline ?? this.isOffline,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class TodayController extends Notifier<TodayState> {
  late TodayRepository _repository;

  @override
  TodayState build() {
    _repository = ref.watch(todayRepositoryProvider);
    final day = ref.watch(currentTimeProvider);
    Future<void>.microtask(() => _load(day));
    return TodayState.initial(day);
  }

  Future<void> _load(DateTime day) async {
    var hasCached = false;
    try {
      final cached = await _repository.loadCached(day);
      if (!ref.mounted) return;
      if (cached != null) {
        hasCached = true;
        state = TodayState.fromSnapshot(cached).copyWith(isRefreshing: true);
      }
    } on Object {
      // A broken read cache must never prevent a fresh server load.
    }

    try {
      final snapshot = await _repository.refresh(day);
      if (!ref.mounted) return;
      state = TodayState.fromSnapshot(snapshot);
    } on Object {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isOffline: hasCached,
        error: hasCached
            ? null
            : 'Today could not load. Check the connection and try again.',
        clearError: hasCached,
      );
    }
  }

  Future<void> retry() async {
    state = state.copyWith(
      isLoading: state.entries.isEmpty,
      isRefreshing: state.entries.isNotEmpty,
      isOffline: false,
      clearError: true,
    );
    await _load(state.day);
  }

  Future<bool> addEntry(NewTimeEntry draft) async {
    if (state.isSaving) return false;
    if (!draft.end.isAfter(draft.start)) {
      state = state.copyWith(error: 'End must be after start.');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final entry = await _repository.addEntry(draft);
      if (!ref.mounted) return false;
      final entries = [...state.entries, entry]
        ..sort((left, right) => left.start.compareTo(right.start));
      final recentActivities = _withRecentActivity(entry);
      state = state.copyWith(
        entries: entries,
        recentActivities: recentActivities,
        isSaving: false,
      );
      return true;
    } on Object {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isSaving: false,
        error: 'The entry could not be saved. Try again.',
      );
      return false;
    }
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

  List<RecentActivity> _withRecentActivity(TimeEntry entry) {
    if (entry.description.trim().isEmpty && entry.categoryId == null) {
      return state.recentActivities;
    }
    final recent = RecentActivity(
      description: entry.description,
      categoryId: entry.categoryId,
    );
    return [
      recent,
      ...state.recentActivities.where(
        (existing) =>
            existing.description.trim() != entry.description.trim() ||
            existing.categoryId != entry.categoryId,
      ),
    ].take(5).toList(growable: false);
  }
}
