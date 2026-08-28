import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

/// Deterministic stand-in for the network, seeded around a fixed day so
/// widget tests and goldens see the same timeline every run.
class FakeTimelineRepository implements TodayRepository {
  FakeTimelineRepository({required this.today});

  final DateTime today;

  int nextId = 100;

  final List<Category> categories = [
    const Category(id: 'food', name: 'Food', colorValue: 0xFFB45309),
    const Category(
      id: 'master-thesis',
      name: 'Master thesis',
      colorValue: 0xFF6543E8,
    ),
    const Category(id: 'training', name: 'Training', colorValue: 0xFFC2410C),
    const Category(id: 'personal', name: 'Personal', colorValue: 0xFF0F766E),
  ];

  late final List<TimeEntry> entries = [
    TimeEntry(
      id: 'breakfast',
      description: 'Breakfast',
      categoryId: 'food',
      start: _at(8, 10),
      end: _at(8, 40),
    ),
    TimeEntry(
      id: 'thesis',
      description: 'Writing thesis',
      categoryId: 'master-thesis',
      start: _at(9, 0),
      end: _at(11, 45),
    ),
    TimeEntry(
      id: 'gym',
      description: 'Gym',
      categoryId: 'training',
      start: _at(12, 30),
      end: _at(13, 45),
    ),
  ];

  late final List<SleepEntry> sleep = [
    SleepEntry(
      id: 'sleep-1',
      source: 'HEALTH_CONNECT',
      sourceApp: 'Pixel Watch',
      title: null,
      start: _at(0, 12).subtract(const Duration(hours: 1)),
      end: _at(7, 29),
      sleepMinutes: 437,
      awakeMinutes: 22,
      lightMinutes: 240,
      deepMinutes: 95,
      remMinutes: 102,
      isNap: false,
    ),
  ];

  DateTime _at(int hour, int minute) =>
      DateTime(today.year, today.month, today.day, hour, minute);

  @override
  Future<List<Category>?> loadCachedCategories() async => null;

  @override
  Future<TimelineWindow?> loadCachedWindow(DateTime from, DateTime to) async =>
      null;

  @override
  Future<List<Category>> loadCategories() async =>
      List.unmodifiable(categories);

  @override
  Future<TimelineWindow> loadWindow(DateTime from, DateTime to) async =>
      TimelineWindow(
        from: from,
        to: to,
        entries: entries
            .where(
              (entry) =>
                  entry.start.isBefore(to) && entry.endOrNow().isAfter(from),
            )
            .toList(growable: false),
        sleep: sleep
            .where(
              (entry) => entry.end.isAfter(from) && entry.end.isBefore(to),
            )
            .toList(growable: false),
      );

  @override
  Future<TimeEntry> addEntry(NewTimeEntry draft) async {
    final entry = TimeEntry(
      id: 'entry-${nextId++}',
      description: draft.description,
      categoryId: draft.categoryId,
      start: draft.start,
      end: draft.end,
    );
    entries.add(entry);
    return entry;
  }

  @override
  Future<TimeEntry> updateEntry(String id, EntryPatch patch) async {
    final index = entries.indexWhere((entry) => entry.id == id);
    if (index == -1) throw StateError('No entry $id');
    final updated = entries[index].copyWith(
      description: patch.description,
      categoryId: patch.categoryId,
      clearCategory: patch.clearCategory,
      start: patch.start,
      end: patch.end,
    );
    entries[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteEntry(String id) async {
    entries.removeWhere((entry) => entry.id == id);
  }

  @override
  Future<Category> addCategory(String name) async {
    final category = Category(
      id: 'category-${nextId++}',
      name: name.trim(),
      colorValue: 0xFF6543E8,
    );
    categories.add(category);
    return category;
  }
}
