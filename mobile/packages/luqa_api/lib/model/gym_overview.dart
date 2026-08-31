//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GymOverview {
  /// Returns a new [GymOverview] instance.
  GymOverview({
    this.locations = const [],
    this.exercises = const [],
    this.recentReferences = const [],
    this.sessions = const [],
    required this.totalSessions,
  });

  final List<GymLocation> locations;

  final List<GymExercise> exercises;

  final List<GymExerciseReference> recentReferences;

  final List<GymSession> sessions;

  final int totalSessions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymOverview &&
          _deepEquality.equals(other.locations, locations) &&
          _deepEquality.equals(other.exercises, exercises) &&
          _deepEquality.equals(other.recentReferences, recentReferences) &&
          _deepEquality.equals(other.sessions, sessions) &&
          other.totalSessions == totalSessions;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (locations.hashCode) +
      (exercises.hashCode) +
      (recentReferences.hashCode) +
      (sessions.hashCode) +
      (totalSessions.hashCode);

  @override
  String toString() =>
      'GymOverview[locations=$locations, exercises=$exercises, recentReferences=$recentReferences, sessions=$sessions, totalSessions=$totalSessions]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'locations'] = this.locations;
    json[r'exercises'] = this.exercises;
    json[r'recentReferences'] = this.recentReferences;
    json[r'sessions'] = this.sessions;
    json[r'totalSessions'] = this.totalSessions;
    return json;
  }

  /// Clones this instance of [GymOverview] and returns a new one where some of the
  /// properties have changed.
  GymOverview copyWith({
    List<GymLocation>? locations,
    List<GymExercise>? exercises,
    List<GymExerciseReference>? recentReferences,
    List<GymSession>? sessions,
    int? totalSessions,
  }) =>
      GymOverview(
        locations: locations ?? this.locations,
        exercises: exercises ?? this.exercises,
        recentReferences: recentReferences ?? this.recentReferences,
        sessions: sessions ?? this.sessions,
        totalSessions: totalSessions ?? this.totalSessions,
      );

  /// Returns a new [GymOverview] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GymOverview? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'locations'),
            'Required key "GymOverview[locations]" is missing from JSON.');
        assert(json[r'locations'] != null,
            'Required key "GymOverview[locations]" has a null value in JSON.');
        assert(json.containsKey(r'exercises'),
            'Required key "GymOverview[exercises]" is missing from JSON.');
        assert(json[r'exercises'] != null,
            'Required key "GymOverview[exercises]" has a null value in JSON.');
        assert(json.containsKey(r'recentReferences'),
            'Required key "GymOverview[recentReferences]" is missing from JSON.');
        assert(json[r'recentReferences'] != null,
            'Required key "GymOverview[recentReferences]" has a null value in JSON.');
        assert(json.containsKey(r'sessions'),
            'Required key "GymOverview[sessions]" is missing from JSON.');
        assert(json[r'sessions'] != null,
            'Required key "GymOverview[sessions]" has a null value in JSON.');
        assert(json.containsKey(r'totalSessions'),
            'Required key "GymOverview[totalSessions]" is missing from JSON.');
        assert(json[r'totalSessions'] != null,
            'Required key "GymOverview[totalSessions]" has a null value in JSON.');
        return true;
      }());

      return GymOverview(
        locations: GymLocation.listFromJson(json[r'locations']),
        exercises: GymExercise.listFromJson(json[r'exercises']),
        recentReferences:
            GymExerciseReference.listFromJson(json[r'recentReferences']),
        sessions: GymSession.listFromJson(json[r'sessions']),
        totalSessions: mapValueOfType<int>(json, r'totalSessions')!,
      );
    }
    return null;
  }

  static List<GymOverview> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GymOverview>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GymOverview.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GymOverview> mapFromJson(dynamic json) {
    final map = <String, GymOverview>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GymOverview.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GymOverview-objects as value to a dart map
  static Map<String, List<GymOverview>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GymOverview>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GymOverview.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'locations',
    'exercises',
    'recentReferences',
    'sessions',
    'totalSessions',
  };
}
