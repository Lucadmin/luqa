//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateCategoryRequest {
  /// Returns a new [CreateCategoryRequest] instance.
  CreateCategoryRequest({
    required this.name,
    this.color = const Optional.absent(),
  });

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
      other is CreateCategoryRequest &&
          other.name == name &&
          other.color == color;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name.hashCode) + (color == null ? 0 : color!.hashCode);

  @override
  String toString() => 'CreateCategoryRequest[name=$name, color=$color]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'name'] = this.name;
    if (this.color.isPresent) {
      final value = this.color.value;
      json[r'color'] = value;
    }
    return json;
  }

  /// Clones this instance of [CreateCategoryRequest] and returns a new one where some of the
  /// properties have changed.
  CreateCategoryRequest copyWith({
    String? name,
    Optional<String?>? color,
  }) =>
      CreateCategoryRequest(
        name: name ?? this.name,
        color: color ?? this.color,
      );

  /// Returns a new [CreateCategoryRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateCategoryRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'),
            'Required key "CreateCategoryRequest[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "CreateCategoryRequest[name]" has a null value in JSON.');
        return true;
      }());

      return CreateCategoryRequest(
        name: mapValueOfType<String>(json, r'name')!,
        color: json.containsKey(r'color')
            ? Optional.present(mapValueOfType<String>(json, r'color'))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<CreateCategoryRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreateCategoryRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateCategoryRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateCategoryRequest> mapFromJson(dynamic json) {
    final map = <String, CreateCategoryRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateCategoryRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateCategoryRequest-objects as value to a dart map
  static Map<String, List<CreateCategoryRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreateCategoryRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateCategoryRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
  };
}
