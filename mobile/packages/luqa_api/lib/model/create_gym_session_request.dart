//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateGymSessionRequest {
  /// Returns a new [CreateGymSessionRequest] instance.
  CreateGymSessionRequest({
    this.id = const Optional.absent(),
    this.date = const Optional.absent(),
    this.locationId = const Optional.absent(),
    this.notes = const Optional.absent(),
    this.exercises = const Optional.present(const []),
  });

  /// Client-minted identity for the workout, so one started with no signal can still be opened and saved into. Supplying it makes the create idempotent.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> id;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> date;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> locationId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> notes;

  final Optional<List<GymSessionExerciseInput>?> exercises;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateGymSessionRequest &&
          other.id == id &&
          other.date == date &&
          other.locationId == locationId &&
          other.notes == notes &&
          _deepEquality.equals(other.exercises, exercises);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id == null ? 0 : id!.hashCode) +
      (date == null ? 0 : date!.hashCode) +
      (locationId == null ? 0 : locationId!.hashCode) +
      (notes == null ? 0 : notes!.hashCode) +
      (exercises.hashCode);

  @override
  String toString() =>
      'CreateGymSessionRequest[id=$id, date=$date, locationId=$locationId, notes=$notes, exercises=$exercises]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id.isPresent) {
      final value = this.id.value;
      json[r'id'] = value;
    }
    if (this.date.isPresent) {
      final value = this.date.value;
      json[r'date'] = value;
    }
    if (this.locationId.isPresent) {
      final value = this.locationId.value;
      json[r'locationId'] = value;
    }
    if (this.notes.isPresent) {
      final value = this.notes.value;
      json[r'notes'] = value;
    }
    if (this.exercises.isPresent) {
      final value = this.exercises.value;
      json[r'exercises'] = value;
    }
    return json;
  }

  /// Clones this instance of [CreateGymSessionRequest] and returns a new one where some of the
  /// properties have changed.
  CreateGymSessionRequest copyWith({
    Optional<String?>? id,
    Optional<String?>? date,
    Optional<String?>? locationId,
    Optional<String?>? notes,
    Optional<List<GymSessionExerciseInput>?>? exercises,
  }) =>
      CreateGymSessionRequest(
        id: id ?? this.id,
        date: date ?? this.date,
        locationId: locationId ?? this.locationId,
        notes: notes ?? this.notes,
        exercises: exercises ?? this.exercises,
      );

  /// Returns a new [CreateGymSessionRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateGymSessionRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return CreateGymSessionRequest(
        id: json.containsKey(r'id')
            ? Optional.present(mapValueOfType<String>(json, r'id'))
            : const Optional.absent(),
        date: json.containsKey(r'date')
            ? Optional.present(mapValueOfType<String>(json, r'date'))
            : const Optional.absent(),
        locationId: json.containsKey(r'locationId')
            ? Optional.present(mapValueOfType<String>(json, r'locationId'))
            : const Optional.absent(),
        notes: json.containsKey(r'notes')
            ? Optional.present(mapValueOfType<String>(json, r'notes'))
            : const Optional.absent(),
        exercises: json.containsKey(r'exercises')
            ? Optional.present(
                GymSessionExerciseInput.listFromJson(json[r'exercises']))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<CreateGymSessionRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreateGymSessionRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateGymSessionRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateGymSessionRequest> mapFromJson(dynamic json) {
    final map = <String, CreateGymSessionRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateGymSessionRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateGymSessionRequest-objects as value to a dart map
  static Map<String, List<CreateGymSessionRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreateGymSessionRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateGymSessionRequest.listFromJson(
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
