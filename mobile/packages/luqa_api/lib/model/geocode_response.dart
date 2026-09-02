//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GeocodeResponse {
  /// Returns a new [GeocodeResponse] instance.
  GeocodeResponse({
    required this.resolved,
    required this.remaining,
  });

  /// Places given a point by this call.
  final int resolved;

  /// Places still without one. Above zero means the map is worth asking again; each call is bounded so that a long-neglected address book cannot make one request run past a serverless timeout.
  final int remaining;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeocodeResponse &&
          other.resolved == resolved &&
          other.remaining == remaining;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (resolved.hashCode) + (remaining.hashCode);

  @override
  String toString() =>
      'GeocodeResponse[resolved=$resolved, remaining=$remaining]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'resolved'] = this.resolved;
    json[r'remaining'] = this.remaining;
    return json;
  }

  /// Clones this instance of [GeocodeResponse] and returns a new one where some of the
  /// properties have changed.
  GeocodeResponse copyWith({
    int? resolved,
    int? remaining,
  }) =>
      GeocodeResponse(
        resolved: resolved ?? this.resolved,
        remaining: remaining ?? this.remaining,
      );

  /// Returns a new [GeocodeResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GeocodeResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'resolved'),
            'Required key "GeocodeResponse[resolved]" is missing from JSON.');
        assert(json[r'resolved'] != null,
            'Required key "GeocodeResponse[resolved]" has a null value in JSON.');
        assert(json.containsKey(r'remaining'),
            'Required key "GeocodeResponse[remaining]" is missing from JSON.');
        assert(json[r'remaining'] != null,
            'Required key "GeocodeResponse[remaining]" has a null value in JSON.');
        return true;
      }());

      return GeocodeResponse(
        resolved: mapValueOfType<int>(json, r'resolved')!,
        remaining: mapValueOfType<int>(json, r'remaining')!,
      );
    }
    return null;
  }

  static List<GeocodeResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GeocodeResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GeocodeResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GeocodeResponse> mapFromJson(dynamic json) {
    final map = <String, GeocodeResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GeocodeResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GeocodeResponse-objects as value to a dart map
  static Map<String, List<GeocodeResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GeocodeResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GeocodeResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'resolved',
    'remaining',
  };
}
