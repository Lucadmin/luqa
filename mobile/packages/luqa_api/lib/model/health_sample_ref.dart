//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HealthSampleRef {
  /// Returns a new [HealthSampleRef] instance.
  HealthSampleRef({
    required this.metric,
    required this.externalId,
  });

  final HealthMetricType metric;

  final String externalId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthSampleRef &&
          other.metric == metric &&
          other.externalId == externalId;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (metric.hashCode) + (externalId.hashCode);

  @override
  String toString() =>
      'HealthSampleRef[metric=$metric, externalId=$externalId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'metric'] = this.metric;
    json[r'externalId'] = this.externalId;
    return json;
  }

  /// Clones this instance of [HealthSampleRef] and returns a new one where some of the
  /// properties have changed.
  HealthSampleRef copyWith({
    HealthMetricType? metric,
    String? externalId,
  }) =>
      HealthSampleRef(
        metric: metric ?? this.metric,
        externalId: externalId ?? this.externalId,
      );

  /// Returns a new [HealthSampleRef] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HealthSampleRef? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'metric'),
            'Required key "HealthSampleRef[metric]" is missing from JSON.');
        assert(json[r'metric'] != null,
            'Required key "HealthSampleRef[metric]" has a null value in JSON.');
        assert(json.containsKey(r'externalId'),
            'Required key "HealthSampleRef[externalId]" is missing from JSON.');
        assert(json[r'externalId'] != null,
            'Required key "HealthSampleRef[externalId]" has a null value in JSON.');
        return true;
      }());

      return HealthSampleRef(
        metric: HealthMetricType.fromJson(json[r'metric'])!,
        externalId: mapValueOfType<String>(json, r'externalId')!,
      );
    }
    return null;
  }

  static List<HealthSampleRef> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HealthSampleRef>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HealthSampleRef.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HealthSampleRef> mapFromJson(dynamic json) {
    final map = <String, HealthSampleRef>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HealthSampleRef.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HealthSampleRef-objects as value to a dart map
  static Map<String, List<HealthSampleRef>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<HealthSampleRef>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HealthSampleRef.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'metric',
    'externalId',
  };
}
