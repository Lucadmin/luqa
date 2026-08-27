//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HealthSyncResponse {
  /// Returns a new [HealthSyncResponse] instance.
  HealthSyncResponse({
    required this.sleep,
    required this.samples,
  });

  final HealthSyncCounts sleep;

  final HealthSyncCounts samples;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthSyncResponse &&
          other.sleep == sleep &&
          other.samples == samples;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (sleep.hashCode) + (samples.hashCode);

  @override
  String toString() => 'HealthSyncResponse[sleep=$sleep, samples=$samples]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'sleep'] = this.sleep;
    json[r'samples'] = this.samples;
    return json;
  }

  /// Clones this instance of [HealthSyncResponse] and returns a new one where some of the
  /// properties have changed.
  HealthSyncResponse copyWith({
    HealthSyncCounts? sleep,
    HealthSyncCounts? samples,
  }) =>
      HealthSyncResponse(
        sleep: sleep ?? this.sleep,
        samples: samples ?? this.samples,
      );

  /// Returns a new [HealthSyncResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HealthSyncResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'sleep'),
            'Required key "HealthSyncResponse[sleep]" is missing from JSON.');
        assert(json[r'sleep'] != null,
            'Required key "HealthSyncResponse[sleep]" has a null value in JSON.');
        assert(json.containsKey(r'samples'),
            'Required key "HealthSyncResponse[samples]" is missing from JSON.');
        assert(json[r'samples'] != null,
            'Required key "HealthSyncResponse[samples]" has a null value in JSON.');
        return true;
      }());

      return HealthSyncResponse(
        sleep: HealthSyncCounts.fromJson(json[r'sleep'])!,
        samples: HealthSyncCounts.fromJson(json[r'samples'])!,
      );
    }
    return null;
  }

  static List<HealthSyncResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HealthSyncResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HealthSyncResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HealthSyncResponse> mapFromJson(dynamic json) {
    final map = <String, HealthSyncResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HealthSyncResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HealthSyncResponse-objects as value to a dart map
  static Map<String, List<HealthSyncResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<HealthSyncResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HealthSyncResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'sleep',
    'samples',
  };
}
