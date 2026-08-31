//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GymExercise {
  /// Returns a new [GymExercise] instance.
  GymExercise({
    required this.id,
    required this.name,
    required this.notes,
    required this.archived,
    required this.sessionCount,
    required this.lastPerformed,
    this.locationIds = const [],
    required this.lastRaw,
    required this.lastLocationId,
  });

  final String id;

  final String name;

  final String notes;

  final bool archived;

  final int sessionCount;

  final String? lastPerformed;

  final List<String> locationIds;

  final String? lastRaw;

  final String? lastLocationId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymExercise &&
          other.id == id &&
          other.name == name &&
          other.notes == notes &&
          other.archived == archived &&
          other.sessionCount == sessionCount &&
          other.lastPerformed == lastPerformed &&
          _deepEquality.equals(other.locationIds, locationIds) &&
          other.lastRaw == lastRaw &&
          other.lastLocationId == lastLocationId;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (name.hashCode) +
      (notes.hashCode) +
      (archived.hashCode) +
      (sessionCount.hashCode) +
      (lastPerformed == null ? 0 : lastPerformed!.hashCode) +
      (locationIds.hashCode) +
      (lastRaw == null ? 0 : lastRaw!.hashCode) +
      (lastLocationId == null ? 0 : lastLocationId!.hashCode);

  @override
  String toString() =>
      'GymExercise[id=$id, name=$name, notes=$notes, archived=$archived, sessionCount=$sessionCount, lastPerformed=$lastPerformed, locationIds=$locationIds, lastRaw=$lastRaw, lastLocationId=$lastLocationId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'name'] = this.name;
    json[r'notes'] = this.notes;
    json[r'archived'] = this.archived;
    json[r'sessionCount'] = this.sessionCount;
    if (this.lastPerformed != null) {
      json[r'lastPerformed'] = this.lastPerformed;
    } else {
      json[r'lastPerformed'] = null;
    }
    json[r'locationIds'] = this.locationIds;
    if (this.lastRaw != null) {
      json[r'lastRaw'] = this.lastRaw;
    } else {
      json[r'lastRaw'] = null;
    }
    if (this.lastLocationId != null) {
      json[r'lastLocationId'] = this.lastLocationId;
    } else {
      json[r'lastLocationId'] = null;
    }
    return json;
  }

  /// Clones this instance of [GymExercise] and returns a new one where some of the
  /// properties have changed.
  GymExercise copyWith({
    String? id,
    String? name,
    String? notes,
    bool? archived,
    int? sessionCount,
    String? lastPerformed,
    bool lastPerformedSetToNull = false,
    List<String>? locationIds,
    String? lastRaw,
    bool lastRawSetToNull = false,
    String? lastLocationId,
    bool lastLocationIdSetToNull = false,
  }) =>
      GymExercise(
        id: id ?? this.id,
        name: name ?? this.name,
        notes: notes ?? this.notes,
        archived: archived ?? this.archived,
        sessionCount: sessionCount ?? this.sessionCount,
        lastPerformed:
            lastPerformedSetToNull ? null : lastPerformed ?? this.lastPerformed,
        locationIds: locationIds ?? this.locationIds,
        lastRaw: lastRawSetToNull ? null : lastRaw ?? this.lastRaw,
        lastLocationId: lastLocationIdSetToNull
            ? null
            : lastLocationId ?? this.lastLocationId,
      );

  /// Returns a new [GymExercise] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GymExercise? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "GymExercise[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "GymExercise[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "GymExercise[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "GymExercise[name]" has a null value in JSON.');
        assert(json.containsKey(r'notes'),
            'Required key "GymExercise[notes]" is missing from JSON.');
        assert(json[r'notes'] != null,
            'Required key "GymExercise[notes]" has a null value in JSON.');
        assert(json.containsKey(r'archived'),
            'Required key "GymExercise[archived]" is missing from JSON.');
        assert(json[r'archived'] != null,
            'Required key "GymExercise[archived]" has a null value in JSON.');
        assert(json.containsKey(r'sessionCount'),
            'Required key "GymExercise[sessionCount]" is missing from JSON.');
        assert(json[r'sessionCount'] != null,
            'Required key "GymExercise[sessionCount]" has a null value in JSON.');
        assert(json.containsKey(r'lastPerformed'),
            'Required key "GymExercise[lastPerformed]" is missing from JSON.');
        assert(json.containsKey(r'locationIds'),
            'Required key "GymExercise[locationIds]" is missing from JSON.');
        assert(json[r'locationIds'] != null,
            'Required key "GymExercise[locationIds]" has a null value in JSON.');
        assert(json.containsKey(r'lastRaw'),
            'Required key "GymExercise[lastRaw]" is missing from JSON.');
        assert(json.containsKey(r'lastLocationId'),
            'Required key "GymExercise[lastLocationId]" is missing from JSON.');
        return true;
      }());

      return GymExercise(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        notes: mapValueOfType<String>(json, r'notes')!,
        archived: mapValueOfType<bool>(json, r'archived')!,
        sessionCount: mapValueOfType<int>(json, r'sessionCount')!,
        lastPerformed: mapValueOfType<String>(json, r'lastPerformed'),
        locationIds: json[r'locationIds'] is Iterable
            ? (json[r'locationIds'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        lastRaw: mapValueOfType<String>(json, r'lastRaw'),
        lastLocationId: mapValueOfType<String>(json, r'lastLocationId'),
      );
    }
    return null;
  }

  static List<GymExercise> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GymExercise>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GymExercise.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GymExercise> mapFromJson(dynamic json) {
    final map = <String, GymExercise>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GymExercise.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GymExercise-objects as value to a dart map
  static Map<String, List<GymExercise>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GymExercise>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GymExercise.listFromJson(
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
    'name',
    'notes',
    'archived',
    'sessionCount',
    'lastPerformed',
    'locationIds',
    'lastRaw',
    'lastLocationId',
  };
}
