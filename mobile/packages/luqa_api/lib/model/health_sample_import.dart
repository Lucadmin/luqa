//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HealthSampleImport {
  /// Returns a new [HealthSampleImport] instance.
  HealthSampleImport({
    required this.externalId,
    required this.metric,
    required this.startTime,
    required this.endTime,
    required this.value,
    this.sourceApp = const Optional.absent(),
    this.zoneOffset = const Optional.absent(),
  });

  final String externalId;

  final HealthMetricType metric;

  final DateTime startTime;

  /// Equal to startTime for instant measurements.
  final DateTime endTime;

  final num value;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> sourceApp;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> zoneOffset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthSampleImport &&
          other.externalId == externalId &&
          other.metric == metric &&
          other.startTime == startTime &&
          other.endTime == endTime &&
          other.value == value &&
          other.sourceApp == sourceApp &&
          other.zoneOffset == zoneOffset;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (externalId.hashCode) +
      (metric.hashCode) +
      (startTime.hashCode) +
      (endTime.hashCode) +
      (value.hashCode) +
      (sourceApp == null ? 0 : sourceApp!.hashCode) +
      (zoneOffset == null ? 0 : zoneOffset!.hashCode);

  @override
  String toString() =>
      'HealthSampleImport[externalId=$externalId, metric=$metric, startTime=$startTime, endTime=$endTime, value=$value, sourceApp=$sourceApp, zoneOffset=$zoneOffset]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'externalId'] = this.externalId;
    json[r'metric'] = this.metric;
    json[r'startTime'] = this.startTime.toUtc().toIso8601String();
    json[r'endTime'] = this.endTime.toUtc().toIso8601String();
    json[r'value'] = this.value;
    if (this.sourceApp.isPresent) {
      final value = this.sourceApp.value;
      json[r'sourceApp'] = value;
    }
    if (this.zoneOffset.isPresent) {
      final value = this.zoneOffset.value;
      json[r'zoneOffset'] = value;
    }
    return json;
  }

  /// Clones this instance of [HealthSampleImport] and returns a new one where some of the
  /// properties have changed.
  HealthSampleImport copyWith({
    String? externalId,
    HealthMetricType? metric,
    DateTime? startTime,
    DateTime? endTime,
    num? value,
    Optional<String?>? sourceApp,
    Optional<String?>? zoneOffset,
  }) =>
      HealthSampleImport(
        externalId: externalId ?? this.externalId,
        metric: metric ?? this.metric,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        value: value ?? this.value,
        sourceApp: sourceApp ?? this.sourceApp,
        zoneOffset: zoneOffset ?? this.zoneOffset,
      );

  /// Returns a new [HealthSampleImport] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HealthSampleImport? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'externalId'),
            'Required key "HealthSampleImport[externalId]" is missing from JSON.');
        assert(json[r'externalId'] != null,
            'Required key "HealthSampleImport[externalId]" has a null value in JSON.');
        assert(json.containsKey(r'metric'),
            'Required key "HealthSampleImport[metric]" is missing from JSON.');
        assert(json[r'metric'] != null,
            'Required key "HealthSampleImport[metric]" has a null value in JSON.');
        assert(json.containsKey(r'startTime'),
            'Required key "HealthSampleImport[startTime]" is missing from JSON.');
        assert(json[r'startTime'] != null,
            'Required key "HealthSampleImport[startTime]" has a null value in JSON.');
        assert(json.containsKey(r'endTime'),
            'Required key "HealthSampleImport[endTime]" is missing from JSON.');
        assert(json[r'endTime'] != null,
            'Required key "HealthSampleImport[endTime]" has a null value in JSON.');
        assert(json.containsKey(r'value'),
            'Required key "HealthSampleImport[value]" is missing from JSON.');
        assert(json[r'value'] != null,
            'Required key "HealthSampleImport[value]" has a null value in JSON.');
        return true;
      }());

      return HealthSampleImport(
        externalId: mapValueOfType<String>(json, r'externalId')!,
        metric: HealthMetricType.fromJson(json[r'metric'])!,
        startTime: mapDateTime(json, r'startTime', r'')!,
        endTime: mapDateTime(json, r'endTime', r'')!,
        value: num.parse('${json[r'value']}'),
        sourceApp: json.containsKey(r'sourceApp')
            ? Optional.present(mapValueOfType<String>(json, r'sourceApp'))
            : const Optional.absent(),
        zoneOffset: json.containsKey(r'zoneOffset')
            ? Optional.present(mapValueOfType<String>(json, r'zoneOffset'))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<HealthSampleImport> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HealthSampleImport>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HealthSampleImport.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HealthSampleImport> mapFromJson(dynamic json) {
    final map = <String, HealthSampleImport>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HealthSampleImport.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HealthSampleImport-objects as value to a dart map
  static Map<String, List<HealthSampleImport>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<HealthSampleImport>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HealthSampleImport.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'externalId',
    'metric',
    'startTime',
    'endTime',
    'value',
  };
}
