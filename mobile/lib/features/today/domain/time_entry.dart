class TimeEntry {
  const TimeEntry({
    required this.id,
    required this.description,
    required this.categoryId,
    required this.start,
    required this.end,
    this.pendingSync = false,
    this.personIds = const [],
  });

  final String id;
  final String description;
  final String? categoryId;
  final DateTime start;
  final DateTime? end;
  final bool pendingSync;

  /// Who was there.
  ///
  /// Dinner logged on Tuesday is the record that Tuesday is when you last saw
  /// them. Asking for that here means never asking for it again on their own
  /// screen — "last seen" becomes something the app already knows.
  final List<String> personIds;

  bool get isRunning => end == null;

  bool get hasPeople => personIds.isNotEmpty;

  /// A null field leaves that value untouched; `clearCategory` is how the
  /// category is removed, since null already means "unchanged".
  TimeEntry copyWith({
    String? description,
    String? categoryId,
    bool clearCategory = false,
    DateTime? start,
    DateTime? end,
    bool? pendingSync,
    List<String>? personIds,
  }) => TimeEntry(
    id: id,
    description: description ?? this.description,
    categoryId: clearCategory ? null : categoryId ?? this.categoryId,
    start: start ?? this.start,
    end: end ?? this.end,
    pendingSync: pendingSync ?? this.pendingSync,
    personIds: personIds ?? this.personIds,
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
    this.personIds = const [],
  });

  /// The identity the device already gave this block. Sending it makes the
  /// create idempotent, so a retry after a lost response cannot duplicate it.
  final String? id;

  final String description;
  final String? categoryId;
  final DateTime start;

  /// Null starts a running timer rather than a completed block.
  final DateTime? end;

  /// Who was there.
  final List<String> personIds;
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
