//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GymExerciseReference {
  /// Returns a new [GymExerciseReference] instance.
  GymExerciseReference({
    required this.exerciseId,
    required this.sessionId,
    required this.date,
    required this.locationId,
    required this.raw,
    required this.notes,
    this.sets = const [],
  });

  final String exerciseId;

  final String sessionId;

  final String date;

  final String? locationId;

  final String raw;

  final String notes;

  final List<GymSet> sets;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymExerciseReference &&
          other.exerciseId == exerciseId &&
          other.sessionId == sessionId &&
          other.date == date &&
          other.locationId == locationId &&
          other.raw == raw &&
          other.notes == notes &&
          _deepEquality.equals(other.sets, sets);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (exerciseId.hashCode) +
      (sessionId.hashCode) +
      (date.hashCode) +
      (locationId == null ? 0 : locationId!.hashCode) +
      (raw.hashCode) +
      (notes.hashCode) +
      (sets.hashCode);

  @override
  String toString() =>
      'GymExerciseReference[exerciseId=$exerciseId, sessionId=$sessionId, date=$date, locationId=$locationId, raw=$raw, notes=$notes, sets=$sets]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'exerciseId'] = this.exerciseId;
    json[r'sessionId'] = this.sessionId;
    json[r'date'] = this.date;
    if (this.locationId != null) {
      json[r'locationId'] = this.locationId;
    } else {
      json[r'locationId'] = null;
    }
    json[r'raw'] = this.raw;
    json[r'notes'] = this.notes;
    json[r'sets'] = this.sets;
    return json;
  }

  /// Clones this instance of [GymExerciseReference] and returns a new one where some of the
  /// properties have changed.
  GymExerciseReference copyWith({
    String? exerciseId,
    String? sessionId,
    String? date,
    String? locationId,
    bool locationIdSetToNull = false,
    String? raw,
    String? notes,
    List<GymSet>? sets,
  }) =>
      GymExerciseReference(
        exerciseId: exerciseId ?? this.exerciseId,
        sessionId: sessionId ?? this.sessionId,
        date: date ?? this.date,
        locationId: locationIdSetToNull ? null : locationId ?? this.locationId,
        raw: raw ?? this.raw,
        notes: notes ?? this.notes,
        sets: sets ?? this.sets,
      );

  /// Returns a new [GymExerciseReference] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GymExerciseReference? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'exerciseId'),
            'Required key "GymExerciseReference[exerciseId]" is missing from JSON.');
        assert(json[r'exerciseId'] != null,
            'Required key "GymExerciseReference[exerciseId]" has a null value in JSON.');
        assert(json.containsKey(r'sessionId'),
            'Required key "GymExerciseReference[sessionId]" is missing from JSON.');
        assert(json[r'sessionId'] != null,
            'Required key "GymExerciseReference[sessionId]" has a null value in JSON.');
        assert(json.containsKey(r'date'),
            'Required key "GymExerciseReference[date]" is missing from JSON.');
        assert(json[r'date'] != null,
            'Required key "GymExerciseReference[date]" has a null value in JSON.');
        assert(json.containsKey(r'locationId'),
            'Required key "GymExerciseReference[locationId]" is missing from JSON.');
        assert(json.containsKey(r'raw'),
            'Required key "GymExerciseReference[raw]" is missing from JSON.');
        assert(json[r'raw'] != null,
            'Required key "GymExerciseReference[raw]" has a null value in JSON.');
        assert(json.containsKey(r'notes'),
            'Required key "GymExerciseReference[notes]" is missing from JSON.');
        assert(json[r'notes'] != null,
            'Required key "GymExerciseReference[notes]" has a null value in JSON.');
        assert(json.containsKey(r'sets'),
            'Required key "GymExerciseReference[sets]" is missing from JSON.');
        assert(json[r'sets'] != null,
            'Required key "GymExerciseReference[sets]" has a null value in JSON.');
        return true;
      }());

      return GymExerciseReference(
        exerciseId: mapValueOfType<String>(json, r'exerciseId')!,
        sessionId: mapValueOfType<String>(json, r'sessionId')!,
        date: mapValueOfType<String>(json, r'date')!,
        locationId: mapValueOfType<String>(json, r'locationId'),
        raw: mapValueOfType<String>(json, r'raw')!,
        notes: mapValueOfType<String>(json, r'notes')!,
        sets: GymSet.listFromJson(json[r'sets']),
      );
    }
    return null;
  }

  static List<GymExerciseReference> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GymExerciseReference>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GymExerciseReference.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GymExerciseReference> mapFromJson(dynamic json) {
    final map = <String, GymExerciseReference>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GymExerciseReference.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GymExerciseReference-objects as value to a dart map
  static Map<String, List<GymExerciseReference>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GymExerciseReference>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GymExerciseReference.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'exerciseId',
    'sessionId',
    'date',
    'locationId',
    'raw',
    'notes',
    'sets',
  };
}
