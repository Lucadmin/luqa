//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UpdatePersonRequest {
  /// Returns a new [UpdatePersonRequest] instance.
  UpdatePersonRequest({
    this.name = const Optional.absent(),
    this.color = const Optional.absent(),
    this.emoji = const Optional.absent(),
    this.defaultPercent = const Optional.absent(),
    this.order = const Optional.absent(),
    this.archived = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> color;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> emoji;

  /// Minimum value: 0
  /// Maximum value: 100
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> defaultPercent;

  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> order;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> archived;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdatePersonRequest &&
          other.name == name &&
          other.color == color &&
          other.emoji == emoji &&
          other.defaultPercent == defaultPercent &&
          other.order == order &&
          other.archived == archived;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name == null ? 0 : name!.hashCode) +
      (color == null ? 0 : color!.hashCode) +
      (emoji == null ? 0 : emoji!.hashCode) +
      (defaultPercent == null ? 0 : defaultPercent!.hashCode) +
      (order == null ? 0 : order!.hashCode) +
      (archived == null ? 0 : archived!.hashCode);

  @override
  String toString() =>
      'UpdatePersonRequest[name=$name, color=$color, emoji=$emoji, defaultPercent=$defaultPercent, order=$order, archived=$archived]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name.isPresent) {
      final value = this.name.value;
      json[r'name'] = value;
    }
    if (this.color.isPresent) {
      final value = this.color.value;
      json[r'color'] = value;
    }
    if (this.emoji.isPresent) {
      final value = this.emoji.value;
      json[r'emoji'] = value;
    }
    if (this.defaultPercent.isPresent) {
      final value = this.defaultPercent.value;
      json[r'defaultPercent'] = value;
    }
    if (this.order.isPresent) {
      final value = this.order.value;
      json[r'order'] = value;
    }
    if (this.archived.isPresent) {
      final value = this.archived.value;
      json[r'archived'] = value;
    }
    return json;
  }

  /// Clones this instance of [UpdatePersonRequest] and returns a new one where some of the
  /// properties have changed.
  UpdatePersonRequest copyWith({
    Optional<String?>? name,
    Optional<String?>? color,
    Optional<String?>? emoji,
    Optional<int?>? defaultPercent,
    Optional<int?>? order,
    Optional<bool?>? archived,
  }) =>
      UpdatePersonRequest(
        name: name ?? this.name,
        color: color ?? this.color,
        emoji: emoji ?? this.emoji,
        defaultPercent: defaultPercent ?? this.defaultPercent,
        order: order ?? this.order,
        archived: archived ?? this.archived,
      );

  /// Returns a new [UpdatePersonRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdatePersonRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UpdatePersonRequest(
        name: json.containsKey(r'name')
            ? Optional.present(mapValueOfType<String>(json, r'name'))
            : const Optional.absent(),
        color: json.containsKey(r'color')
            ? Optional.present(mapValueOfType<String>(json, r'color'))
            : const Optional.absent(),
        emoji: json.containsKey(r'emoji')
            ? Optional.present(mapValueOfType<String>(json, r'emoji'))
            : const Optional.absent(),
        defaultPercent: json.containsKey(r'defaultPercent')
            ? Optional.present(json[r'defaultPercent'] == null
                ? null
                : int.parse('${json[r'defaultPercent']}'))
            : const Optional.absent(),
        order: json.containsKey(r'order')
            ? Optional.present(
                json[r'order'] == null ? null : int.parse('${json[r'order']}'))
            : const Optional.absent(),
        archived: json.containsKey(r'archived')
            ? Optional.present(mapValueOfType<bool>(json, r'archived'))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<UpdatePersonRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UpdatePersonRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdatePersonRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdatePersonRequest> mapFromJson(dynamic json) {
    final map = <String, UpdatePersonRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdatePersonRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdatePersonRequest-objects as value to a dart map
  static Map<String, List<UpdatePersonRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UpdatePersonRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdatePersonRequest.listFromJson(
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
