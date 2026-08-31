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

  /// A null field leaves that value untouched; `clearCategory` is how the
  /// category is removed, since null already means "unchanged".
  TimeEntry copyWith({
    String? description,
    String? categoryId,
    bool clearCategory = false,
    DateTime? start,
    DateTime? end,
    bool? pendingSync,
  }) => TimeEntry(
    id: id,
    description: description ?? this.description,
    categoryId: clearCategory ? null : categoryId ?? this.categoryId,
    start: start ?? this.start,
    end: end ?? this.end,
    pendingSync: pendingSync ?? this.pendingSync,
  );

  DateTime endOrNow([DateTime? now]) => end ?? now ?? DateTime.now();

  Duration get duration => endOrNow().difference(start);
}

class NewTimeEntry {
  const NewTimeEntry({
    required this.description,
    required this.categoryId,
    required this.start,
    required this.end,
    this.id,
  });

  /// The identity the device already gave this block. Sending it makes the
  /// create idempotent, so a retry after a lost response cannot duplicate it.
  final String? id;

  final String description;
  final String? categoryId;
  final DateTime start;

  /// Null starts a running timer rather than a completed block.
  final DateTime? end;
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
