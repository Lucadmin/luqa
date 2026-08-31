//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PersonNote {
  /// Returns a new [PersonNote] instance.
  PersonNote({
    required this.id,
    required this.body,
    required this.pinned,
    required this.happenedOn,
    required this.createdAt,
  });

  final String id;

  final String body;

  /// Kept at the top: the allergy, the kids' names, the thing not to bring up.
  final bool pinned;

  final String? happenedOn;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonNote &&
          other.id == id &&
          other.body == body &&
          other.pinned == pinned &&
          other.happenedOn == happenedOn &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (body.hashCode) +
      (pinned.hashCode) +
      (happenedOn == null ? 0 : happenedOn!.hashCode) +
      (createdAt.hashCode);

  @override
  String toString() =>
      'PersonNote[id=$id, body=$body, pinned=$pinned, happenedOn=$happenedOn, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'body'] = this.body;
    json[r'pinned'] = this.pinned;
    if (this.happenedOn != null) {
      json[r'happenedOn'] = this.happenedOn;
    } else {
      json[r'happenedOn'] = null;
    }
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [PersonNote] and returns a new one where some of the
  /// properties have changed.
  PersonNote copyWith({
    String? id,
    String? body,
    bool? pinned,
    String? happenedOn,
    bool happenedOnSetToNull = false,
    DateTime? createdAt,
  }) =>
      PersonNote(
        id: id ?? this.id,
        body: body ?? this.body,
        pinned: pinned ?? this.pinned,
        happenedOn: happenedOnSetToNull ? null : happenedOn ?? this.happenedOn,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Returns a new [PersonNote] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PersonNote? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "PersonNote[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "PersonNote[id]" has a null value in JSON.');
        assert(json.containsKey(r'body'),
            'Required key "PersonNote[body]" is missing from JSON.');
        assert(json[r'body'] != null,
            'Required key "PersonNote[body]" has a null value in JSON.');
        assert(json.containsKey(r'pinned'),
            'Required key "PersonNote[pinned]" is missing from JSON.');
        assert(json[r'pinned'] != null,
            'Required key "PersonNote[pinned]" has a null value in JSON.');
        assert(json.containsKey(r'happenedOn'),
            'Required key "PersonNote[happenedOn]" is missing from JSON.');
        assert(json.containsKey(r'createdAt'),
            'Required key "PersonNote[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null,
            'Required key "PersonNote[createdAt]" has a null value in JSON.');
        return true;
      }());

      return PersonNote(
        id: mapValueOfType<String>(json, r'id')!,
        body: mapValueOfType<String>(json, r'body')!,
        pinned: mapValueOfType<bool>(json, r'pinned')!,
        happenedOn: mapValueOfType<String>(json, r'happenedOn'),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<PersonNote> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PersonNote>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PersonNote.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PersonNote> mapFromJson(dynamic json) {
    final map = <String, PersonNote>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PersonNote.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PersonNote-objects as value to a dart map
  static Map<String, List<PersonNote>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PersonNote>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PersonNote.listFromJson(
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
    'body',
    'pinned',
    'happenedOn',
    'createdAt',
  };
}
