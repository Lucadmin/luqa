import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

class TodaySnapshot {
  const TodaySnapshot({
    required this.day,
    required this.entries,
    required this.categories,
    required this.recentActivities,
    required this.habits,
    required this.sleep,
  });

  final DateTime day;
  final List<TimeEntry> entries;
  final List<Category> categories;
  final List<RecentActivity> recentActivities;
  final List<HabitSnapshot> habits;
  final Duration sleep;
}

abstract interface class TodayRepository {
  TodaySnapshot load(DateTime day);

  Future<TimeEntry> addEntry(NewTimeEntry draft);

  Future<Category> addCategory(String name);
}
