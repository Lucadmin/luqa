//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GymLocationResponse {
  /// Returns a new [GymLocationResponse] instance.
  GymLocationResponse({
    required this.location,
  });

  final GymLocation location;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymLocationResponse && other.location == location;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (location.hashCode);

  @override
  String toString() => 'GymLocationResponse[location=$location]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'location'] = this.location;
    return json;
  }

  /// Clones this instance of [GymLocationResponse] and returns a new one where some of the
  /// properties have changed.
  GymLocationResponse copyWith({
    GymLocation? location,
  }) =>
      GymLocationResponse(
        location: location ?? this.location,
      );

  /// Returns a new [GymLocationResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GymLocationResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'location'),
            'Required key "GymLocationResponse[location]" is missing from JSON.');
        assert(json[r'location'] != null,
            'Required key "GymLocationResponse[location]" has a null value in JSON.');
        return true;
      }());

      return GymLocationResponse(
        location: GymLocation.fromJson(json[r'location'])!,
      );
    }
    return null;
  }

  static List<GymLocationResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GymLocationResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GymLocationResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GymLocationResponse> mapFromJson(dynamic json) {
    final map = <String, GymLocationResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GymLocationResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GymLocationResponse-objects as value to a dart map
  static Map<String, List<GymLocationResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GymLocationResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GymLocationResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'location',
  };
}
