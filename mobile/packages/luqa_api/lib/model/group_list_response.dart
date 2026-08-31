//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GroupListResponse {
  /// Returns a new [GroupListResponse] instance.
  GroupListResponse({
    this.groups = const [],
  });

  final List<PersonGroup> groups;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupListResponse && _deepEquality.equals(other.groups, groups);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (groups.hashCode);

  @override
  String toString() => 'GroupListResponse[groups=$groups]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'groups'] = this.groups;
    return json;
  }

  /// Clones this instance of [GroupListResponse] and returns a new one where some of the
  /// properties have changed.
  GroupListResponse copyWith({
    List<PersonGroup>? groups,
  }) =>
      GroupListResponse(
        groups: groups ?? this.groups,
      );

  /// Returns a new [GroupListResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GroupListResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'groups'),
            'Required key "GroupListResponse[groups]" is missing from JSON.');
        assert(json[r'groups'] != null,
            'Required key "GroupListResponse[groups]" has a null value in JSON.');
        return true;
      }());

      return GroupListResponse(
        groups: PersonGroup.listFromJson(json[r'groups']),
      );
    }
    return null;
  }

  static List<GroupListResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GroupListResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GroupListResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GroupListResponse> mapFromJson(dynamic json) {
    final map = <String, GroupListResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GroupListResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GroupListResponse-objects as value to a dart map
  static Map<String, List<GroupListResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GroupListResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GroupListResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'groups',
  };
}
