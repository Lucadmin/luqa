//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateTimeEntryRequest {
  /// Returns a new [CreateTimeEntryRequest] instance.
  CreateTimeEntryRequest({
    this.description = const Optional.present(''),
    this.categoryId = const Optional.absent(),
    required this.startTime,
    this.endTime = const Optional.absent(),
  });

  final Optional<String?> description;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> categoryId;

  final DateTime startTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<DateTime?> endTime;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateTimeEntryRequest &&
          other.description == description &&
          other.categoryId == categoryId &&
          other.startTime == startTime &&
          other.endTime == endTime;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (description.hashCode) +
      (categoryId == null ? 0 : categoryId!.hashCode) +
      (startTime.hashCode) +
      (endTime == null ? 0 : endTime!.hashCode);

  @override
  String toString() =>
      'CreateTimeEntryRequest[description=$description, categoryId=$categoryId, startTime=$startTime, endTime=$endTime]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.description.isPresent) {
      final value = this.description.value;
      json[r'description'] = value;
    }
    if (this.categoryId.isPresent) {
      final value = this.categoryId.value;
      json[r'categoryId'] = value;
    }
    json[r'startTime'] = this.startTime.toUtc().toIso8601String();
    if (this.endTime.isPresent) {
      final value = this.endTime.value;
      json[r'endTime'] = value == null ? null : value.toUtc().toIso8601String();
    }
    return json;
  }

  /// Clones this instance of [CreateTimeEntryRequest] and returns a new one where some of the
  /// properties have changed.
  CreateTimeEntryRequest copyWith({
    Optional<String?>? description,
    Optional<String?>? categoryId,
    DateTime? startTime,
    Optional<DateTime?>? endTime,
  }) =>
      CreateTimeEntryRequest(
        description: description ?? this.description,
        categoryId: categoryId ?? this.categoryId,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
      );

  /// Returns a new [CreateTimeEntryRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateTimeEntryRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'startTime'),
            'Required key "CreateTimeEntryRequest[startTime]" is missing from JSON.');
        assert(json[r'startTime'] != null,
            'Required key "CreateTimeEntryRequest[startTime]" has a null value in JSON.');
        return true;
      }());

      return CreateTimeEntryRequest(
        description: json.containsKey(r'description')
            ? Optional.present(mapValueOfType<String>(json, r'description'))
            : const Optional.absent(),
        categoryId: json.containsKey(r'categoryId')
            ? Optional.present(mapValueOfType<String>(json, r'categoryId'))
            : const Optional.absent(),
        startTime: mapDateTime(json, r'startTime', r'')!,
        endTime: json.containsKey(r'endTime')
            ? Optional.present(mapDateTime(json, r'endTime', r''))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<CreateTimeEntryRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreateTimeEntryRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateTimeEntryRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateTimeEntryRequest> mapFromJson(dynamic json) {
    final map = <String, CreateTimeEntryRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateTimeEntryRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateTimeEntryRequest-objects as value to a dart map
  static Map<String, List<CreateTimeEntryRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreateTimeEntryRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateTimeEntryRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'startTime',
  };
}
