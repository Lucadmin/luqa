//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PersonGiftIdea {
  /// Returns a new [PersonGiftIdea] instance.
  PersonGiftIdea({
    required this.id,
    required this.idea,
    required this.url,
    required this.givenAt,
  });

  final String id;

  final String idea;

  final String? url;

  /// Set once given. The row is kept rather than deleted, because the list's second job is not giving the same thing twice.
  final DateTime? givenAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonGiftIdea &&
          other.id == id &&
          other.idea == idea &&
          other.url == url &&
          other.givenAt == givenAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (idea.hashCode) +
      (url == null ? 0 : url!.hashCode) +
      (givenAt == null ? 0 : givenAt!.hashCode);

  @override
  String toString() =>
      'PersonGiftIdea[id=$id, idea=$idea, url=$url, givenAt=$givenAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'idea'] = this.idea;
    if (this.url != null) {
      json[r'url'] = this.url;
    } else {
      json[r'url'] = null;
    }
    if (this.givenAt != null) {
      json[r'givenAt'] = this.givenAt!.toUtc().toIso8601String();
    } else {
      json[r'givenAt'] = null;
    }
    return json;
  }

  /// Clones this instance of [PersonGiftIdea] and returns a new one where some of the
  /// properties have changed.
  PersonGiftIdea copyWith({
    String? id,
    String? idea,
    String? url,
    bool urlSetToNull = false,
    DateTime? givenAt,
    bool givenAtSetToNull = false,
  }) =>
      PersonGiftIdea(
        id: id ?? this.id,
        idea: idea ?? this.idea,
        url: urlSetToNull ? null : url ?? this.url,
        givenAt: givenAtSetToNull ? null : givenAt ?? this.givenAt,
      );

  /// Returns a new [PersonGiftIdea] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PersonGiftIdea? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "PersonGiftIdea[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "PersonGiftIdea[id]" has a null value in JSON.');
        assert(json.containsKey(r'idea'),
            'Required key "PersonGiftIdea[idea]" is missing from JSON.');
        assert(json[r'idea'] != null,
            'Required key "PersonGiftIdea[idea]" has a null value in JSON.');
        assert(json.containsKey(r'url'),
            'Required key "PersonGiftIdea[url]" is missing from JSON.');
        assert(json.containsKey(r'givenAt'),
            'Required key "PersonGiftIdea[givenAt]" is missing from JSON.');
        return true;
      }());

      return PersonGiftIdea(
        id: mapValueOfType<String>(json, r'id')!,
        idea: mapValueOfType<String>(json, r'idea')!,
        url: mapValueOfType<String>(json, r'url'),
        givenAt: mapDateTime(json, r'givenAt', r''),
      );
    }
    return null;
  }

  static List<PersonGiftIdea> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PersonGiftIdea>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PersonGiftIdea.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PersonGiftIdea> mapFromJson(dynamic json) {
    final map = <String, PersonGiftIdea>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PersonGiftIdea.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PersonGiftIdea-objects as value to a dart map
  static Map<String, List<PersonGiftIdea>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PersonGiftIdea>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PersonGiftIdea.listFromJson(
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
    'idea',
    'url',
    'givenAt',
  };
}
