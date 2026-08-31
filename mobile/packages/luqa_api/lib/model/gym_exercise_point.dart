//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GymExercisePoint {
  /// Returns a new [GymExercisePoint] instance.
  GymExercisePoint({
    required this.sessionId,
    required this.date,
    required this.locationId,
    required this.raw,
    required this.notes,
    this.sets = const [],
    required this.topWeight,
    required this.best1RM,
    required this.totalReps,
    required this.volume,
    required this.isPr,
  });

  final String sessionId;

  final String date;

  final String? locationId;

  final String raw;

  final String notes;

  final List<GymSet> sets;

  final num? topWeight;

  final num? best1RM;

  final int totalReps;

  final num volume;

  final bool isPr;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymExercisePoint &&
          other.sessionId == sessionId &&
          other.date == date &&
          other.locationId == locationId &&
          other.raw == raw &&
          other.notes == notes &&
          _deepEquality.equals(other.sets, sets) &&
          other.topWeight == topWeight &&
          other.best1RM == best1RM &&
          other.totalReps == totalReps &&
          other.volume == volume &&
          other.isPr == isPr;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (sessionId.hashCode) +
      (date.hashCode) +
      (locationId == null ? 0 : locationId!.hashCode) +
      (raw.hashCode) +
      (notes.hashCode) +
      (sets.hashCode) +
      (topWeight == null ? 0 : topWeight!.hashCode) +
      (best1RM == null ? 0 : best1RM!.hashCode) +
      (totalReps.hashCode) +
      (volume.hashCode) +
      (isPr.hashCode);

  @override
  String toString() =>
      'GymExercisePoint[sessionId=$sessionId, date=$date, locationId=$locationId, raw=$raw, notes=$notes, sets=$sets, topWeight=$topWeight, best1RM=$best1RM, totalReps=$totalReps, volume=$volume, isPr=$isPr]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
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
    if (this.topWeight != null) {
      json[r'topWeight'] = this.topWeight;
    } else {
      json[r'topWeight'] = null;
    }
    if (this.best1RM != null) {
      json[r'best1RM'] = this.best1RM;
    } else {
      json[r'best1RM'] = null;
    }
    json[r'totalReps'] = this.totalReps;
    json[r'volume'] = this.volume;
    json[r'isPr'] = this.isPr;
    return json;
  }

  /// Clones this instance of [GymExercisePoint] and returns a new one where some of the
  /// properties have changed.
  GymExercisePoint copyWith({
    String? sessionId,
    String? date,
    String? locationId,
    bool locationIdSetToNull = false,
    String? raw,
    String? notes,
    List<GymSet>? sets,
    num? topWeight,
    bool topWeightSetToNull = false,
    num? best1RM,
    bool best1RMSetToNull = false,
    int? totalReps,
    num? volume,
    bool? isPr,
  }) =>
      GymExercisePoint(
        sessionId: sessionId ?? this.sessionId,
        date: date ?? this.date,
        locationId: locationIdSetToNull ? null : locationId ?? this.locationId,
        raw: raw ?? this.raw,
        notes: notes ?? this.notes,
        sets: sets ?? this.sets,
        topWeight: topWeightSetToNull ? null : topWeight ?? this.topWeight,
        best1RM: best1RMSetToNull ? null : best1RM ?? this.best1RM,
        totalReps: totalReps ?? this.totalReps,
        volume: volume ?? this.volume,
        isPr: isPr ?? this.isPr,
      );

  /// Returns a new [GymExercisePoint] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GymExercisePoint? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'sessionId'),
            'Required key "GymExercisePoint[sessionId]" is missing from JSON.');
        assert(json[r'sessionId'] != null,
            'Required key "GymExercisePoint[sessionId]" has a null value in JSON.');
        assert(json.containsKey(r'date'),
            'Required key "GymExercisePoint[date]" is missing from JSON.');
        assert(json[r'date'] != null,
            'Required key "GymExercisePoint[date]" has a null value in JSON.');
        assert(json.containsKey(r'locationId'),
            'Required key "GymExercisePoint[locationId]" is missing from JSON.');
        assert(json.containsKey(r'raw'),
            'Required key "GymExercisePoint[raw]" is missing from JSON.');
        assert(json[r'raw'] != null,
            'Required key "GymExercisePoint[raw]" has a null value in JSON.');
        assert(json.containsKey(r'notes'),
            'Required key "GymExercisePoint[notes]" is missing from JSON.');
        assert(json[r'notes'] != null,
            'Required key "GymExercisePoint[notes]" has a null value in JSON.');
        assert(json.containsKey(r'sets'),
            'Required key "GymExercisePoint[sets]" is missing from JSON.');
        assert(json[r'sets'] != null,
            'Required key "GymExercisePoint[sets]" has a null value in JSON.');
        assert(json.containsKey(r'topWeight'),
            'Required key "GymExercisePoint[topWeight]" is missing from JSON.');
        assert(json.containsKey(r'best1RM'),
            'Required key "GymExercisePoint[best1RM]" is missing from JSON.');
        assert(json.containsKey(r'totalReps'),
            'Required key "GymExercisePoint[totalReps]" is missing from JSON.');
        assert(json[r'totalReps'] != null,
            'Required key "GymExercisePoint[totalReps]" has a null value in JSON.');
        assert(json.containsKey(r'volume'),
            'Required key "GymExercisePoint[volume]" is missing from JSON.');
        assert(json[r'volume'] != null,
            'Required key "GymExercisePoint[volume]" has a null value in JSON.');
        assert(json.containsKey(r'isPr'),
            'Required key "GymExercisePoint[isPr]" is missing from JSON.');
        assert(json[r'isPr'] != null,
            'Required key "GymExercisePoint[isPr]" has a null value in JSON.');
        return true;
      }());

      return GymExercisePoint(
        sessionId: mapValueOfType<String>(json, r'sessionId')!,
        date: mapValueOfType<String>(json, r'date')!,
        locationId: mapValueOfType<String>(json, r'locationId'),
        raw: mapValueOfType<String>(json, r'raw')!,
        notes: mapValueOfType<String>(json, r'notes')!,
        sets: GymSet.listFromJson(json[r'sets']),
        topWeight: json[r'topWeight'] == null
            ? null
            : num.parse('${json[r'topWeight']}'),
        best1RM:
            json[r'best1RM'] == null ? null : num.parse('${json[r'best1RM']}'),
        totalReps: mapValueOfType<int>(json, r'totalReps')!,
        volume: num.parse('${json[r'volume']}'),
        isPr: mapValueOfType<bool>(json, r'isPr')!,
      );
    }
    return null;
  }

  static List<GymExercisePoint> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GymExercisePoint>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GymExercisePoint.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GymExercisePoint> mapFromJson(dynamic json) {
    final map = <String, GymExercisePoint>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GymExercisePoint.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GymExercisePoint-objects as value to a dart map
  static Map<String, List<GymExercisePoint>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GymExercisePoint>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GymExercisePoint.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'sessionId',
    'date',
    'locationId',
    'raw',
    'notes',
    'sets',
    'topWeight',
    'best1RM',
    'totalReps',
    'volume',
    'isPr',
  };
}
