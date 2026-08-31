//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PersonGroup {
  /// Returns a new [PersonGroup] instance.
  PersonGroup({
    required this.id,
    required this.name,
    required this.color,
    required this.emoji,
    required this.order,
    required this.archived,
    this.memberIds = const [],
  });

  final String id;

  final String name;

  final String color;

  final String? emoji;

  final int order;

  final bool archived;

  final List<String> memberIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonGroup &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.emoji == emoji &&
          other.order == order &&
          other.archived == archived &&
          _deepEquality.equals(other.memberIds, memberIds);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (name.hashCode) +
      (color.hashCode) +
      (emoji == null ? 0 : emoji!.hashCode) +
      (order.hashCode) +
      (archived.hashCode) +
      (memberIds.hashCode);

  @override
  String toString() =>
      'PersonGroup[id=$id, name=$name, color=$color, emoji=$emoji, order=$order, archived=$archived, memberIds=$memberIds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'name'] = this.name;
    json[r'color'] = this.color;
    if (this.emoji != null) {
      json[r'emoji'] = this.emoji;
    } else {
      json[r'emoji'] = null;
    }
    json[r'order'] = this.order;
    json[r'archived'] = this.archived;
    json[r'memberIds'] = this.memberIds;
    return json;
  }

  /// Clones this instance of [PersonGroup] and returns a new one where some of the
  /// properties have changed.
  PersonGroup copyWith({
    String? id,
    String? name,
    String? color,
    String? emoji,
    bool emojiSetToNull = false,
    int? order,
    bool? archived,
    List<String>? memberIds,
  }) =>
      PersonGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        emoji: emojiSetToNull ? null : emoji ?? this.emoji,
        order: order ?? this.order,
        archived: archived ?? this.archived,
        memberIds: memberIds ?? this.memberIds,
      );

  /// Returns a new [PersonGroup] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PersonGroup? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "PersonGroup[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "PersonGroup[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "PersonGroup[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "PersonGroup[name]" has a null value in JSON.');
        assert(json.containsKey(r'color'),
            'Required key "PersonGroup[color]" is missing from JSON.');
        assert(json[r'color'] != null,
            'Required key "PersonGroup[color]" has a null value in JSON.');
        assert(json.containsKey(r'emoji'),
            'Required key "PersonGroup[emoji]" is missing from JSON.');
        assert(json.containsKey(r'order'),
            'Required key "PersonGroup[order]" is missing from JSON.');
        assert(json[r'order'] != null,
            'Required key "PersonGroup[order]" has a null value in JSON.');
        assert(json.containsKey(r'archived'),
            'Required key "PersonGroup[archived]" is missing from JSON.');
        assert(json[r'archived'] != null,
            'Required key "PersonGroup[archived]" has a null value in JSON.');
        assert(json.containsKey(r'memberIds'),
            'Required key "PersonGroup[memberIds]" is missing from JSON.');
        assert(json[r'memberIds'] != null,
            'Required key "PersonGroup[memberIds]" has a null value in JSON.');
        return true;
      }());

      return PersonGroup(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        color: mapValueOfType<String>(json, r'color')!,
        emoji: mapValueOfType<String>(json, r'emoji'),
        order: mapValueOfType<int>(json, r'order')!,
        archived: mapValueOfType<bool>(json, r'archived')!,
        memberIds: json[r'memberIds'] is Iterable
            ? (json[r'memberIds'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<PersonGroup> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PersonGroup>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PersonGroup.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PersonGroup> mapFromJson(dynamic json) {
    final map = <String, PersonGroup>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PersonGroup.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PersonGroup-objects as value to a dart map
  static Map<String, List<PersonGroup>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PersonGroup>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PersonGroup.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'color',
    'emoji',
    'order',
    'archived',
    'memberIds',
  };
}
