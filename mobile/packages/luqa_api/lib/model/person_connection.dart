//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PersonConnection {
  /// Returns a new [PersonConnection] instance.
  PersonConnection({
    required this.personId,
    required this.closeness,
  });

  final String personId;

  /// Minimum value: 1
  /// Maximum value: 4
  final int closeness;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonConnection &&
          other.personId == personId &&
          other.closeness == closeness;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (personId.hashCode) + (closeness.hashCode);

  @override
  String toString() =>
      'PersonConnection[personId=$personId, closeness=$closeness]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'personId'] = this.personId;
    json[r'closeness'] = this.closeness;
    return json;
  }

  /// Clones this instance of [PersonConnection] and returns a new one where some of the
  /// properties have changed.
  PersonConnection copyWith({
    String? personId,
    int? closeness,
  }) =>
      PersonConnection(
        personId: personId ?? this.personId,
        closeness: closeness ?? this.closeness,
      );

  /// Returns a new [PersonConnection] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PersonConnection? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'personId'),
            'Required key "PersonConnection[personId]" is missing from JSON.');
        assert(json[r'personId'] != null,
            'Required key "PersonConnection[personId]" has a null value in JSON.');
        assert(json.containsKey(r'closeness'),
            'Required key "PersonConnection[closeness]" is missing from JSON.');
        assert(json[r'closeness'] != null,
            'Required key "PersonConnection[closeness]" has a null value in JSON.');
        return true;
      }());

      return PersonConnection(
        personId: mapValueOfType<String>(json, r'personId')!,
        closeness: mapValueOfType<int>(json, r'closeness')!,
      );
    }
    return null;
  }

  static List<PersonConnection> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PersonConnection>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PersonConnection.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PersonConnection> mapFromJson(dynamic json) {
    final map = <String, PersonConnection>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PersonConnection.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PersonConnection-objects as value to a dart map
  static Map<String, List<PersonConnection>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PersonConnection>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PersonConnection.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'personId',
    'closeness',
  };
}
