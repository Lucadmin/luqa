//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateSessionRequest {
  /// Returns a new [CreateSessionRequest] instance.
  CreateSessionRequest({
    required this.email,
    required this.password,
    required this.deviceId,
    this.deviceName = const Optional.absent(),
  });

  final String email;

  final String password;

  final String deviceId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> deviceName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateSessionRequest &&
          other.email == email &&
          other.password == password &&
          other.deviceId == deviceId &&
          other.deviceName == deviceName;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (email.hashCode) +
      (password.hashCode) +
      (deviceId.hashCode) +
      (deviceName == null ? 0 : deviceName!.hashCode);

  @override
  String toString() =>
      'CreateSessionRequest[email=$email, password=[REDACTED], deviceId=$deviceId, deviceName=$deviceName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'email'] = this.email;
    json[r'password'] = this.password;
    json[r'deviceId'] = this.deviceId;
    if (this.deviceName.isPresent) {
      final value = this.deviceName.value;
      json[r'deviceName'] = value;
    }
    return json;
  }

  /// Clones this instance of [CreateSessionRequest] and returns a new one where some of the
  /// properties have changed.
  CreateSessionRequest copyWith({
    String? email,
    String? password,
    String? deviceId,
    Optional<String?>? deviceName,
  }) =>
      CreateSessionRequest(
        email: email ?? this.email,
        password: password ?? this.password,
        deviceId: deviceId ?? this.deviceId,
        deviceName: deviceName ?? this.deviceName,
      );

  /// Returns a new [CreateSessionRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateSessionRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'email'),
            'Required key "CreateSessionRequest[email]" is missing from JSON.');
        assert(json[r'email'] != null,
            'Required key "CreateSessionRequest[email]" has a null value in JSON.');
        assert(json.containsKey(r'password'),
            'Required key "CreateSessionRequest[password]" is missing from JSON.');
        assert(json[r'password'] != null,
            'Required key "CreateSessionRequest[password]" has a null value in JSON.');
        assert(json.containsKey(r'deviceId'),
            'Required key "CreateSessionRequest[deviceId]" is missing from JSON.');
        assert(json[r'deviceId'] != null,
            'Required key "CreateSessionRequest[deviceId]" has a null value in JSON.');
        return true;
      }());

      return CreateSessionRequest(
        email: mapValueOfType<String>(json, r'email')!,
        password: mapValueOfType<String>(json, r'password')!,
        deviceId: mapValueOfType<String>(json, r'deviceId')!,
        deviceName: json.containsKey(r'deviceName')
            ? Optional.present(mapValueOfType<String>(json, r'deviceName'))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<CreateSessionRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreateSessionRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateSessionRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateSessionRequest> mapFromJson(dynamic json) {
    final map = <String, CreateSessionRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateSessionRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateSessionRequest-objects as value to a dart map
  static Map<String, List<CreateSessionRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreateSessionRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateSessionRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'email',
    'password',
    'deviceId',
  };
}
