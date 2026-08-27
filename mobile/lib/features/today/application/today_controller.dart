import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/features/today/data/fake_today_repository.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

final todayRepositoryProvider = Provider<TodayRepository>(
  (ref) => FakeTodayRepository(),
);

final currentTimeProvider = Provider<DateTime>((ref) => DateTime.now());

final todayControllerProvider = NotifierProvider<TodayController, TodayState>(
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
    this.isSaving = false,
    this.error,
  });

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
  final Duration sleep;
  final bool isSaving;
  final String? error;

  TodayState copyWith({
    List<TimeEntry>? entries,
    List<Category>? categories,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return TodayState(
      day: day,
      entries: entries ?? this.entries,
      categories: categories ?? this.categories,
      recentActivities: recentActivities,
      habits: habits,
      sleep: sleep,
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
    return TodayState.fromSnapshot(
      _repository.load(ref.watch(currentTimeProvider)),
    );
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
      final entries = [...state.entries, entry]
        ..sort((left, right) => left.start.compareTo(right.start));
      state = state.copyWith(entries: entries, isSaving: false);
      return true;
    } on Object {
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
      state = state.copyWith(categories: [...state.categories, category]);
      return category;
    } on Object {
      state = state.copyWith(error: 'The category could not be created.');
      return null;
    }
  }
}
