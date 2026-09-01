//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DeleteGymExerciseResponse {
  /// Returns a new [DeleteGymExerciseResponse] instance.
  DeleteGymExerciseResponse({
    required this.deleted,
    required this.archived,
  });

  /// True when the exercise was removed outright.
  final bool deleted;

  /// True when logged workouts still reference it, so it was archived rather than removed.
  final bool archived;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeleteGymExerciseResponse &&
          other.deleted == deleted &&
          other.archived == archived;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (deleted.hashCode) + (archived.hashCode);

  @override
  String toString() =>
      'DeleteGymExerciseResponse[deleted=$deleted, archived=$archived]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'deleted'] = this.deleted;
    json[r'archived'] = this.archived;
    return json;
  }

  /// Clones this instance of [DeleteGymExerciseResponse] and returns a new one where some of the
  /// properties have changed.
  DeleteGymExerciseResponse copyWith({
    bool? deleted,
    bool? archived,
  }) =>
      DeleteGymExerciseResponse(
        deleted: deleted ?? this.deleted,
        archived: archived ?? this.archived,
      );

  /// Returns a new [DeleteGymExerciseResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DeleteGymExerciseResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'deleted'),
            'Required key "DeleteGymExerciseResponse[deleted]" is missing from JSON.');
        assert(json[r'deleted'] != null,
            'Required key "DeleteGymExerciseResponse[deleted]" has a null value in JSON.');
        assert(json.containsKey(r'archived'),
            'Required key "DeleteGymExerciseResponse[archived]" is missing from JSON.');
        assert(json[r'archived'] != null,
            'Required key "DeleteGymExerciseResponse[archived]" has a null value in JSON.');
        return true;
      }());

      return DeleteGymExerciseResponse(
        deleted: mapValueOfType<bool>(json, r'deleted')!,
        archived: mapValueOfType<bool>(json, r'archived')!,
      );
    }
    return null;
  }

  static List<DeleteGymExerciseResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <DeleteGymExerciseResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DeleteGymExerciseResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DeleteGymExerciseResponse> mapFromJson(dynamic json) {
    final map = <String, DeleteGymExerciseResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DeleteGymExerciseResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DeleteGymExerciseResponse-objects as value to a dart map
  static Map<String, List<DeleteGymExerciseResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<DeleteGymExerciseResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DeleteGymExerciseResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'deleted',
    'archived',
  };
}
