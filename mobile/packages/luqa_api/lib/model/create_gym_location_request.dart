//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateGymLocationRequest {
  /// Returns a new [CreateGymLocationRequest] instance.
  CreateGymLocationRequest({
    this.id = const Optional.absent(),
    required this.code,
    required this.name,
    this.color = const Optional.absent(),
  });

  /// Preferred identity for a gym added offline. Honoured only when free; a gym with the same code already existing wins, so the response is authoritative.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> id;

  final String code;

  final String name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateGymLocationRequest &&
          other.id == id &&
          other.code == code &&
          other.name == name &&
          other.color == color;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id == null ? 0 : id!.hashCode) +
      (code.hashCode) +
      (name.hashCode) +
      (color == null ? 0 : color!.hashCode);

  @override
  String toString() =>
      'CreateGymLocationRequest[id=$id, code=$code, name=$name, color=$color]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id.isPresent) {
      final value = this.id.value;
      json[r'id'] = value;
    }
    json[r'code'] = this.code;
    json[r'name'] = this.name;
    if (this.color.isPresent) {
      final value = this.color.value;
      json[r'color'] = value;
    }
    return json;
  }

  /// Clones this instance of [CreateGymLocationRequest] and returns a new one where some of the
  /// properties have changed.
  CreateGymLocationRequest copyWith({
    Optional<String?>? id,
    String? code,
    String? name,
    Optional<String?>? color,
  }) =>
      CreateGymLocationRequest(
        id: id ?? this.id,
        code: code ?? this.code,
        name: name ?? this.name,
        color: color ?? this.color,
      );

  /// Returns a new [CreateGymLocationRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateGymLocationRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'code'),
            'Required key "CreateGymLocationRequest[code]" is missing from JSON.');
        assert(json[r'code'] != null,
            'Required key "CreateGymLocationRequest[code]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "CreateGymLocationRequest[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "CreateGymLocationRequest[name]" has a null value in JSON.');
        return true;
      }());

      return CreateGymLocationRequest(
        id: json.containsKey(r'id')
            ? Optional.present(mapValueOfType<String>(json, r'id'))
            : const Optional.absent(),
        code: mapValueOfType<String>(json, r'code')!,
        name: mapValueOfType<String>(json, r'name')!,
        color: json.containsKey(r'color')
            ? Optional.present(mapValueOfType<String>(json, r'color'))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<CreateGymLocationRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreateGymLocationRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateGymLocationRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateGymLocationRequest> mapFromJson(dynamic json) {
    final map = <String, CreateGymLocationRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateGymLocationRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateGymLocationRequest-objects as value to a dart map
  static Map<String, List<CreateGymLocationRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreateGymLocationRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateGymLocationRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'code',
    'name',
  };
}
