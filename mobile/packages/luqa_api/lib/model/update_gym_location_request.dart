//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UpdateGymLocationRequest {
  /// Returns a new [UpdateGymLocationRequest] instance.
  UpdateGymLocationRequest({
    this.code = const Optional.absent(),
    this.name = const Optional.absent(),
    this.color = const Optional.absent(),
    this.order = const Optional.absent(),
    this.archived = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> code;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> color;

  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> order;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> archived;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateGymLocationRequest &&
          other.code == code &&
          other.name == name &&
          other.color == color &&
          other.order == order &&
          other.archived == archived;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (code == null ? 0 : code!.hashCode) +
      (name == null ? 0 : name!.hashCode) +
      (color == null ? 0 : color!.hashCode) +
      (order == null ? 0 : order!.hashCode) +
      (archived == null ? 0 : archived!.hashCode);

  @override
  String toString() =>
      'UpdateGymLocationRequest[code=$code, name=$name, color=$color, order=$order, archived=$archived]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.code.isPresent) {
      final value = this.code.value;
      json[r'code'] = value;
    }
    if (this.name.isPresent) {
      final value = this.name.value;
      json[r'name'] = value;
    }
    if (this.color.isPresent) {
      final value = this.color.value;
      json[r'color'] = value;
    }
    if (this.order.isPresent) {
      final value = this.order.value;
      json[r'order'] = value;
    }
    if (this.archived.isPresent) {
      final value = this.archived.value;
      json[r'archived'] = value;
    }
    return json;
  }

  /// Clones this instance of [UpdateGymLocationRequest] and returns a new one where some of the
  /// properties have changed.
  UpdateGymLocationRequest copyWith({
    Optional<String?>? code,
    Optional<String?>? name,
    Optional<String?>? color,
    Optional<int?>? order,
    Optional<bool?>? archived,
  }) =>
      UpdateGymLocationRequest(
        code: code ?? this.code,
        name: name ?? this.name,
        color: color ?? this.color,
        order: order ?? this.order,
        archived: archived ?? this.archived,
      );

  /// Returns a new [UpdateGymLocationRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateGymLocationRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UpdateGymLocationRequest(
        code: json.containsKey(r'code')
            ? Optional.present(mapValueOfType<String>(json, r'code'))
            : const Optional.absent(),
        name: json.containsKey(r'name')
            ? Optional.present(mapValueOfType<String>(json, r'name'))
            : const Optional.absent(),
        color: json.containsKey(r'color')
            ? Optional.present(mapValueOfType<String>(json, r'color'))
            : const Optional.absent(),
        order: json.containsKey(r'order')
            ? Optional.present(
                json[r'order'] == null ? null : int.parse('${json[r'order']}'))
            : const Optional.absent(),
        archived: json.containsKey(r'archived')
            ? Optional.present(mapValueOfType<bool>(json, r'archived'))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<UpdateGymLocationRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UpdateGymLocationRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateGymLocationRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateGymLocationRequest> mapFromJson(dynamic json) {
    final map = <String, UpdateGymLocationRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateGymLocationRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateGymLocationRequest-objects as value to a dart map
  static Map<String, List<UpdateGymLocationRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UpdateGymLocationRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateGymLocationRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{};
}
