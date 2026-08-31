//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GroupResponse {
  /// Returns a new [GroupResponse] instance.
  GroupResponse({
    required this.group,
  });

  final PersonGroup group;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GroupResponse && other.group == group;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (group.hashCode);

  @override
  String toString() => 'GroupResponse[group=$group]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'group'] = this.group;
    return json;
  }

  /// Clones this instance of [GroupResponse] and returns a new one where some of the
  /// properties have changed.
  GroupResponse copyWith({
    PersonGroup? group,
  }) =>
      GroupResponse(
        group: group ?? this.group,
      );

  /// Returns a new [GroupResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GroupResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'group'),
            'Required key "GroupResponse[group]" is missing from JSON.');
        assert(json[r'group'] != null,
            'Required key "GroupResponse[group]" has a null value in JSON.');
        return true;
      }());

      return GroupResponse(
        group: PersonGroup.fromJson(json[r'group'])!,
      );
    }
    return null;
  }

  static List<GroupResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GroupResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GroupResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GroupResponse> mapFromJson(dynamic json) {
    final map = <String, GroupResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GroupResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GroupResponse-objects as value to a dart map
  static Map<String, List<GroupResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GroupResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GroupResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'group',
  };
}
