//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GymSessionListResponse {
  /// Returns a new [GymSessionListResponse] instance.
  GymSessionListResponse({
    this.sessions = const [],
    required this.nextCursor,
  });

  final List<GymSession> sessions;

  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymSessionListResponse &&
          _deepEquality.equals(other.sessions, sessions) &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (sessions.hashCode) + (nextCursor == null ? 0 : nextCursor!.hashCode);

  @override
  String toString() =>
      'GymSessionListResponse[sessions=$sessions, nextCursor=$nextCursor]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'sessions'] = this.sessions;
    if (this.nextCursor != null) {
      json[r'nextCursor'] = this.nextCursor;
    } else {
      json[r'nextCursor'] = null;
    }
    return json;
  }

  /// Clones this instance of [GymSessionListResponse] and returns a new one where some of the
  /// properties have changed.
  GymSessionListResponse copyWith({
    List<GymSession>? sessions,
    String? nextCursor,
    bool nextCursorSetToNull = false,
  }) =>
      GymSessionListResponse(
        sessions: sessions ?? this.sessions,
        nextCursor: nextCursorSetToNull ? null : nextCursor ?? this.nextCursor,
      );

  /// Returns a new [GymSessionListResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GymSessionListResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'sessions'),
            'Required key "GymSessionListResponse[sessions]" is missing from JSON.');
        assert(json[r'sessions'] != null,
            'Required key "GymSessionListResponse[sessions]" has a null value in JSON.');
        assert(json.containsKey(r'nextCursor'),
            'Required key "GymSessionListResponse[nextCursor]" is missing from JSON.');
        return true;
      }());

      return GymSessionListResponse(
        sessions: GymSession.listFromJson(json[r'sessions']),
        nextCursor: mapValueOfType<String>(json, r'nextCursor'),
      );
    }
    return null;
  }

  static List<GymSessionListResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GymSessionListResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GymSessionListResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GymSessionListResponse> mapFromJson(dynamic json) {
    final map = <String, GymSessionListResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GymSessionListResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GymSessionListResponse-objects as value to a dart map
  static Map<String, List<GymSessionListResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GymSessionListResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GymSessionListResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'sessions',
    'nextCursor',
  };
}
