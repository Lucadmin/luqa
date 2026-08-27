//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SleepSyncWindow {
  /// Returns a new [SleepSyncWindow] instance.
  SleepSyncWindow({
    required this.from,
    required this.to,
  });

  final DateTime from;

  final DateTime to;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepSyncWindow && other.from == from && other.to == to;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (from.hashCode) + (to.hashCode);

  @override
  String toString() => 'SleepSyncWindow[from=$from, to=$to]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'from'] = this.from.toUtc().toIso8601String();
    json[r'to'] = this.to.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [SleepSyncWindow] and returns a new one where some of the
  /// properties have changed.
  SleepSyncWindow copyWith({
    DateTime? from,
    DateTime? to,
  }) =>
      SleepSyncWindow(
        from: from ?? this.from,
        to: to ?? this.to,
      );

  /// Returns a new [SleepSyncWindow] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SleepSyncWindow? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'from'),
            'Required key "SleepSyncWindow[from]" is missing from JSON.');
        assert(json[r'from'] != null,
            'Required key "SleepSyncWindow[from]" has a null value in JSON.');
        assert(json.containsKey(r'to'),
            'Required key "SleepSyncWindow[to]" is missing from JSON.');
        assert(json[r'to'] != null,
            'Required key "SleepSyncWindow[to]" has a null value in JSON.');
        return true;
      }());

      return SleepSyncWindow(
        from: mapDateTime(json, r'from', r'')!,
        to: mapDateTime(json, r'to', r'')!,
      );
    }
    return null;
  }

  static List<SleepSyncWindow> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SleepSyncWindow>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SleepSyncWindow.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SleepSyncWindow> mapFromJson(dynamic json) {
    final map = <String, SleepSyncWindow>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SleepSyncWindow.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SleepSyncWindow-objects as value to a dart map
  static Map<String, List<SleepSyncWindow>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SleepSyncWindow>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SleepSyncWindow.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'from',
    'to',
  };
}
