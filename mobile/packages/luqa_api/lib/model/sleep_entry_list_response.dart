//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SleepEntryListResponse {
  /// Returns a new [SleepEntryListResponse] instance.
  SleepEntryListResponse({
    this.entries = const [],
  });

  final List<SleepEntry> entries;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepEntryListResponse &&
          _deepEquality.equals(other.entries, entries);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (entries.hashCode);

  @override
  String toString() => 'SleepEntryListResponse[entries=$entries]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'entries'] = this.entries;
    return json;
  }

  /// Clones this instance of [SleepEntryListResponse] and returns a new one where some of the
  /// properties have changed.
  SleepEntryListResponse copyWith({
    List<SleepEntry>? entries,
  }) =>
      SleepEntryListResponse(
        entries: entries ?? this.entries,
      );

  /// Returns a new [SleepEntryListResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SleepEntryListResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'entries'),
            'Required key "SleepEntryListResponse[entries]" is missing from JSON.');
        assert(json[r'entries'] != null,
            'Required key "SleepEntryListResponse[entries]" has a null value in JSON.');
        return true;
      }());

      return SleepEntryListResponse(
        entries: SleepEntry.listFromJson(json[r'entries']),
      );
    }
    return null;
  }

  static List<SleepEntryListResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SleepEntryListResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SleepEntryListResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SleepEntryListResponse> mapFromJson(dynamic json) {
    final map = <String, SleepEntryListResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SleepEntryListResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SleepEntryListResponse-objects as value to a dart map
  static Map<String, List<SleepEntryListResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SleepEntryListResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SleepEntryListResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'entries',
  };
}
