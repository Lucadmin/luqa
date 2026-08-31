//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GymExerciseMergeResponse {
  /// Returns a new [GymExerciseMergeResponse] instance.
  GymExerciseMergeResponse({
    required this.exercise,
    required this.mergedExerciseId,
    required this.movedEntries,
  });

  final GymExercise exercise;

  final String mergedExerciseId;

  /// Minimum value: 0
  final int movedEntries;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymExerciseMergeResponse &&
          other.exercise == exercise &&
          other.mergedExerciseId == mergedExerciseId &&
          other.movedEntries == movedEntries;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (exercise.hashCode) +
      (mergedExerciseId.hashCode) +
      (movedEntries.hashCode);

  @override
  String toString() =>
      'GymExerciseMergeResponse[exercise=$exercise, mergedExerciseId=$mergedExerciseId, movedEntries=$movedEntries]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'exercise'] = this.exercise;
    json[r'mergedExerciseId'] = this.mergedExerciseId;
    json[r'movedEntries'] = this.movedEntries;
    return json;
  }

  /// Clones this instance of [GymExerciseMergeResponse] and returns a new one where some of the
  /// properties have changed.
  GymExerciseMergeResponse copyWith({
    GymExercise? exercise,
    String? mergedExerciseId,
    int? movedEntries,
  }) =>
      GymExerciseMergeResponse(
        exercise: exercise ?? this.exercise,
        mergedExerciseId: mergedExerciseId ?? this.mergedExerciseId,
        movedEntries: movedEntries ?? this.movedEntries,
      );

  /// Returns a new [GymExerciseMergeResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GymExerciseMergeResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'exercise'),
            'Required key "GymExerciseMergeResponse[exercise]" is missing from JSON.');
        assert(json[r'exercise'] != null,
            'Required key "GymExerciseMergeResponse[exercise]" has a null value in JSON.');
        assert(json.containsKey(r'mergedExerciseId'),
            'Required key "GymExerciseMergeResponse[mergedExerciseId]" is missing from JSON.');
        assert(json[r'mergedExerciseId'] != null,
            'Required key "GymExerciseMergeResponse[mergedExerciseId]" has a null value in JSON.');
        assert(json.containsKey(r'movedEntries'),
            'Required key "GymExerciseMergeResponse[movedEntries]" is missing from JSON.');
        assert(json[r'movedEntries'] != null,
            'Required key "GymExerciseMergeResponse[movedEntries]" has a null value in JSON.');
        return true;
      }());

      return GymExerciseMergeResponse(
        exercise: GymExercise.fromJson(json[r'exercise'])!,
        mergedExerciseId: mapValueOfType<String>(json, r'mergedExerciseId')!,
        movedEntries: mapValueOfType<int>(json, r'movedEntries')!,
      );
    }
    return null;
  }

  static List<GymExerciseMergeResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GymExerciseMergeResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GymExerciseMergeResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GymExerciseMergeResponse> mapFromJson(dynamic json) {
    final map = <String, GymExerciseMergeResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GymExerciseMergeResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GymExerciseMergeResponse-objects as value to a dart map
  static Map<String, List<GymExerciseMergeResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GymExerciseMergeResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GymExerciseMergeResponse.listFromJson(
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
    'mergedExerciseId',
    'movedEntries',
  };
}
