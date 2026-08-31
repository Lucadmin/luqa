//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GymSessionExerciseInput {
  /// Returns a new [GymSessionExerciseInput] instance.
  GymSessionExerciseInput({
    this.exerciseId = const Optional.absent(),
    this.name = const Optional.absent(),
    this.sets = const Optional.present(const []),
    this.notes = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> exerciseId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> name;

  final Optional<List<GymSetInput>?> sets;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> notes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymSessionExerciseInput &&
          other.exerciseId == exerciseId &&
          other.name == name &&
          _deepEquality.equals(other.sets, sets) &&
          other.notes == notes;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (exerciseId == null ? 0 : exerciseId!.hashCode) +
      (name == null ? 0 : name!.hashCode) +
      (sets.hashCode) +
      (notes == null ? 0 : notes!.hashCode);

  @override
  String toString() =>
      'GymSessionExerciseInput[exerciseId=$exerciseId, name=$name, sets=$sets, notes=$notes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.exerciseId.isPresent) {
      final value = this.exerciseId.value;
      json[r'exerciseId'] = value;
    }
    if (this.name.isPresent) {
      final value = this.name.value;
      json[r'name'] = value;
    }
    if (this.sets.isPresent) {
      final value = this.sets.value;
      json[r'sets'] = value;
    }
    if (this.notes.isPresent) {
      final value = this.notes.value;
      json[r'notes'] = value;
    }
    return json;
  }

  /// Clones this instance of [GymSessionExerciseInput] and returns a new one where some of the
  /// properties have changed.
  GymSessionExerciseInput copyWith({
    Optional<String?>? exerciseId,
    Optional<String?>? name,
    Optional<List<GymSetInput>?>? sets,
    Optional<String?>? notes,
  }) =>
      GymSessionExerciseInput(
        exerciseId: exerciseId ?? this.exerciseId,
        name: name ?? this.name,
        sets: sets ?? this.sets,
        notes: notes ?? this.notes,
      );

  /// Returns a new [GymSessionExerciseInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GymSessionExerciseInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return GymSessionExerciseInput(
        exerciseId: json.containsKey(r'exerciseId')
            ? Optional.present(mapValueOfType<String>(json, r'exerciseId'))
            : const Optional.absent(),
        name: json.containsKey(r'name')
            ? Optional.present(mapValueOfType<String>(json, r'name'))
            : const Optional.absent(),
        sets: json.containsKey(r'sets')
            ? Optional.present(GymSetInput.listFromJson(json[r'sets']))
            : const Optional.absent(),
        notes: json.containsKey(r'notes')
            ? Optional.present(mapValueOfType<String>(json, r'notes'))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<GymSessionExerciseInput> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GymSessionExerciseInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GymSessionExerciseInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GymSessionExerciseInput> mapFromJson(dynamic json) {
    final map = <String, GymSessionExerciseInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GymSessionExerciseInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GymSessionExerciseInput-objects as value to a dart map
  static Map<String, List<GymSessionExerciseInput>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GymSessionExerciseInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GymSessionExerciseInput.listFromJson(
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
