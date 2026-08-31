//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UpdatePersonNoteRequest {
  /// Returns a new [UpdatePersonNoteRequest] instance.
  UpdatePersonNoteRequest({
    this.body = const Optional.absent(),
    this.pinned = const Optional.absent(),
    this.happenedOn = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> body;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> pinned;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> happenedOn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdatePersonNoteRequest &&
          other.body == body &&
          other.pinned == pinned &&
          other.happenedOn == happenedOn;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (body == null ? 0 : body!.hashCode) +
      (pinned == null ? 0 : pinned!.hashCode) +
      (happenedOn == null ? 0 : happenedOn!.hashCode);

  @override
  String toString() =>
      'UpdatePersonNoteRequest[body=$body, pinned=$pinned, happenedOn=$happenedOn]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.body.isPresent) {
      final value = this.body.value;
      json[r'body'] = value;
    }
    if (this.pinned.isPresent) {
      final value = this.pinned.value;
      json[r'pinned'] = value;
    }
    if (this.happenedOn.isPresent) {
      final value = this.happenedOn.value;
      json[r'happenedOn'] = value;
    }
    return json;
  }

  /// Clones this instance of [UpdatePersonNoteRequest] and returns a new one where some of the
  /// properties have changed.
  UpdatePersonNoteRequest copyWith({
    Optional<String?>? body,
    Optional<bool?>? pinned,
    Optional<String?>? happenedOn,
  }) =>
      UpdatePersonNoteRequest(
        body: body ?? this.body,
        pinned: pinned ?? this.pinned,
        happenedOn: happenedOn ?? this.happenedOn,
      );

  /// Returns a new [UpdatePersonNoteRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdatePersonNoteRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UpdatePersonNoteRequest(
        body: json.containsKey(r'body')
            ? Optional.present(mapValueOfType<String>(json, r'body'))
            : const Optional.absent(),
        pinned: json.containsKey(r'pinned')
            ? Optional.present(mapValueOfType<bool>(json, r'pinned'))
            : const Optional.absent(),
        happenedOn: json.containsKey(r'happenedOn')
            ? Optional.present(mapValueOfType<String>(json, r'happenedOn'))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<UpdatePersonNoteRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UpdatePersonNoteRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdatePersonNoteRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdatePersonNoteRequest> mapFromJson(dynamic json) {
    final map = <String, UpdatePersonNoteRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdatePersonNoteRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdatePersonNoteRequest-objects as value to a dart map
  static Map<String, List<UpdatePersonNoteRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UpdatePersonNoteRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdatePersonNoteRequest.listFromJson(
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
