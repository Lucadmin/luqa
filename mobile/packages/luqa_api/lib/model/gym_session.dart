//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GymSession {
  /// Returns a new [GymSession] instance.
  GymSession({
    required this.id,
    required this.date,
    required this.locationId,
    required this.notes,
    this.exercises = const [],
    required this.createdAt,
  });

  final String id;

  final String date;

  final String? locationId;

  final String notes;

  final List<GymSessionExercise> exercises;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymSession &&
          other.id == id &&
          other.date == date &&
          other.locationId == locationId &&
          other.notes == notes &&
          _deepEquality.equals(other.exercises, exercises) &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (date.hashCode) +
      (locationId == null ? 0 : locationId!.hashCode) +
      (notes.hashCode) +
      (exercises.hashCode) +
      (createdAt.hashCode);

  @override
  String toString() =>
      'GymSession[id=$id, date=$date, locationId=$locationId, notes=$notes, exercises=$exercises, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'date'] = this.date;
    if (this.locationId != null) {
      json[r'locationId'] = this.locationId;
    } else {
      json[r'locationId'] = null;
    }
    json[r'notes'] = this.notes;
    json[r'exercises'] = this.exercises;
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [GymSession] and returns a new one where some of the
  /// properties have changed.
  GymSession copyWith({
    String? id,
    String? date,
    String? locationId,
    bool locationIdSetToNull = false,
    String? notes,
    List<GymSessionExercise>? exercises,
    DateTime? createdAt,
  }) =>
      GymSession(
        id: id ?? this.id,
        date: date ?? this.date,
        locationId: locationIdSetToNull ? null : locationId ?? this.locationId,
        notes: notes ?? this.notes,
        exercises: exercises ?? this.exercises,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Returns a new [GymSession] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GymSession? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "GymSession[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "GymSession[id]" has a null value in JSON.');
        assert(json.containsKey(r'date'),
            'Required key "GymSession[date]" is missing from JSON.');
        assert(json[r'date'] != null,
            'Required key "GymSession[date]" has a null value in JSON.');
        assert(json.containsKey(r'locationId'),
            'Required key "GymSession[locationId]" is missing from JSON.');
        assert(json.containsKey(r'notes'),
            'Required key "GymSession[notes]" is missing from JSON.');
        assert(json[r'notes'] != null,
            'Required key "GymSession[notes]" has a null value in JSON.');
        assert(json.containsKey(r'exercises'),
            'Required key "GymSession[exercises]" is missing from JSON.');
        assert(json[r'exercises'] != null,
            'Required key "GymSession[exercises]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'),
            'Required key "GymSession[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null,
            'Required key "GymSession[createdAt]" has a null value in JSON.');
        return true;
      }());

      return GymSession(
        id: mapValueOfType<String>(json, r'id')!,
        date: mapValueOfType<String>(json, r'date')!,
        locationId: mapValueOfType<String>(json, r'locationId'),
        notes: mapValueOfType<String>(json, r'notes')!,
        exercises: GymSessionExercise.listFromJson(json[r'exercises']),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<GymSession> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GymSession>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GymSession.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GymSession> mapFromJson(dynamic json) {
    final map = <String, GymSession>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GymSession.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GymSession-objects as value to a dart map
  static Map<String, List<GymSession>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GymSession>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GymSession.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'date',
    'locationId',
    'notes',
    'exercises',
    'createdAt',
  };
}
