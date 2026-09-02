//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CitySearchResponse {
  /// Returns a new [CitySearchResponse] instance.
  CitySearchResponse({
    this.results = const [],
  });

  /// Best match first, in the geocoder's own ranking. Empty when the query is too short, matches nothing, or could not be asked — all three leave the client offering the typed name as it stands.
  final List<CityCandidate> results;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CitySearchResponse &&
          _deepEquality.equals(other.results, results);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (results.hashCode);

  @override
  String toString() => 'CitySearchResponse[results=$results]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'results'] = this.results;
    return json;
  }

  /// Clones this instance of [CitySearchResponse] and returns a new one where some of the
  /// properties have changed.
  CitySearchResponse copyWith({
    List<CityCandidate>? results,
  }) =>
      CitySearchResponse(
        results: results ?? this.results,
      );

  /// Returns a new [CitySearchResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CitySearchResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'results'),
            'Required key "CitySearchResponse[results]" is missing from JSON.');
        assert(json[r'results'] != null,
            'Required key "CitySearchResponse[results]" has a null value in JSON.');
        return true;
      }());

      return CitySearchResponse(
        results: CityCandidate.listFromJson(json[r'results']),
      );
    }
    return null;
  }

  static List<CitySearchResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CitySearchResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CitySearchResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CitySearchResponse> mapFromJson(dynamic json) {
    final map = <String, CitySearchResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CitySearchResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CitySearchResponse-objects as value to a dart map
  static Map<String, List<CitySearchResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CitySearchResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CitySearchResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'results',
  };
}
