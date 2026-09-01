//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GymExerciseUpdateResponse {
  /// Returns a new [GymExerciseUpdateResponse] instance.
  GymExerciseUpdateResponse({
    required this.exercise,
    required this.mergedInto,
  });

  final GymExercise exercise;

  /// Set when the new name already belonged to another exercise and the two were merged. `exercise` is then the survivor and the exercise in the path no longer exists.
  final String? mergedInto;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymExerciseUpdateResponse &&
          other.exercise == exercise &&
          other.mergedInto == mergedInto;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (exercise.hashCode) + (mergedInto == null ? 0 : mergedInto!.hashCode);

  @override
  String toString() =>
      'GymExerciseUpdateResponse[exercise=$exercise, mergedInto=$mergedInto]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'exercise'] = this.exercise;
    if (this.mergedInto != null) {
      json[r'mergedInto'] = this.mergedInto;
    } else {
      json[r'mergedInto'] = null;
    }
    return json;
  }

  /// Clones this instance of [GymExerciseUpdateResponse] and returns a new one where some of the
  /// properties have changed.
  GymExerciseUpdateResponse copyWith({
    GymExercise? exercise,
    String? mergedInto,
    bool mergedIntoSetToNull = false,
  }) =>
      GymExerciseUpdateResponse(
        exercise: exercise ?? this.exercise,
        mergedInto: mergedIntoSetToNull ? null : mergedInto ?? this.mergedInto,
      );

  /// Returns a new [GymExerciseUpdateResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GymExerciseUpdateResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'exercise'),
            'Required key "GymExerciseUpdateResponse[exercise]" is missing from JSON.');
        assert(json[r'exercise'] != null,
            'Required key "GymExerciseUpdateResponse[exercise]" has a null value in JSON.');
        assert(json.containsKey(r'mergedInto'),
            'Required key "GymExerciseUpdateResponse[mergedInto]" is missing from JSON.');
        return true;
      }());

      return GymExerciseUpdateResponse(
        exercise: GymExercise.fromJson(json[r'exercise'])!,
        mergedInto: mapValueOfType<String>(json, r'mergedInto'),
      );
    }
    return null;
  }

  static List<GymExerciseUpdateResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GymExerciseUpdateResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GymExerciseUpdateResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GymExerciseUpdateResponse> mapFromJson(dynamic json) {
    final map = <String, GymExerciseUpdateResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GymExerciseUpdateResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GymExerciseUpdateResponse-objects as value to a dart map
  static Map<String, List<GymExerciseUpdateResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GymExerciseUpdateResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GymExerciseUpdateResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'exercise',
    'mergedInto',
  };
}
