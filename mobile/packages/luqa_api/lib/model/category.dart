//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Category {
  /// Returns a new [Category] instance.
  Category({
    required this.id,
    required this.name,
    required this.color,
    required this.archived,
  });

  final String id;

  final String name;

  final String color;

  final bool archived;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.archived == archived;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) + (name.hashCode) + (color.hashCode) + (archived.hashCode);

  @override
  String toString() =>
      'Category[id=$id, name=$name, color=$color, archived=$archived]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'name'] = this.name;
    json[r'color'] = this.color;
    json[r'archived'] = this.archived;
    return json;
  }

  /// Clones this instance of [Category] and returns a new one where some of the
  /// properties have changed.
  Category copyWith({
    String? id,
    String? name,
    String? color,
    bool? archived,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        archived: archived ?? this.archived,
      );

  /// Returns a new [Category] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Category? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "Category[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "Category[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "Category[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "Category[name]" has a null value in JSON.');
        assert(json.containsKey(r'color'),
            'Required key "Category[color]" is missing from JSON.');
        assert(json[r'color'] != null,
            'Required key "Category[color]" has a null value in JSON.');
        assert(json.containsKey(r'archived'),
            'Required key "Category[archived]" is missing from JSON.');
        assert(json[r'archived'] != null,
            'Required key "Category[archived]" has a null value in JSON.');
        return true;
      }());

      return Category(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        color: mapValueOfType<String>(json, r'color')!,
        archived: mapValueOfType<bool>(json, r'archived')!,
      );
    }
    return null;
  }

  static List<Category> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Category>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Category.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Category> mapFromJson(dynamic json) {
    final map = <String, Category>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Category.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Category-objects as value to a dart map
  static Map<String, List<Category>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Category>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Category.listFromJson(
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
    'archived',
  };
}
