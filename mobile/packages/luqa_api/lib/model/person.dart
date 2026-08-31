//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Person {
  /// Returns a new [Person] instance.
  Person({
    required this.id,
    required this.name,
    required this.color,
    required this.emoji,
    required this.defaultPercent,
    required this.order,
    required this.archived,
  });

  final String id;

  final String name;

  final String color;

  final String? emoji;

  /// The cut of a bill this person usually carries, in whole percent. Null means share equally with everyone else on it.
  ///
  /// Minimum value: 0
  /// Maximum value: 100
  final int? defaultPercent;

  final int order;

  final bool archived;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.emoji == emoji &&
          other.defaultPercent == defaultPercent &&
          other.order == order &&
          other.archived == archived;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (name.hashCode) +
      (color.hashCode) +
      (emoji == null ? 0 : emoji!.hashCode) +
      (defaultPercent == null ? 0 : defaultPercent!.hashCode) +
      (order.hashCode) +
      (archived.hashCode);

  @override
  String toString() =>
      'Person[id=$id, name=$name, color=$color, emoji=$emoji, defaultPercent=$defaultPercent, order=$order, archived=$archived]';

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
    if (this.defaultPercent != null) {
      json[r'defaultPercent'] = this.defaultPercent;
    } else {
      json[r'defaultPercent'] = null;
    }
    json[r'order'] = this.order;
    json[r'archived'] = this.archived;
    return json;
  }

  /// Clones this instance of [Person] and returns a new one where some of the
  /// properties have changed.
  Person copyWith({
    String? id,
    String? name,
    String? color,
    String? emoji,
    bool emojiSetToNull = false,
    int? defaultPercent,
    bool defaultPercentSetToNull = false,
    int? order,
    bool? archived,
  }) =>
      Person(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        emoji: emojiSetToNull ? null : emoji ?? this.emoji,
        defaultPercent: defaultPercentSetToNull
            ? null
            : defaultPercent ?? this.defaultPercent,
        order: order ?? this.order,
        archived: archived ?? this.archived,
      );

  /// Returns a new [Person] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Person? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "Person[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "Person[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "Person[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "Person[name]" has a null value in JSON.');
        assert(json.containsKey(r'color'),
            'Required key "Person[color]" is missing from JSON.');
        assert(json[r'color'] != null,
            'Required key "Person[color]" has a null value in JSON.');
        assert(json.containsKey(r'emoji'),
            'Required key "Person[emoji]" is missing from JSON.');
        assert(json.containsKey(r'defaultPercent'),
            'Required key "Person[defaultPercent]" is missing from JSON.');
        assert(json.containsKey(r'order'),
            'Required key "Person[order]" is missing from JSON.');
        assert(json[r'order'] != null,
            'Required key "Person[order]" has a null value in JSON.');
        assert(json.containsKey(r'archived'),
            'Required key "Person[archived]" is missing from JSON.');
        assert(json[r'archived'] != null,
            'Required key "Person[archived]" has a null value in JSON.');
        return true;
      }());

      return Person(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        color: mapValueOfType<String>(json, r'color')!,
        emoji: mapValueOfType<String>(json, r'emoji'),
        defaultPercent: mapValueOfType<int>(json, r'defaultPercent'),
        order: mapValueOfType<int>(json, r'order')!,
        archived: mapValueOfType<bool>(json, r'archived')!,
      );
    }
    return null;
  }

  static List<Person> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Person>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Person.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Person> mapFromJson(dynamic json) {
    final map = <String, Person>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Person.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Person-objects as value to a dart map
  static Map<String, List<Person>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Person>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Person.listFromJson(
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
    'defaultPercent',
    'order',
    'archived',
  };
}
