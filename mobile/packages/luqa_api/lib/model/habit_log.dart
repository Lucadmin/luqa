//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HabitLog {
  /// Returns a new [HabitLog] instance.
  HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.count,
    required this.seconds,
    required this.runningSince,
    required this.completedAt,
  });

  final String id;

  final String habitId;

  final String date;

  /// Reps done for a COUNT goal, or 0/1 for a TASK.
  final int count;

  /// Seconds banked toward an unlinked TIME goal.
  final int seconds;

  /// When an unlinked timer started. The elapsed time is added as it runs rather than written every second, so a device that is asleep still shows the right total when it wakes.
  final DateTime? runningSince;

  /// The first moment the day's goal was met. A seventh glass of water does not re-complete the day.
  final DateTime? completedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitLog &&
          other.id == id &&
          other.habitId == habitId &&
          other.date == date &&
          other.count == count &&
          other.seconds == seconds &&
          other.runningSince == runningSince &&
          other.completedAt == completedAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (habitId.hashCode) +
      (date.hashCode) +
      (count.hashCode) +
      (seconds.hashCode) +
      (runningSince == null ? 0 : runningSince!.hashCode) +
      (completedAt == null ? 0 : completedAt!.hashCode);

  @override
  String toString() =>
      'HabitLog[id=$id, habitId=$habitId, date=$date, count=$count, seconds=$seconds, runningSince=$runningSince, completedAt=$completedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'habitId'] = this.habitId;
    json[r'date'] = this.date;
    json[r'count'] = this.count;
    json[r'seconds'] = this.seconds;
    if (this.runningSince != null) {
      json[r'runningSince'] = this.runningSince!.toUtc().toIso8601String();
    } else {
      json[r'runningSince'] = null;
    }
    if (this.completedAt != null) {
      json[r'completedAt'] = this.completedAt!.toUtc().toIso8601String();
    } else {
      json[r'completedAt'] = null;
    }
    return json;
  }

  /// Clones this instance of [HabitLog] and returns a new one where some of the
  /// properties have changed.
  HabitLog copyWith({
    String? id,
    String? habitId,
    String? date,
    int? count,
    int? seconds,
    DateTime? runningSince,
    bool runningSinceSetToNull = false,
    DateTime? completedAt,
    bool completedAtSetToNull = false,
  }) =>
      HabitLog(
        id: id ?? this.id,
        habitId: habitId ?? this.habitId,
        date: date ?? this.date,
        count: count ?? this.count,
        seconds: seconds ?? this.seconds,
        runningSince:
            runningSinceSetToNull ? null : runningSince ?? this.runningSince,
        completedAt:
            completedAtSetToNull ? null : completedAt ?? this.completedAt,
      );

  /// Returns a new [HabitLog] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HabitLog? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "HabitLog[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "HabitLog[id]" has a null value in JSON.');
        assert(json.containsKey(r'habitId'),
            'Required key "HabitLog[habitId]" is missing from JSON.');
        assert(json[r'habitId'] != null,
            'Required key "HabitLog[habitId]" has a null value in JSON.');
        assert(json.containsKey(r'date'),
            'Required key "HabitLog[date]" is missing from JSON.');
        assert(json[r'date'] != null,
            'Required key "HabitLog[date]" has a null value in JSON.');
        assert(json.containsKey(r'count'),
            'Required key "HabitLog[count]" is missing from JSON.');
        assert(json[r'count'] != null,
            'Required key "HabitLog[count]" has a null value in JSON.');
        assert(json.containsKey(r'seconds'),
            'Required key "HabitLog[seconds]" is missing from JSON.');
        assert(json[r'seconds'] != null,
            'Required key "HabitLog[seconds]" has a null value in JSON.');
        assert(json.containsKey(r'runningSince'),
            'Required key "HabitLog[runningSince]" is missing from JSON.');
        assert(json.containsKey(r'completedAt'),
            'Required key "HabitLog[completedAt]" is missing from JSON.');
        return true;
      }());

      return HabitLog(
        id: mapValueOfType<String>(json, r'id')!,
        habitId: mapValueOfType<String>(json, r'habitId')!,
        date: mapValueOfType<String>(json, r'date')!,
        count: mapValueOfType<int>(json, r'count')!,
        seconds: mapValueOfType<int>(json, r'seconds')!,
        runningSince: mapDateTime(json, r'runningSince', r''),
        completedAt: mapDateTime(json, r'completedAt', r''),
      );
    }
    return null;
  }

  static List<HabitLog> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HabitLog>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HabitLog.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HabitLog> mapFromJson(dynamic json) {
    final map = <String, HabitLog>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HabitLog.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HabitLog-objects as value to a dart map
  static Map<String, List<HabitLog>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<HabitLog>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HabitLog.listFromJson(
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
    'habitId',
    'date',
    'count',
    'seconds',
    'runningSince',
    'completedAt',
  };
}
