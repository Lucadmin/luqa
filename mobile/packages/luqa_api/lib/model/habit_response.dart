//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HabitResponse {
  /// Returns a new [HabitResponse] instance.
  HabitResponse({
    required this.habit,
  });

  final Habit habit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HabitResponse && other.habit == habit;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (habit.hashCode);

  @override
  String toString() => 'HabitResponse[habit=$habit]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'habit'] = this.habit;
    return json;
  }

  /// Clones this instance of [HabitResponse] and returns a new one where some of the
  /// properties have changed.
  HabitResponse copyWith({
    Habit? habit,
  }) =>
      HabitResponse(
        habit: habit ?? this.habit,
      );

  /// Returns a new [HabitResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HabitResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'habit'),
            'Required key "HabitResponse[habit]" is missing from JSON.');
        assert(json[r'habit'] != null,
            'Required key "HabitResponse[habit]" has a null value in JSON.');
        return true;
      }());

      return HabitResponse(
        habit: Habit.fromJson(json[r'habit'])!,
      );
    }
    return null;
  }

  static List<HabitResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HabitResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HabitResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HabitResponse> mapFromJson(dynamic json) {
    final map = <String, HabitResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HabitResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HabitResponse-objects as value to a dart map
  static Map<String, List<HabitResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<HabitResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HabitResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'habit',
  };
}
