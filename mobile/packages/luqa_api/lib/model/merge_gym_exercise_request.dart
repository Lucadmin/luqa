//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MergeGymExerciseRequest {
  /// Returns a new [MergeGymExerciseRequest] instance.
  MergeGymExerciseRequest({
    required this.targetExerciseId,
  });

  final String targetExerciseId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MergeGymExerciseRequest &&
          other.targetExerciseId == targetExerciseId;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (targetExerciseId.hashCode);

  @override
  String toString() =>
      'MergeGymExerciseRequest[targetExerciseId=$targetExerciseId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'targetExerciseId'] = this.targetExerciseId;
    return json;
  }

  /// Clones this instance of [MergeGymExerciseRequest] and returns a new one where some of the
  /// properties have changed.
  MergeGymExerciseRequest copyWith({
    String? targetExerciseId,
  }) =>
      MergeGymExerciseRequest(
        targetExerciseId: targetExerciseId ?? this.targetExerciseId,
      );

  /// Returns a new [MergeGymExerciseRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MergeGymExerciseRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'targetExerciseId'),
            'Required key "MergeGymExerciseRequest[targetExerciseId]" is missing from JSON.');
        assert(json[r'targetExerciseId'] != null,
            'Required key "MergeGymExerciseRequest[targetExerciseId]" has a null value in JSON.');
        return true;
      }());

      return MergeGymExerciseRequest(
        targetExerciseId: mapValueOfType<String>(json, r'targetExerciseId')!,
      );
    }
    return null;
  }

  static List<MergeGymExerciseRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MergeGymExerciseRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MergeGymExerciseRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MergeGymExerciseRequest> mapFromJson(dynamic json) {
    final map = <String, MergeGymExerciseRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MergeGymExerciseRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MergeGymExerciseRequest-objects as value to a dart map
  static Map<String, List<MergeGymExerciseRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MergeGymExerciseRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MergeGymExerciseRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'targetExerciseId',
  };
}
