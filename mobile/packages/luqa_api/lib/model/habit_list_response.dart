//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HabitListResponse {
  /// Returns a new [HabitListResponse] instance.
  HabitListResponse({
    this.habits = const [],
  });

  final List<Habit> habits;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitListResponse && _deepEquality.equals(other.habits, habits);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (habits.hashCode);

  @override
  String toString() => 'HabitListResponse[habits=$habits]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'habits'] = this.habits;
    return json;
  }

  /// Clones this instance of [HabitListResponse] and returns a new one where some of the
  /// properties have changed.
  HabitListResponse copyWith({
    List<Habit>? habits,
  }) =>
      HabitListResponse(
        habits: habits ?? this.habits,
      );

  /// Returns a new [HabitListResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HabitListResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'habits'),
            'Required key "HabitListResponse[habits]" is missing from JSON.');
        assert(json[r'habits'] != null,
            'Required key "HabitListResponse[habits]" has a null value in JSON.');
        return true;
      }());

      return HabitListResponse(
        habits: Habit.listFromJson(json[r'habits']),
      );
    }
    return null;
  }

  static List<HabitListResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HabitListResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HabitListResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HabitListResponse> mapFromJson(dynamic json) {
    final map = <String, HabitListResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HabitListResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HabitListResponse-objects as value to a dart map
  static Map<String, List<HabitListResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<HabitListResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HabitListResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'habits',
  };
}
