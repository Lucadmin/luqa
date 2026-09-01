//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UpdateGymExerciseRequest {
  /// Returns a new [UpdateGymExerciseRequest] instance.
  UpdateGymExerciseRequest({
    this.name = const Optional.absent(),
    this.notes = const Optional.absent(),
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
  final Optional<String?> notes;

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
      other is UpdateGymExerciseRequest &&
          other.name == name &&
          other.notes == notes &&
          other.archived == archived;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name == null ? 0 : name!.hashCode) +
      (notes == null ? 0 : notes!.hashCode) +
      (archived == null ? 0 : archived!.hashCode);

  @override
  String toString() =>
      'UpdateGymExerciseRequest[name=$name, notes=$notes, archived=$archived]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name.isPresent) {
      final value = this.name.value;
      json[r'name'] = value;
    }
    if (this.notes.isPresent) {
      final value = this.notes.value;
      json[r'notes'] = value;
    }
    if (this.archived.isPresent) {
      final value = this.archived.value;
      json[r'archived'] = value;
    }
    return json;
  }

  /// Clones this instance of [UpdateGymExerciseRequest] and returns a new one where some of the
  /// properties have changed.
  UpdateGymExerciseRequest copyWith({
    Optional<String?>? name,
    Optional<String?>? notes,
    Optional<bool?>? archived,
  }) =>
      UpdateGymExerciseRequest(
        name: name ?? this.name,
        notes: notes ?? this.notes,
        archived: archived ?? this.archived,
      );

  /// Returns a new [UpdateGymExerciseRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateGymExerciseRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UpdateGymExerciseRequest(
        name: json.containsKey(r'name')
            ? Optional.present(mapValueOfType<String>(json, r'name'))
            : const Optional.absent(),
        notes: json.containsKey(r'notes')
            ? Optional.present(mapValueOfType<String>(json, r'notes'))
            : const Optional.absent(),
        archived: json.containsKey(r'archived')
            ? Optional.present(mapValueOfType<bool>(json, r'archived'))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<UpdateGymExerciseRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UpdateGymExerciseRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateGymExerciseRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateGymExerciseRequest> mapFromJson(dynamic json) {
    final map = <String, UpdateGymExerciseRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateGymExerciseRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateGymExerciseRequest-objects as value to a dart map
  static Map<String, List<UpdateGymExerciseRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UpdateGymExerciseRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateGymExerciseRequest.listFromJson(
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
