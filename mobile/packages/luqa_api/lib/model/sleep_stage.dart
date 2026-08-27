//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SleepStage {
  /// Returns a new [SleepStage] instance.
  SleepStage({
    required this.stage,
    required this.startTime,
    required this.endTime,
  });

  /// Provider stage name, normalized server-side (e.g. DEEP, REM, AWAKE_IN_BED).
  final String stage;

  final DateTime startTime;

  final DateTime endTime;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepStage &&
          other.stage == stage &&
          other.startTime == startTime &&
          other.endTime == endTime;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (stage.hashCode) + (startTime.hashCode) + (endTime.hashCode);

  @override
  String toString() =>
      'SleepStage[stage=$stage, startTime=$startTime, endTime=$endTime]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'stage'] = this.stage;
    json[r'startTime'] = this.startTime.toUtc().toIso8601String();
    json[r'endTime'] = this.endTime.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [SleepStage] and returns a new one where some of the
  /// properties have changed.
  SleepStage copyWith({
    String? stage,
    DateTime? startTime,
    DateTime? endTime,
  }) =>
      SleepStage(
        stage: stage ?? this.stage,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
      );

  /// Returns a new [SleepStage] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SleepStage? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'stage'),
            'Required key "SleepStage[stage]" is missing from JSON.');
        assert(json[r'stage'] != null,
            'Required key "SleepStage[stage]" has a null value in JSON.');
        assert(json.containsKey(r'startTime'),
            'Required key "SleepStage[startTime]" is missing from JSON.');
        assert(json[r'startTime'] != null,
            'Required key "SleepStage[startTime]" has a null value in JSON.');
        assert(json.containsKey(r'endTime'),
            'Required key "SleepStage[endTime]" is missing from JSON.');
        assert(json[r'endTime'] != null,
            'Required key "SleepStage[endTime]" has a null value in JSON.');
        return true;
      }());

      return SleepStage(
        stage: mapValueOfType<String>(json, r'stage')!,
        startTime: mapDateTime(json, r'startTime', r'')!,
        endTime: mapDateTime(json, r'endTime', r'')!,
      );
    }
    return null;
  }

  static List<SleepStage> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SleepStage>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SleepStage.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SleepStage> mapFromJson(dynamic json) {
    final map = <String, SleepStage>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SleepStage.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SleepStage-objects as value to a dart map
  static Map<String, List<SleepStage>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SleepStage>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SleepStage.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'stage',
    'startTime',
    'endTime',
  };
}
