//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Habit {
  /// Returns a new [Habit] instance.
  Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.order,
    required this.goalType,
    required this.goalPeriod,
    required this.targetCount,
    required this.targetSeconds,
    required this.categoryId,
    required this.scheduleType,
    this.weekdays = const [],
    required this.weekInterval,
    required this.intervalDays,
    required this.timesPerPeriod,
    required this.anchorDate,
    this.dates = const [],
    this.excludedDates = const [],
    required this.archived,
    required this.createdAt,
  });

  final String id;

  final String name;

  /// Name from the shared habit icon set.
  final String? icon;

  final String color;

  final int order;

  final HabitGoalType goalType;

  final HabitGoalPeriod goalPeriod;

  /// Reps needed for a COUNT goal. Always 1 for TASK.
  final int targetCount;

  /// Duration goal in seconds for a TIME habit.
  final int targetSeconds;

  /// A TIME habit linked to a tracking category draws its progress from the time tracked on that category, and its timer is a real time entry rather than a number kept beside one.
  final String? categoryId;

  final HabitScheduleType scheduleType;

  /// For WEEKDAYS — 0 is Sunday, 6 is Saturday.
  final List<int> weekdays;

  /// For WEEKDAYS — every N weeks.
  final int weekInterval;

  /// For INTERVAL — every N days from the anchor.
  final int intervalDays;

  /// For TIMES_PER_* — the quota within each period.
  final int timesPerPeriod;

  /// YYYY-MM-DD the interval counts from. Null falls back to the day the habit was created.
  final String? anchorDate;

  /// For DATES — the explicit YYYY-MM-DD days.
  final List<String> dates;

  /// Days to skip, whatever the schedule would otherwise say.
  final List<String> excludedDates;

  /// Archived habits stay in the feed so a device is told one it is showing has been put away.
  final bool archived;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Habit &&
          other.id == id &&
          other.name == name &&
          other.icon == icon &&
          other.color == color &&
          other.order == order &&
          other.goalType == goalType &&
          other.goalPeriod == goalPeriod &&
          other.targetCount == targetCount &&
          other.targetSeconds == targetSeconds &&
          other.categoryId == categoryId &&
          other.scheduleType == scheduleType &&
          _deepEquality.equals(other.weekdays, weekdays) &&
          other.weekInterval == weekInterval &&
          other.intervalDays == intervalDays &&
          other.timesPerPeriod == timesPerPeriod &&
          other.anchorDate == anchorDate &&
          _deepEquality.equals(other.dates, dates) &&
          _deepEquality.equals(other.excludedDates, excludedDates) &&
          other.archived == archived &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (name.hashCode) +
      (icon == null ? 0 : icon!.hashCode) +
      (color.hashCode) +
      (order.hashCode) +
      (goalType.hashCode) +
      (goalPeriod.hashCode) +
      (targetCount.hashCode) +
      (targetSeconds.hashCode) +
      (categoryId == null ? 0 : categoryId!.hashCode) +
      (scheduleType.hashCode) +
      (weekdays.hashCode) +
      (weekInterval.hashCode) +
      (intervalDays.hashCode) +
      (timesPerPeriod.hashCode) +
      (anchorDate == null ? 0 : anchorDate!.hashCode) +
      (dates.hashCode) +
      (excludedDates.hashCode) +
      (archived.hashCode) +
      (createdAt.hashCode);

  @override
  String toString() =>
      'Habit[id=$id, name=$name, icon=$icon, color=$color, order=$order, goalType=$goalType, goalPeriod=$goalPeriod, targetCount=$targetCount, targetSeconds=$targetSeconds, categoryId=$categoryId, scheduleType=$scheduleType, weekdays=$weekdays, weekInterval=$weekInterval, intervalDays=$intervalDays, timesPerPeriod=$timesPerPeriod, anchorDate=$anchorDate, dates=$dates, excludedDates=$excludedDates, archived=$archived, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'name'] = this.name;
    if (this.icon != null) {
      json[r'icon'] = this.icon;
    } else {
      json[r'icon'] = null;
    }
    json[r'color'] = this.color;
    json[r'order'] = this.order;
    json[r'goalType'] = this.goalType;
    json[r'goalPeriod'] = this.goalPeriod;
    json[r'targetCount'] = this.targetCount;
    json[r'targetSeconds'] = this.targetSeconds;
    if (this.categoryId != null) {
      json[r'categoryId'] = this.categoryId;
    } else {
      json[r'categoryId'] = null;
    }
    json[r'scheduleType'] = this.scheduleType;
    json[r'weekdays'] = this.weekdays;
    json[r'weekInterval'] = this.weekInterval;
    json[r'intervalDays'] = this.intervalDays;
    json[r'timesPerPeriod'] = this.timesPerPeriod;
    if (this.anchorDate != null) {
      json[r'anchorDate'] = this.anchorDate;
    } else {
      json[r'anchorDate'] = null;
    }
    json[r'dates'] = this.dates;
    json[r'excludedDates'] = this.excludedDates;
    json[r'archived'] = this.archived;
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [Habit] and returns a new one where some of the
  /// properties have changed.
  Habit copyWith({
    String? id,
    String? name,
    String? icon,
    bool iconSetToNull = false,
    String? color,
    int? order,
    HabitGoalType? goalType,
    HabitGoalPeriod? goalPeriod,
    int? targetCount,
    int? targetSeconds,
    String? categoryId,
    bool categoryIdSetToNull = false,
    HabitScheduleType? scheduleType,
    List<int>? weekdays,
    int? weekInterval,
    int? intervalDays,
    int? timesPerPeriod,
    String? anchorDate,
    bool anchorDateSetToNull = false,
    List<String>? dates,
    List<String>? excludedDates,
    bool? archived,
    DateTime? createdAt,
  }) =>
      Habit(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: iconSetToNull ? null : icon ?? this.icon,
        color: color ?? this.color,
        order: order ?? this.order,
        goalType: goalType ?? this.goalType,
        goalPeriod: goalPeriod ?? this.goalPeriod,
        targetCount: targetCount ?? this.targetCount,
        targetSeconds: targetSeconds ?? this.targetSeconds,
        categoryId: categoryIdSetToNull ? null : categoryId ?? this.categoryId,
        scheduleType: scheduleType ?? this.scheduleType,
        weekdays: weekdays ?? this.weekdays,
        weekInterval: weekInterval ?? this.weekInterval,
        intervalDays: intervalDays ?? this.intervalDays,
        timesPerPeriod: timesPerPeriod ?? this.timesPerPeriod,
        anchorDate: anchorDateSetToNull ? null : anchorDate ?? this.anchorDate,
        dates: dates ?? this.dates,
        excludedDates: excludedDates ?? this.excludedDates,
        archived: archived ?? this.archived,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Returns a new [Habit] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Habit? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "Habit[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "Habit[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "Habit[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "Habit[name]" has a null value in JSON.');
        assert(json.containsKey(r'icon'),
            'Required key "Habit[icon]" is missing from JSON.');
        assert(json.containsKey(r'color'),
            'Required key "Habit[color]" is missing from JSON.');
        assert(json[r'color'] != null,
            'Required key "Habit[color]" has a null value in JSON.');
        assert(json.containsKey(r'order'),
            'Required key "Habit[order]" is missing from JSON.');
        assert(json[r'order'] != null,
            'Required key "Habit[order]" has a null value in JSON.');
        assert(json.containsKey(r'goalType'),
            'Required key "Habit[goalType]" is missing from JSON.');
        assert(json[r'goalType'] != null,
            'Required key "Habit[goalType]" has a null value in JSON.');
        assert(json.containsKey(r'goalPeriod'),
            'Required key "Habit[goalPeriod]" is missing from JSON.');
        assert(json[r'goalPeriod'] != null,
            'Required key "Habit[goalPeriod]" has a null value in JSON.');
        assert(json.containsKey(r'targetCount'),
            'Required key "Habit[targetCount]" is missing from JSON.');
        assert(json[r'targetCount'] != null,
            'Required key "Habit[targetCount]" has a null value in JSON.');
        assert(json.containsKey(r'targetSeconds'),
            'Required key "Habit[targetSeconds]" is missing from JSON.');
        assert(json[r'targetSeconds'] != null,
            'Required key "Habit[targetSeconds]" has a null value in JSON.');
        assert(json.containsKey(r'categoryId'),
            'Required key "Habit[categoryId]" is missing from JSON.');
        assert(json.containsKey(r'scheduleType'),
            'Required key "Habit[scheduleType]" is missing from JSON.');
        assert(json[r'scheduleType'] != null,
            'Required key "Habit[scheduleType]" has a null value in JSON.');
        assert(json.containsKey(r'weekdays'),
            'Required key "Habit[weekdays]" is missing from JSON.');
        assert(json[r'weekdays'] != null,
            'Required key "Habit[weekdays]" has a null value in JSON.');
        assert(json.containsKey(r'weekInterval'),
            'Required key "Habit[weekInterval]" is missing from JSON.');
        assert(json[r'weekInterval'] != null,
            'Required key "Habit[weekInterval]" has a null value in JSON.');
        assert(json.containsKey(r'intervalDays'),
            'Required key "Habit[intervalDays]" is missing from JSON.');
        assert(json[r'intervalDays'] != null,
            'Required key "Habit[intervalDays]" has a null value in JSON.');
        assert(json.containsKey(r'timesPerPeriod'),
            'Required key "Habit[timesPerPeriod]" is missing from JSON.');
        assert(json[r'timesPerPeriod'] != null,
            'Required key "Habit[timesPerPeriod]" has a null value in JSON.');
        assert(json.containsKey(r'anchorDate'),
            'Required key "Habit[anchorDate]" is missing from JSON.');
        assert(json.containsKey(r'dates'),
            'Required key "Habit[dates]" is missing from JSON.');
        assert(json[r'dates'] != null,
            'Required key "Habit[dates]" has a null value in JSON.');
        assert(json.containsKey(r'excludedDates'),
            'Required key "Habit[excludedDates]" is missing from JSON.');
        assert(json[r'excludedDates'] != null,
            'Required key "Habit[excludedDates]" has a null value in JSON.');
        assert(json.containsKey(r'archived'),
            'Required key "Habit[archived]" is missing from JSON.');
        assert(json[r'archived'] != null,
            'Required key "Habit[archived]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'),
            'Required key "Habit[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null,
            'Required key "Habit[createdAt]" has a null value in JSON.');
        return true;
      }());

      return Habit(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        icon: mapValueOfType<String>(json, r'icon'),
        color: mapValueOfType<String>(json, r'color')!,
        order: mapValueOfType<int>(json, r'order')!,
        goalType: HabitGoalType.fromJson(json[r'goalType'])!,
        goalPeriod: HabitGoalPeriod.fromJson(json[r'goalPeriod'])!,
        targetCount: mapValueOfType<int>(json, r'targetCount')!,
        targetSeconds: mapValueOfType<int>(json, r'targetSeconds')!,
        categoryId: mapValueOfType<String>(json, r'categoryId'),
        scheduleType: HabitScheduleType.fromJson(json[r'scheduleType'])!,
        weekdays: json[r'weekdays'] is Iterable
            ? (json[r'weekdays'] as Iterable)
                .cast<int>()
                .toList(growable: false)
            : const [],
        weekInterval: mapValueOfType<int>(json, r'weekInterval')!,
        intervalDays: mapValueOfType<int>(json, r'intervalDays')!,
        timesPerPeriod: mapValueOfType<int>(json, r'timesPerPeriod')!,
        anchorDate: mapValueOfType<String>(json, r'anchorDate'),
        dates: json[r'dates'] is Iterable
            ? (json[r'dates'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        excludedDates: json[r'excludedDates'] is Iterable
            ? (json[r'excludedDates'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        archived: mapValueOfType<bool>(json, r'archived')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<Habit> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Habit>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Habit.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Habit> mapFromJson(dynamic json) {
    final map = <String, Habit>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Habit.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Habit-objects as value to a dart map
  static Map<String, List<Habit>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Habit>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Habit.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'icon',
    'color',
    'order',
    'goalType',
    'goalPeriod',
    'targetCount',
    'targetSeconds',
    'categoryId',
    'scheduleType',
    'weekdays',
    'weekInterval',
    'intervalDays',
    'timesPerPeriod',
    'anchorDate',
    'dates',
    'excludedDates',
    'archived',
    'createdAt',
  };
}
