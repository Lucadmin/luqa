//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TimeEntryResponse {
  /// Returns a new [TimeEntryResponse] instance.
  TimeEntryResponse({
    required this.entry,
  });

  final TimeEntry entry;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeEntryResponse && other.entry == entry;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (entry.hashCode);

  @override
  String toString() => 'TimeEntryResponse[entry=$entry]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'entry'] = this.entry;
    return json;
  }

  /// Clones this instance of [TimeEntryResponse] and returns a new one where some of the
  /// properties have changed.
  TimeEntryResponse copyWith({
    TimeEntry? entry,
  }) =>
      TimeEntryResponse(
        entry: entry ?? this.entry,
      );

  /// Returns a new [TimeEntryResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TimeEntryResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'entry'),
            'Required key "TimeEntryResponse[entry]" is missing from JSON.');
        assert(json[r'entry'] != null,
            'Required key "TimeEntryResponse[entry]" has a null value in JSON.');
        return true;
      }());

      return TimeEntryResponse(
        entry: TimeEntry.fromJson(json[r'entry'])!,
      );
    }
    return null;
  }

  static List<TimeEntryResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TimeEntryResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TimeEntryResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TimeEntryResponse> mapFromJson(dynamic json) {
    final map = <String, TimeEntryResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TimeEntryResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TimeEntryResponse-objects as value to a dart map
  static Map<String, List<TimeEntryResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<TimeEntryResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TimeEntryResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'entry',
  };
}
