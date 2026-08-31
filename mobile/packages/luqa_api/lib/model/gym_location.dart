//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GymLocation {
  /// Returns a new [GymLocation] instance.
  GymLocation({
    required this.id,
    required this.code,
    required this.name,
    required this.color,
    required this.order,
    required this.archived,
  });

  final String id;

  final String code;

  final String name;

  final String color;

  final int order;

  final bool archived;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymLocation &&
          other.id == id &&
          other.code == code &&
          other.name == name &&
          other.color == color &&
          other.order == order &&
          other.archived == archived;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (code.hashCode) +
      (name.hashCode) +
      (color.hashCode) +
      (order.hashCode) +
      (archived.hashCode);

  @override
  String toString() =>
      'GymLocation[id=$id, code=$code, name=$name, color=$color, order=$order, archived=$archived]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'code'] = this.code;
    json[r'name'] = this.name;
    json[r'color'] = this.color;
    json[r'order'] = this.order;
    json[r'archived'] = this.archived;
    return json;
  }

  /// Clones this instance of [GymLocation] and returns a new one where some of the
  /// properties have changed.
  GymLocation copyWith({
    String? id,
    String? code,
    String? name,
    String? color,
    int? order,
    bool? archived,
  }) =>
      GymLocation(
        id: id ?? this.id,
        code: code ?? this.code,
        name: name ?? this.name,
        color: color ?? this.color,
        order: order ?? this.order,
        archived: archived ?? this.archived,
      );

  /// Returns a new [GymLocation] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GymLocation? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "GymLocation[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "GymLocation[id]" has a null value in JSON.');
        assert(json.containsKey(r'code'),
            'Required key "GymLocation[code]" is missing from JSON.');
        assert(json[r'code'] != null,
            'Required key "GymLocation[code]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "GymLocation[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "GymLocation[name]" has a null value in JSON.');
        assert(json.containsKey(r'color'),
            'Required key "GymLocation[color]" is missing from JSON.');
        assert(json[r'color'] != null,
            'Required key "GymLocation[color]" has a null value in JSON.');
        assert(json.containsKey(r'order'),
            'Required key "GymLocation[order]" is missing from JSON.');
        assert(json[r'order'] != null,
            'Required key "GymLocation[order]" has a null value in JSON.');
        assert(json.containsKey(r'archived'),
            'Required key "GymLocation[archived]" is missing from JSON.');
        assert(json[r'archived'] != null,
            'Required key "GymLocation[archived]" has a null value in JSON.');
        return true;
      }());

      return GymLocation(
        id: mapValueOfType<String>(json, r'id')!,
        code: mapValueOfType<String>(json, r'code')!,
        name: mapValueOfType<String>(json, r'name')!,
        color: mapValueOfType<String>(json, r'color')!,
        order: mapValueOfType<int>(json, r'order')!,
        archived: mapValueOfType<bool>(json, r'archived')!,
      );
    }
    return null;
  }

  static List<GymLocation> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GymLocation>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GymLocation.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GymLocation> mapFromJson(dynamic json) {
    final map = <String, GymLocation>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GymLocation.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GymLocation-objects as value to a dart map
  static Map<String, List<GymLocation>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GymLocation>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GymLocation.listFromJson(
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
    'code',
    'name',
    'color',
    'order',
    'archived',
  };
}
