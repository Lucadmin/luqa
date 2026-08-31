//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateGroupRequest {
  /// Returns a new [CreateGroupRequest] instance.
  CreateGroupRequest({
    this.id = const Optional.absent(),
    required this.name,
    this.color = const Optional.absent(),
    this.emoji = const Optional.absent(),
    this.memberIds = const Optional.present(const []),
  });

  /// Preferred identity for a group made offline. Honoured only when free; an existing group with the same name wins.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> id;

  final String name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> color;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> emoji;

  final Optional<List<String>?> memberIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateGroupRequest &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.emoji == emoji &&
          _deepEquality.equals(other.memberIds, memberIds);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id == null ? 0 : id!.hashCode) +
      (name.hashCode) +
      (color == null ? 0 : color!.hashCode) +
      (emoji == null ? 0 : emoji!.hashCode) +
      (memberIds.hashCode);

  @override
  String toString() =>
      'CreateGroupRequest[id=$id, name=$name, color=$color, emoji=$emoji, memberIds=$memberIds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id.isPresent) {
      final value = this.id.value;
      json[r'id'] = value;
    }
    json[r'name'] = this.name;
    if (this.color.isPresent) {
      final value = this.color.value;
      json[r'color'] = value;
    }
    if (this.emoji.isPresent) {
      final value = this.emoji.value;
      json[r'emoji'] = value;
    }
    if (this.memberIds.isPresent) {
      final value = this.memberIds.value;
      json[r'memberIds'] = value;
    }
    return json;
  }

  /// Clones this instance of [CreateGroupRequest] and returns a new one where some of the
  /// properties have changed.
  CreateGroupRequest copyWith({
    Optional<String?>? id,
    String? name,
    Optional<String?>? color,
    Optional<String?>? emoji,
    Optional<List<String>?>? memberIds,
  }) =>
      CreateGroupRequest(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        emoji: emoji ?? this.emoji,
        memberIds: memberIds ?? this.memberIds,
      );

  /// Returns a new [CreateGroupRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateGroupRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'),
            'Required key "CreateGroupRequest[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "CreateGroupRequest[name]" has a null value in JSON.');
        return true;
      }());

      return CreateGroupRequest(
        id: json.containsKey(r'id')
            ? Optional.present(mapValueOfType<String>(json, r'id'))
            : const Optional.absent(),
        name: mapValueOfType<String>(json, r'name')!,
        color: json.containsKey(r'color')
            ? Optional.present(mapValueOfType<String>(json, r'color'))
            : const Optional.absent(),
        emoji: json.containsKey(r'emoji')
            ? Optional.present(mapValueOfType<String>(json, r'emoji'))
            : const Optional.absent(),
        memberIds: json.containsKey(r'memberIds')
            ? Optional.present(json[r'memberIds'] is Iterable
                ? (json[r'memberIds'] as Iterable)
                    .cast<String>()
                    .toList(growable: false)
                : const [])
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<CreateGroupRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreateGroupRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateGroupRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateGroupRequest> mapFromJson(dynamic json) {
    final map = <String, CreateGroupRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateGroupRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateGroupRequest-objects as value to a dart map
  static Map<String, List<CreateGroupRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreateGroupRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateGroupRequest.listFromJson(
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
