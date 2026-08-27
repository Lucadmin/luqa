//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SessionCredentials {
  /// Returns a new [SessionCredentials] instance.
  SessionCredentials({
    required this.user,
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
    required this.refreshExpiresAt,
  });

  final MobileUser user;

  final String accessToken;

  final DateTime accessExpiresAt;

  final String refreshToken;

  final DateTime refreshExpiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionCredentials &&
          other.user == user &&
          other.accessToken == accessToken &&
          other.accessExpiresAt == accessExpiresAt &&
          other.refreshToken == refreshToken &&
          other.refreshExpiresAt == refreshExpiresAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (user.hashCode) +
      (accessToken.hashCode) +
      (accessExpiresAt.hashCode) +
      (refreshToken.hashCode) +
      (refreshExpiresAt.hashCode);

  @override
  String toString() =>
      'SessionCredentials[user=$user, accessToken=[REDACTED], accessExpiresAt=$accessExpiresAt, refreshToken=[REDACTED], refreshExpiresAt=$refreshExpiresAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'user'] = this.user;
    json[r'accessToken'] = this.accessToken;
    json[r'accessExpiresAt'] = this.accessExpiresAt.toUtc().toIso8601String();
    json[r'refreshToken'] = this.refreshToken;
    json[r'refreshExpiresAt'] = this.refreshExpiresAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [SessionCredentials] and returns a new one where some of the
  /// properties have changed.
  SessionCredentials copyWith({
    MobileUser? user,
    String? accessToken,
    DateTime? accessExpiresAt,
    String? refreshToken,
    DateTime? refreshExpiresAt,
  }) =>
      SessionCredentials(
        user: user ?? this.user,
        accessToken: accessToken ?? this.accessToken,
        accessExpiresAt: accessExpiresAt ?? this.accessExpiresAt,
        refreshToken: refreshToken ?? this.refreshToken,
        refreshExpiresAt: refreshExpiresAt ?? this.refreshExpiresAt,
      );

  /// Returns a new [SessionCredentials] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SessionCredentials? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'user'),
            'Required key "SessionCredentials[user]" is missing from JSON.');
        assert(json[r'user'] != null,
            'Required key "SessionCredentials[user]" has a null value in JSON.');
        assert(json.containsKey(r'accessToken'),
            'Required key "SessionCredentials[accessToken]" is missing from JSON.');
        assert(json[r'accessToken'] != null,
            'Required key "SessionCredentials[accessToken]" has a null value in JSON.');
        assert(json.containsKey(r'accessExpiresAt'),
            'Required key "SessionCredentials[accessExpiresAt]" is missing from JSON.');
        assert(json[r'accessExpiresAt'] != null,
            'Required key "SessionCredentials[accessExpiresAt]" has a null value in JSON.');
        assert(json.containsKey(r'refreshToken'),
            'Required key "SessionCredentials[refreshToken]" is missing from JSON.');
        assert(json[r'refreshToken'] != null,
            'Required key "SessionCredentials[refreshToken]" has a null value in JSON.');
        assert(json.containsKey(r'refreshExpiresAt'),
            'Required key "SessionCredentials[refreshExpiresAt]" is missing from JSON.');
        assert(json[r'refreshExpiresAt'] != null,
            'Required key "SessionCredentials[refreshExpiresAt]" has a null value in JSON.');
        return true;
      }());

      return SessionCredentials(
        user: MobileUser.fromJson(json[r'user'])!,
        accessToken: mapValueOfType<String>(json, r'accessToken')!,
        accessExpiresAt: mapDateTime(json, r'accessExpiresAt', r'')!,
        refreshToken: mapValueOfType<String>(json, r'refreshToken')!,
        refreshExpiresAt: mapDateTime(json, r'refreshExpiresAt', r'')!,
      );
    }
    return null;
  }

  static List<SessionCredentials> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SessionCredentials>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SessionCredentials.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SessionCredentials> mapFromJson(dynamic json) {
    final map = <String, SessionCredentials>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SessionCredentials.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SessionCredentials-objects as value to a dart map
  static Map<String, List<SessionCredentials>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SessionCredentials>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SessionCredentials.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'user',
    'accessToken',
    'accessExpiresAt',
    'refreshToken',
    'refreshExpiresAt',
  };
}
