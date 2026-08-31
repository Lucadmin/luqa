//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GymSetInput {
  /// Returns a new [GymSetInput] instance.
  GymSetInput({
    this.weight = const Optional.absent(),
    this.reps = const Optional.absent(),
    this.note = const Optional.absent(),
  });

  /// Minimum value: 0
  /// Maximum value: 2000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<num?> weight;

  /// Minimum value: 0
  /// Maximum value: 1000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> reps;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymSetInput &&
          other.weight == weight &&
          other.reps == reps &&
          other.note == note;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (weight == null ? 0 : weight!.hashCode) +
      (reps == null ? 0 : reps!.hashCode) +
      (note == null ? 0 : note!.hashCode);

  @override
  String toString() => 'GymSetInput[weight=$weight, reps=$reps, note=$note]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.weight.isPresent) {
      final value = this.weight.value;
      json[r'weight'] = value;
    }
    if (this.reps.isPresent) {
      final value = this.reps.value;
      json[r'reps'] = value;
    }
    if (this.note.isPresent) {
      final value = this.note.value;
      json[r'note'] = value;
    }
    return json;
  }

  /// Clones this instance of [GymSetInput] and returns a new one where some of the
  /// properties have changed.
  GymSetInput copyWith({
    Optional<num?>? weight,
    Optional<int?>? reps,
    Optional<String?>? note,
  }) =>
      GymSetInput(
        weight: weight ?? this.weight,
        reps: reps ?? this.reps,
        note: note ?? this.note,
      );

  /// Returns a new [GymSetInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GymSetInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return GymSetInput(
        weight: json.containsKey(r'weight')
            ? Optional.present(json[r'weight'] == null
                ? null
                : num.parse('${json[r'weight']}'))
            : const Optional.absent(),
        reps: json.containsKey(r'reps')
            ? Optional.present(
                json[r'reps'] == null ? null : int.parse('${json[r'reps']}'))
            : const Optional.absent(),
        note: json.containsKey(r'note')
            ? Optional.present(mapValueOfType<String>(json, r'note'))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<GymSetInput> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GymSetInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GymSetInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GymSetInput> mapFromJson(dynamic json) {
    final map = <String, GymSetInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GymSetInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GymSetInput-objects as value to a dart map
  static Map<String, List<GymSetInput>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GymSetInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GymSetInput.listFromJson(
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
