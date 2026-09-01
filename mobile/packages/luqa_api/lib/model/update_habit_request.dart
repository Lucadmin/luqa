//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UpdateHabitRequest {
  /// Returns a new [UpdateHabitRequest] instance.
  UpdateHabitRequest({
    this.name = const Optional.absent(),
    this.icon = const Optional.absent(),
    this.color = const Optional.absent(),
    this.order = const Optional.absent(),
    this.goalType = const Optional.absent(),
    this.goalPeriod = const Optional.absent(),
    this.targetCount = const Optional.absent(),
    this.targetSeconds = const Optional.absent(),
    this.categoryId = const Optional.absent(),
    this.scheduleType = const Optional.absent(),
    this.weekdays = const Optional.present(const []),
    this.weekInterval = const Optional.absent(),
    this.intervalDays = const Optional.absent(),
    this.timesPerPeriod = const Optional.absent(),
    this.anchorDate = const Optional.absent(),
    this.dates = const Optional.present(const []),
    this.excludedDates = const Optional.present(const []),
    this.archived = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> icon;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> color;

  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> order;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<HabitGoalType?> goalType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<HabitGoalPeriod?> goalPeriod;

  /// Minimum value: 1
  /// Maximum value: 1000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> targetCount;

  /// Minimum value: 0
  /// Maximum value: 2592000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> targetSeconds;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> categoryId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<HabitScheduleType?> scheduleType;

  final Optional<List<int>?> weekdays;

  /// Minimum value: 1
  /// Maximum value: 12
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> weekInterval;

  /// Minimum value: 1
  /// Maximum value: 365
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> intervalDays;

  /// Minimum value: 1
  /// Maximum value: 366
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> timesPerPeriod;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> anchorDate;

  final Optional<List<String>?> dates;

  final Optional<List<String>?> excludedDates;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> archived;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateHabitRequest &&
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
          other.archived == archived;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name == null ? 0 : name!.hashCode) +
      (icon == null ? 0 : icon!.hashCode) +
      (color == null ? 0 : color!.hashCode) +
      (order == null ? 0 : order!.hashCode) +
      (goalType == null ? 0 : goalType!.hashCode) +
      (goalPeriod == null ? 0 : goalPeriod!.hashCode) +
      (targetCount == null ? 0 : targetCount!.hashCode) +
      (targetSeconds == null ? 0 : targetSeconds!.hashCode) +
      (categoryId == null ? 0 : categoryId!.hashCode) +
      (scheduleType == null ? 0 : scheduleType!.hashCode) +
      (weekdays.hashCode) +
      (weekInterval == null ? 0 : weekInterval!.hashCode) +
      (intervalDays == null ? 0 : intervalDays!.hashCode) +
      (timesPerPeriod == null ? 0 : timesPerPeriod!.hashCode) +
      (anchorDate == null ? 0 : anchorDate!.hashCode) +
      (dates.hashCode) +
      (excludedDates.hashCode) +
      (archived == null ? 0 : archived!.hashCode);

  @override
  String toString() =>
      'UpdateHabitRequest[name=$name, icon=$icon, color=$color, order=$order, goalType=$goalType, goalPeriod=$goalPeriod, targetCount=$targetCount, targetSeconds=$targetSeconds, categoryId=$categoryId, scheduleType=$scheduleType, weekdays=$weekdays, weekInterval=$weekInterval, intervalDays=$intervalDays, timesPerPeriod=$timesPerPeriod, anchorDate=$anchorDate, dates=$dates, excludedDates=$excludedDates, archived=$archived]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name.isPresent) {
      final value = this.name.value;
      json[r'name'] = value;
    }
    if (this.icon.isPresent) {
      final value = this.icon.value;
      json[r'icon'] = value;
    }
    if (this.color.isPresent) {
      final value = this.color.value;
      json[r'color'] = value;
    }
    if (this.order.isPresent) {
      final value = this.order.value;
      json[r'order'] = value;
    }
    if (this.goalType.isPresent) {
      final value = this.goalType.value;
      json[r'goalType'] = value;
    }
    if (this.goalPeriod.isPresent) {
      final value = this.goalPeriod.value;
      json[r'goalPeriod'] = value;
    }
    if (this.targetCount.isPresent) {
      final value = this.targetCount.value;
      json[r'targetCount'] = value;
    }
    if (this.targetSeconds.isPresent) {
      final value = this.targetSeconds.value;
      json[r'targetSeconds'] = value;
    }
    if (this.categoryId.isPresent) {
      final value = this.categoryId.value;
      json[r'categoryId'] = value;
    }
    if (this.scheduleType.isPresent) {
      final value = this.scheduleType.value;
      json[r'scheduleType'] = value;
    }
    if (this.weekdays.isPresent) {
      final value = this.weekdays.value;
      json[r'weekdays'] = value;
    }
    if (this.weekInterval.isPresent) {
      final value = this.weekInterval.value;
      json[r'weekInterval'] = value;
    }
    if (this.intervalDays.isPresent) {
      final value = this.intervalDays.value;
      json[r'intervalDays'] = value;
    }
    if (this.timesPerPeriod.isPresent) {
      final value = this.timesPerPeriod.value;
      json[r'timesPerPeriod'] = value;
    }
    if (this.anchorDate.isPresent) {
      final value = this.anchorDate.value;
      json[r'anchorDate'] = value;
    }
    if (this.dates.isPresent) {
      final value = this.dates.value;
      json[r'dates'] = value;
    }
    if (this.excludedDates.isPresent) {
      final value = this.excludedDates.value;
      json[r'excludedDates'] = value;
    }
    if (this.archived.isPresent) {
      final value = this.archived.value;
      json[r'archived'] = value;
    }
    return json;
  }

  /// Clones this instance of [UpdateHabitRequest] and returns a new one where some of the
  /// properties have changed.
  UpdateHabitRequest copyWith({
    Optional<String?>? name,
    Optional<String?>? icon,
    Optional<String?>? color,
    Optional<int?>? order,
    Optional<HabitGoalType?>? goalType,
    Optional<HabitGoalPeriod?>? goalPeriod,
    Optional<int?>? targetCount,
    Optional<int?>? targetSeconds,
    Optional<String?>? categoryId,
    Optional<HabitScheduleType?>? scheduleType,
    Optional<List<int>?>? weekdays,
    Optional<int?>? weekInterval,
    Optional<int?>? intervalDays,
    Optional<int?>? timesPerPeriod,
    Optional<String?>? anchorDate,
    Optional<List<String>?>? dates,
    Optional<List<String>?>? excludedDates,
    Optional<bool?>? archived,
  }) =>
      UpdateHabitRequest(
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        order: order ?? this.order,
        goalType: goalType ?? this.goalType,
        goalPeriod: goalPeriod ?? this.goalPeriod,
        targetCount: targetCount ?? this.targetCount,
        targetSeconds: targetSeconds ?? this.targetSeconds,
        categoryId: categoryId ?? this.categoryId,
        scheduleType: scheduleType ?? this.scheduleType,
        weekdays: weekdays ?? this.weekdays,
        weekInterval: weekInterval ?? this.weekInterval,
        intervalDays: intervalDays ?? this.intervalDays,
        timesPerPeriod: timesPerPeriod ?? this.timesPerPeriod,
        anchorDate: anchorDate ?? this.anchorDate,
        dates: dates ?? this.dates,
        excludedDates: excludedDates ?? this.excludedDates,
        archived: archived ?? this.archived,
      );

  /// Returns a new [UpdateHabitRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateHabitRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UpdateHabitRequest(
        name: json.containsKey(r'name')
            ? Optional.present(mapValueOfType<String>(json, r'name'))
            : const Optional.absent(),
        icon: json.containsKey(r'icon')
            ? Optional.present(mapValueOfType<String>(json, r'icon'))
            : const Optional.absent(),
        color: json.containsKey(r'color')
            ? Optional.present(mapValueOfType<String>(json, r'color'))
            : const Optional.absent(),
        order: json.containsKey(r'order')
            ? Optional.present(
                json[r'order'] == null ? null : int.parse('${json[r'order']}'))
            : const Optional.absent(),
        goalType: json.containsKey(r'goalType')
            ? Optional.present(HabitGoalType.fromJson(json[r'goalType']))
            : const Optional.absent(),
        goalPeriod: json.containsKey(r'goalPeriod')
            ? Optional.present(HabitGoalPeriod.fromJson(json[r'goalPeriod']))
            : const Optional.absent(),
        targetCount: json.containsKey(r'targetCount')
            ? Optional.present(json[r'targetCount'] == null
                ? null
                : int.parse('${json[r'targetCount']}'))
            : const Optional.absent(),
        targetSeconds: json.containsKey(r'targetSeconds')
            ? Optional.present(json[r'targetSeconds'] == null
                ? null
                : int.parse('${json[r'targetSeconds']}'))
            : const Optional.absent(),
        categoryId: json.containsKey(r'categoryId')
            ? Optional.present(mapValueOfType<String>(json, r'categoryId'))
            : const Optional.absent(),
        scheduleType: json.containsKey(r'scheduleType')
            ? Optional.present(
                HabitScheduleType.fromJson(json[r'scheduleType']))
            : const Optional.absent(),
        weekdays: json.containsKey(r'weekdays')
            ? Optional.present(json[r'weekdays'] is Iterable
                ? (json[r'weekdays'] as Iterable)
                    .cast<int>()
                    .toList(growable: false)
                : const [])
            : const Optional.absent(),
        weekInterval: json.containsKey(r'weekInterval')
            ? Optional.present(json[r'weekInterval'] == null
                ? null
                : int.parse('${json[r'weekInterval']}'))
            : const Optional.absent(),
        intervalDays: json.containsKey(r'intervalDays')
            ? Optional.present(json[r'intervalDays'] == null
                ? null
                : int.parse('${json[r'intervalDays']}'))
            : const Optional.absent(),
        timesPerPeriod: json.containsKey(r'timesPerPeriod')
            ? Optional.present(json[r'timesPerPeriod'] == null
                ? null
                : int.parse('${json[r'timesPerPeriod']}'))
            : const Optional.absent(),
        anchorDate: json.containsKey(r'anchorDate')
            ? Optional.present(mapValueOfType<String>(json, r'anchorDate'))
            : const Optional.absent(),
        dates: json.containsKey(r'dates')
            ? Optional.present(json[r'dates'] is Iterable
                ? (json[r'dates'] as Iterable)
                    .cast<String>()
                    .toList(growable: false)
                : const [])
            : const Optional.absent(),
        excludedDates: json.containsKey(r'excludedDates')
            ? Optional.present(json[r'excludedDates'] is Iterable
                ? (json[r'excludedDates'] as Iterable)
                    .cast<String>()
                    .toList(growable: false)
                : const [])
            : const Optional.absent(),
        archived: json.containsKey(r'archived')
            ? Optional.present(mapValueOfType<bool>(json, r'archived'))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<UpdateHabitRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UpdateHabitRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateHabitRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateHabitRequest> mapFromJson(dynamic json) {
    final map = <String, UpdateHabitRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateHabitRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateHabitRequest-objects as value to a dart map
  static Map<String, List<UpdateHabitRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UpdateHabitRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateHabitRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{};
}
