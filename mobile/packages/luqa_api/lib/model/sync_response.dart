//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SyncResponse {
  /// Returns a new [SyncResponse] instance.
  SyncResponse({
    required this.settings,
    required this.collections,
  });

  final SyncSettings settings;

  final SyncCollections collections;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncResponse &&
          other.settings == settings &&
          other.collections == collections;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (settings.hashCode) + (collections.hashCode);

  @override
  String toString() =>
      'SyncResponse[settings=$settings, collections=$collections]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'settings'] = this.settings;
    json[r'collections'] = this.collections;
    return json;
  }

  /// Clones this instance of [SyncResponse] and returns a new one where some of the
  /// properties have changed.
  SyncResponse copyWith({
    SyncSettings? settings,
    SyncCollections? collections,
  }) =>
      SyncResponse(
        settings: settings ?? this.settings,
        collections: collections ?? this.collections,
      );

  /// Returns a new [SyncResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SyncResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'settings'),
            'Required key "SyncResponse[settings]" is missing from JSON.');
        assert(json[r'settings'] != null,
            'Required key "SyncResponse[settings]" has a null value in JSON.');
        assert(json.containsKey(r'collections'),
            'Required key "SyncResponse[collections]" is missing from JSON.');
        assert(json[r'collections'] != null,
            'Required key "SyncResponse[collections]" has a null value in JSON.');
        return true;
      }());

      return SyncResponse(
        settings: SyncSettings.fromJson(json[r'settings'])!,
        collections: SyncCollections.fromJson(json[r'collections'])!,
      );
    }
    return null;
  }

  static List<SyncResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SyncResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SyncResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SyncResponse> mapFromJson(dynamic json) {
    final map = <String, SyncResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SyncResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SyncResponse-objects as value to a dart map
  static Map<String, List<SyncResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SyncResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SyncResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'settings',
    'collections',
  };
}
