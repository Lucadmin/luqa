//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PutHabitLogRequest {
  /// Returns a new [PutHabitLogRequest] instance.
  PutHabitLogRequest({
    required this.count,
    required this.seconds,
    this.runningSince = const Optional.absent(),
  });

  /// Minimum value: 0
  /// Maximum value: 100000
  final int count;

  /// Minimum value: 0
  /// Maximum value: 2592000
  final int seconds;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<DateTime?> runningSince;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PutHabitLogRequest &&
          other.count == count &&
          other.seconds == seconds &&
          other.runningSince == runningSince;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (count.hashCode) +
      (seconds.hashCode) +
      (runningSince == null ? 0 : runningSince!.hashCode);

  @override
  String toString() =>
      'PutHabitLogRequest[count=$count, seconds=$seconds, runningSince=$runningSince]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'count'] = this.count;
    json[r'seconds'] = this.seconds;
    if (this.runningSince.isPresent) {
      final value = this.runningSince.value;
      json[r'runningSince'] =
          value == null ? null : value.toUtc().toIso8601String();
    }
    return json;
  }

  /// Clones this instance of [PutHabitLogRequest] and returns a new one where some of the
  /// properties have changed.
  PutHabitLogRequest copyWith({
    int? count,
    int? seconds,
    Optional<DateTime?>? runningSince,
  }) =>
      PutHabitLogRequest(
        count: count ?? this.count,
        seconds: seconds ?? this.seconds,
        runningSince: runningSince ?? this.runningSince,
      );

  /// Returns a new [PutHabitLogRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PutHabitLogRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'count'),
            'Required key "PutHabitLogRequest[count]" is missing from JSON.');
        assert(json[r'count'] != null,
            'Required key "PutHabitLogRequest[count]" has a null value in JSON.');
        assert(json.containsKey(r'seconds'),
            'Required key "PutHabitLogRequest[seconds]" is missing from JSON.');
        assert(json[r'seconds'] != null,
            'Required key "PutHabitLogRequest[seconds]" has a null value in JSON.');
        return true;
      }());

      return PutHabitLogRequest(
        count: mapValueOfType<int>(json, r'count')!,
        seconds: mapValueOfType<int>(json, r'seconds')!,
        runningSince: json.containsKey(r'runningSince')
            ? Optional.present(mapDateTime(json, r'runningSince', r''))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<PutHabitLogRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PutHabitLogRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PutHabitLogRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PutHabitLogRequest> mapFromJson(dynamic json) {
    final map = <String, PutHabitLogRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PutHabitLogRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PutHabitLogRequest-objects as value to a dart map
  static Map<String, List<PutHabitLogRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PutHabitLogRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PutHabitLogRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'count',
    'seconds',
  };
}
