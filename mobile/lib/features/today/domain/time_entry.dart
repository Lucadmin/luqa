class TimeEntry {
  const TimeEntry({
    required this.id,
    required this.description,
    required this.categoryId,
    required this.start,
    required this.end,
    this.pendingSync = false,
  });

  final String id;
  final String description;
  final String? categoryId;
  final DateTime start;
  final DateTime? end;
  final bool pendingSync;

  bool get isRunning => end == null;

  DateTime endOrNow([DateTime? now]) => end ?? now ?? DateTime.now();

  Duration get duration => endOrNow().difference(start);
}

class NewTimeEntry {
  const NewTimeEntry({
    required this.description,
    required this.categoryId,
    required this.start,
    required this.end,
  });

  final String description;
  final String? categoryId;
  final DateTime start;
  final DateTime end;
}

class RecentActivity {
  const RecentActivity({required this.description, required this.categoryId});

  final String description;
  final String? categoryId;
}

class HabitSnapshot {
  const HabitSnapshot({
    required this.name,
    required this.progress,
    required this.iconKey,
    required this.colorValue,
  });

  final String name;
  final String progress;
  final String iconKey;
  final int colorValue;
}
