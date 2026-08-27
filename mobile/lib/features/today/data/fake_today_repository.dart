import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

class FakeTodayRepository implements TodayRepository {
  final List<Category> _categories = [
    const Category(id: 'food', name: 'Food', colorValue: 0xFFB45309),
    const Category(
      id: 'master-thesis',
      name: 'Master thesis',
      colorValue: 0xFF6543E8,
    ),
    const Category(id: 'training', name: 'Training', colorValue: 0xFFC2410C),
    const Category(id: 'personal', name: 'Personal', colorValue: 0xFF0F766E),
  ];

  final List<TimeEntry> _entries = [];

  DateTime _at(DateTime day, int hour, int minute) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  void _seed(DateTime day) {
    if (_entries.isNotEmpty) return;
    _entries.addAll([
      TimeEntry(
        id: 'breakfast',
        description: 'Breakfast',
        categoryId: 'food',
        start: _at(day, 8, 10),
        end: _at(day, 8, 40),
      ),
      TimeEntry(
        id: 'thesis',
        description: 'Writing thesis',
        categoryId: 'master-thesis',
        start: _at(day, 9, 0),
        end: _at(day, 11, 45),
      ),
      TimeEntry(
        id: 'gym',
        description: 'Gym',
        categoryId: 'training',
        start: _at(day, 12, 30),
        end: _at(day, 13, 45),
      ),
    ]);
  }

  TodaySnapshot _snapshot(DateTime day) {
    _seed(day);
    return TodaySnapshot(
      day: DateTime(day.year, day.month, day.day),
      entries: List.unmodifiable(_entries),
      categories: List.unmodifiable(_categories),
      recentActivities: const [
        RecentActivity(
          description: 'Writing thesis',
          categoryId: 'master-thesis',
        ),
        RecentActivity(description: 'Lunch', categoryId: 'food'),
        RecentActivity(description: 'Gym', categoryId: 'training'),
      ],
      habits: const [
        HabitSnapshot(
          name: 'Water',
          progress: '5/8',
          iconKey: 'water',
          colorValue: 0xFF2563EB,
        ),
        HabitSnapshot(
          name: 'Read',
          progress: '20m',
          iconKey: 'read',
          colorValue: 0xFF0F766E,
        ),
        HabitSnapshot(
          name: 'Stretch',
          progress: '1/3',
          iconKey: 'stretch',
          colorValue: 0xFFBE185D,
        ),
      ],
      sleep: const Duration(hours: 7, minutes: 17),
    );
  }

  @override
  Future<TodaySnapshot?> loadCached(DateTime day) async => _snapshot(day);

  @override
  Future<TodaySnapshot> refresh(DateTime day) async => _snapshot(day);

  @override
  Future<TimeEntry> addEntry(NewTimeEntry draft) async {
    await Future<void>.delayed(LuqaMotion.press);
    final entry = TimeEntry(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      description: draft.description,
      categoryId: draft.categoryId,
      start: draft.start,
      end: draft.end,
    );
    _entries.add(entry);
    return entry;
  }

  @override
  Future<Category> addCategory(String name) async {
    await Future<void>.delayed(LuqaMotion.press);
    final category = Category(
      id: 'local-category-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      colorValue: 0xFF6543E8,
    );
    _categories.add(category);
    return category;
  }
}
