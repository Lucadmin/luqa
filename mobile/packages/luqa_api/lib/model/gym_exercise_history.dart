//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GymExerciseHistory {
  /// Returns a new [GymExerciseHistory] instance.
  GymExerciseHistory({
    required this.exercise,
    this.points = const [],
    required this.bestEver,
    required this.heaviest,
  });

  final GymExercise exercise;

  final List<GymExercisePoint> points;

  final num? bestEver;

  final num? heaviest;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymExerciseHistory &&
          other.exercise == exercise &&
          _deepEquality.equals(other.points, points) &&
          other.bestEver == bestEver &&
          other.heaviest == heaviest;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (exercise.hashCode) +
      (points.hashCode) +
      (bestEver == null ? 0 : bestEver!.hashCode) +
      (heaviest == null ? 0 : heaviest!.hashCode);

  @override
  String toString() =>
      'GymExerciseHistory[exercise=$exercise, points=$points, bestEver=$bestEver, heaviest=$heaviest]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'exercise'] = this.exercise;
    json[r'points'] = this.points;
    if (this.bestEver != null) {
      json[r'bestEver'] = this.bestEver;
    } else {
      json[r'bestEver'] = null;
    }
    if (this.heaviest != null) {
      json[r'heaviest'] = this.heaviest;
    } else {
      json[r'heaviest'] = null;
    }
    return json;
  }

  /// Clones this instance of [GymExerciseHistory] and returns a new one where some of the
  /// properties have changed.
  GymExerciseHistory copyWith({
    GymExercise? exercise,
    List<GymExercisePoint>? points,
    num? bestEver,
    bool bestEverSetToNull = false,
    num? heaviest,
    bool heaviestSetToNull = false,
  }) =>
      GymExerciseHistory(
        exercise: exercise ?? this.exercise,
        points: points ?? this.points,
        bestEver: bestEverSetToNull ? null : bestEver ?? this.bestEver,
        heaviest: heaviestSetToNull ? null : heaviest ?? this.heaviest,
      );

  /// Returns a new [GymExerciseHistory] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GymExerciseHistory? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'exercise'),
            'Required key "GymExerciseHistory[exercise]" is missing from JSON.');
        assert(json[r'exercise'] != null,
            'Required key "GymExerciseHistory[exercise]" has a null value in JSON.');
        assert(json.containsKey(r'points'),
            'Required key "GymExerciseHistory[points]" is missing from JSON.');
        assert(json[r'points'] != null,
            'Required key "GymExerciseHistory[points]" has a null value in JSON.');
        assert(json.containsKey(r'bestEver'),
            'Required key "GymExerciseHistory[bestEver]" is missing from JSON.');
        assert(json.containsKey(r'heaviest'),
            'Required key "GymExerciseHistory[heaviest]" is missing from JSON.');
        return true;
      }());

      return GymExerciseHistory(
        exercise: GymExercise.fromJson(json[r'exercise'])!,
        points: GymExercisePoint.listFromJson(json[r'points']),
        bestEver: json[r'bestEver'] == null
            ? null
            : num.parse('${json[r'bestEver']}'),
        heaviest: json[r'heaviest'] == null
            ? null
            : num.parse('${json[r'heaviest']}'),
      );
    }
    return null;
  }

  static List<GymExerciseHistory> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GymExerciseHistory>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GymExerciseHistory.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GymExerciseHistory> mapFromJson(dynamic json) {
    final map = <String, GymExerciseHistory>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GymExerciseHistory.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GymExerciseHistory-objects as value to a dart map
  static Map<String, List<GymExerciseHistory>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GymExerciseHistory>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GymExerciseHistory.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'exercise',
    'points',
    'bestEver',
    'heaviest',
  };
}
