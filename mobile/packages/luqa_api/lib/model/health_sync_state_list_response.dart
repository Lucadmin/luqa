//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HealthSyncStateListResponse {
  /// Returns a new [HealthSyncStateListResponse] instance.
  HealthSyncStateListResponse({
    this.states = const [],
  });

  final List<HealthSyncState> states;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthSyncStateListResponse &&
          _deepEquality.equals(other.states, states);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (states.hashCode);

  @override
  String toString() => 'HealthSyncStateListResponse[states=$states]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'states'] = this.states;
    return json;
  }

  /// Clones this instance of [HealthSyncStateListResponse] and returns a new one where some of the
  /// properties have changed.
  HealthSyncStateListResponse copyWith({
    List<HealthSyncState>? states,
  }) =>
      HealthSyncStateListResponse(
        states: states ?? this.states,
      );

  /// Returns a new [HealthSyncStateListResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HealthSyncStateListResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'states'),
            'Required key "HealthSyncStateListResponse[states]" is missing from JSON.');
        assert(json[r'states'] != null,
            'Required key "HealthSyncStateListResponse[states]" has a null value in JSON.');
        return true;
      }());

      return HealthSyncStateListResponse(
        states: HealthSyncState.listFromJson(json[r'states']),
      );
    }
    return null;
  }

  static List<HealthSyncStateListResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HealthSyncStateListResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HealthSyncStateListResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HealthSyncStateListResponse> mapFromJson(dynamic json) {
    final map = <String, HealthSyncStateListResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HealthSyncStateListResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HealthSyncStateListResponse-objects as value to a dart map
  static Map<String, List<HealthSyncStateListResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<HealthSyncStateListResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HealthSyncStateListResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'states',
  };
}
