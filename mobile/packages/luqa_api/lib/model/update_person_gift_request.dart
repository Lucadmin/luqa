//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UpdatePersonGiftRequest {
  /// Returns a new [UpdatePersonGiftRequest] instance.
  UpdatePersonGiftRequest({
    this.idea = const Optional.absent(),
    this.url = const Optional.absent(),
    this.givenAt = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> idea;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> url;

  /// A date marks it given; null puts it back on the list. Either way the row stays.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<DateTime?> givenAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdatePersonGiftRequest &&
          other.idea == idea &&
          other.url == url &&
          other.givenAt == givenAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (idea == null ? 0 : idea!.hashCode) +
      (url == null ? 0 : url!.hashCode) +
      (givenAt == null ? 0 : givenAt!.hashCode);

  @override
  String toString() =>
      'UpdatePersonGiftRequest[idea=$idea, url=$url, givenAt=$givenAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.idea.isPresent) {
      final value = this.idea.value;
      json[r'idea'] = value;
    }
    if (this.url.isPresent) {
      final value = this.url.value;
      json[r'url'] = value;
    }
    if (this.givenAt.isPresent) {
      final value = this.givenAt.value;
      json[r'givenAt'] = value == null ? null : value.toUtc().toIso8601String();
    }
    return json;
  }

  /// Clones this instance of [UpdatePersonGiftRequest] and returns a new one where some of the
  /// properties have changed.
  UpdatePersonGiftRequest copyWith({
    Optional<String?>? idea,
    Optional<String?>? url,
    Optional<DateTime?>? givenAt,
  }) =>
      UpdatePersonGiftRequest(
        idea: idea ?? this.idea,
        url: url ?? this.url,
        givenAt: givenAt ?? this.givenAt,
      );

  /// Returns a new [UpdatePersonGiftRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdatePersonGiftRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UpdatePersonGiftRequest(
        idea: json.containsKey(r'idea')
            ? Optional.present(mapValueOfType<String>(json, r'idea'))
            : const Optional.absent(),
        url: json.containsKey(r'url')
            ? Optional.present(mapValueOfType<String>(json, r'url'))
            : const Optional.absent(),
        givenAt: json.containsKey(r'givenAt')
            ? Optional.present(mapDateTime(json, r'givenAt', r''))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<UpdatePersonGiftRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UpdatePersonGiftRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdatePersonGiftRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdatePersonGiftRequest> mapFromJson(dynamic json) {
    final map = <String, UpdatePersonGiftRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdatePersonGiftRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdatePersonGiftRequest-objects as value to a dart map
  static Map<String, List<UpdatePersonGiftRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UpdatePersonGiftRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdatePersonGiftRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{};
}
