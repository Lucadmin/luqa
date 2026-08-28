import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

/// Everything the timeline needs for one contiguous stretch of days. The
/// window is deliberately wider than the screen so ordinary scrolling never
/// waits on the network.
class TimelineWindow {
  const TimelineWindow({
    required this.from,
    required this.to,
    required this.entries,
    required this.sleep,
  });

  /// Local midnight, inclusive.
  final DateTime from;

  /// Local midnight, exclusive.
  final DateTime to;

  final List<TimeEntry> entries;
  final List<SleepEntry> sleep;

  bool covers(DateTime day) => !day.isBefore(from) && day.isBefore(to);
}

/// A partial edit. Every field is left untouched unless it is supplied;
/// `clearCategory` is how a category is removed, since null already means
/// "unchanged".
class EntryPatch {
  const EntryPatch({
    this.description,
    this.categoryId,
    this.clearCategory = false,
    this.start,
    this.end,
  });

  final String? description;
  final String? categoryId;
  final bool clearCategory;
  final DateTime? start;
  final DateTime? end;

  bool get isEmpty =>
      description == null &&
      categoryId == null &&
      !clearCategory &&
      start == null &&
      end == null;
}

abstract interface class TodayRepository {
  /// Locally cached copies, so a cold start paints before the network answers.
  Future<List<Category>?> loadCachedCategories();

  Future<TimelineWindow?> loadCachedWindow(DateTime from, DateTime to);

  Future<List<Category>> loadCategories();

  Future<TimelineWindow> loadWindow(DateTime from, DateTime to);

  /// A null `end` starts a running timer and stops whichever one was running.
  Future<TimeEntry> addEntry(NewTimeEntry draft);

  Future<TimeEntry> updateEntry(String id, EntryPatch patch);

  Future<void> deleteEntry(String id);

  Future<Category> addCategory(String name);
}
