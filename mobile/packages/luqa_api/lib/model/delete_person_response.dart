//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DeletePersonResponse {
  /// Returns a new [DeletePersonResponse] instance.
  DeletePersonResponse({
    required this.deleted,
  });

  /// True when the person was removed outright, false when they were archived because bills or paybacks still reference them.
  final bool deleted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeletePersonResponse && other.deleted == deleted;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (deleted.hashCode);

  @override
  String toString() => 'DeletePersonResponse[deleted=$deleted]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'deleted'] = this.deleted;
    return json;
  }

  /// Clones this instance of [DeletePersonResponse] and returns a new one where some of the
  /// properties have changed.
  DeletePersonResponse copyWith({
    bool? deleted,
  }) =>
      DeletePersonResponse(
        deleted: deleted ?? this.deleted,
      );

  /// Returns a new [DeletePersonResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DeletePersonResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'deleted'),
            'Required key "DeletePersonResponse[deleted]" is missing from JSON.');
        assert(json[r'deleted'] != null,
            'Required key "DeletePersonResponse[deleted]" has a null value in JSON.');
        return true;
      }());

      return DeletePersonResponse(
        deleted: mapValueOfType<bool>(json, r'deleted')!,
      );
    }
    return null;
  }

  static List<DeletePersonResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <DeletePersonResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DeletePersonResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DeletePersonResponse> mapFromJson(dynamic json) {
    final map = <String, DeletePersonResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DeletePersonResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DeletePersonResponse-objects as value to a dart map
  static Map<String, List<DeletePersonResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<DeletePersonResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DeletePersonResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'deleted',
  };
}
