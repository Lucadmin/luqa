//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreatePersonRequest {
  /// Returns a new [CreatePersonRequest] instance.
  CreatePersonRequest({
    this.id = const Optional.absent(),
    required this.name,
    this.color = const Optional.absent(),
    this.emoji = const Optional.absent(),
    this.defaultPercent = const Optional.absent(),
    this.nickname = const Optional.absent(),
    this.photoUrl = const Optional.absent(),
    this.birthdayYear = const Optional.absent(),
    this.birthdayMonth = const Optional.absent(),
    this.birthdayDay = const Optional.absent(),
    this.cadenceDays = const Optional.absent(),
    this.lastSeenAt = const Optional.absent(),
  });

  /// Preferred identity for someone added offline. Honoured only when free; an existing person with the same name wins, so the response is authoritative.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> id;

  final String name;

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

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> nickname;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> photoUrl;

  /// Minimum value: 1900
  /// Maximum value: 2200
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> birthdayYear;

  /// Minimum value: 1
  /// Maximum value: 12
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> birthdayMonth;

  /// Minimum value: 1
  /// Maximum value: 31
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> birthdayDay;

  /// Minimum value: 1
  /// Maximum value: 3650
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> cadenceDays;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<DateTime?> lastSeenAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreatePersonRequest &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.emoji == emoji &&
          other.defaultPercent == defaultPercent &&
          other.nickname == nickname &&
          other.photoUrl == photoUrl &&
          other.birthdayYear == birthdayYear &&
          other.birthdayMonth == birthdayMonth &&
          other.birthdayDay == birthdayDay &&
          other.cadenceDays == cadenceDays &&
          other.lastSeenAt == lastSeenAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id == null ? 0 : id!.hashCode) +
      (name.hashCode) +
      (color == null ? 0 : color!.hashCode) +
      (emoji == null ? 0 : emoji!.hashCode) +
      (defaultPercent == null ? 0 : defaultPercent!.hashCode) +
      (nickname == null ? 0 : nickname!.hashCode) +
      (photoUrl == null ? 0 : photoUrl!.hashCode) +
      (birthdayYear == null ? 0 : birthdayYear!.hashCode) +
      (birthdayMonth == null ? 0 : birthdayMonth!.hashCode) +
      (birthdayDay == null ? 0 : birthdayDay!.hashCode) +
      (cadenceDays == null ? 0 : cadenceDays!.hashCode) +
      (lastSeenAt == null ? 0 : lastSeenAt!.hashCode);

  @override
  String toString() =>
      'CreatePersonRequest[id=$id, name=$name, color=$color, emoji=$emoji, defaultPercent=$defaultPercent, nickname=$nickname, photoUrl=$photoUrl, birthdayYear=$birthdayYear, birthdayMonth=$birthdayMonth, birthdayDay=$birthdayDay, cadenceDays=$cadenceDays, lastSeenAt=$lastSeenAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id.isPresent) {
      final value = this.id.value;
      json[r'id'] = value;
    }
    json[r'name'] = this.name;
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
    if (this.nickname.isPresent) {
      final value = this.nickname.value;
      json[r'nickname'] = value;
    }
    if (this.photoUrl.isPresent) {
      final value = this.photoUrl.value;
      json[r'photoUrl'] = value;
    }
    if (this.birthdayYear.isPresent) {
      final value = this.birthdayYear.value;
      json[r'birthdayYear'] = value;
    }
    if (this.birthdayMonth.isPresent) {
      final value = this.birthdayMonth.value;
      json[r'birthdayMonth'] = value;
    }
    if (this.birthdayDay.isPresent) {
      final value = this.birthdayDay.value;
      json[r'birthdayDay'] = value;
    }
    if (this.cadenceDays.isPresent) {
      final value = this.cadenceDays.value;
      json[r'cadenceDays'] = value;
    }
    if (this.lastSeenAt.isPresent) {
      final value = this.lastSeenAt.value;
      json[r'lastSeenAt'] =
          value == null ? null : value.toUtc().toIso8601String();
    }
    return json;
  }

  /// Clones this instance of [CreatePersonRequest] and returns a new one where some of the
  /// properties have changed.
  CreatePersonRequest copyWith({
    Optional<String?>? id,
    String? name,
    Optional<String?>? color,
    Optional<String?>? emoji,
    Optional<int?>? defaultPercent,
    Optional<String?>? nickname,
    Optional<String?>? photoUrl,
    Optional<int?>? birthdayYear,
    Optional<int?>? birthdayMonth,
    Optional<int?>? birthdayDay,
    Optional<int?>? cadenceDays,
    Optional<DateTime?>? lastSeenAt,
  }) =>
      CreatePersonRequest(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        emoji: emoji ?? this.emoji,
        defaultPercent: defaultPercent ?? this.defaultPercent,
        nickname: nickname ?? this.nickname,
        photoUrl: photoUrl ?? this.photoUrl,
        birthdayYear: birthdayYear ?? this.birthdayYear,
        birthdayMonth: birthdayMonth ?? this.birthdayMonth,
        birthdayDay: birthdayDay ?? this.birthdayDay,
        cadenceDays: cadenceDays ?? this.cadenceDays,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      );

  /// Returns a new [CreatePersonRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreatePersonRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'),
            'Required key "CreatePersonRequest[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "CreatePersonRequest[name]" has a null value in JSON.');
        return true;
      }());

      return CreatePersonRequest(
        id: json.containsKey(r'id')
            ? Optional.present(mapValueOfType<String>(json, r'id'))
            : const Optional.absent(),
        name: mapValueOfType<String>(json, r'name')!,
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
        nickname: json.containsKey(r'nickname')
            ? Optional.present(mapValueOfType<String>(json, r'nickname'))
            : const Optional.absent(),
        photoUrl: json.containsKey(r'photoUrl')
            ? Optional.present(mapValueOfType<String>(json, r'photoUrl'))
            : const Optional.absent(),
        birthdayYear: json.containsKey(r'birthdayYear')
            ? Optional.present(json[r'birthdayYear'] == null
                ? null
                : int.parse('${json[r'birthdayYear']}'))
            : const Optional.absent(),
        birthdayMonth: json.containsKey(r'birthdayMonth')
            ? Optional.present(json[r'birthdayMonth'] == null
                ? null
                : int.parse('${json[r'birthdayMonth']}'))
            : const Optional.absent(),
        birthdayDay: json.containsKey(r'birthdayDay')
            ? Optional.present(json[r'birthdayDay'] == null
                ? null
                : int.parse('${json[r'birthdayDay']}'))
            : const Optional.absent(),
        cadenceDays: json.containsKey(r'cadenceDays')
            ? Optional.present(json[r'cadenceDays'] == null
                ? null
                : int.parse('${json[r'cadenceDays']}'))
            : const Optional.absent(),
        lastSeenAt: json.containsKey(r'lastSeenAt')
            ? Optional.present(mapDateTime(json, r'lastSeenAt', r''))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<CreatePersonRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreatePersonRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreatePersonRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreatePersonRequest> mapFromJson(dynamic json) {
    final map = <String, CreatePersonRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreatePersonRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreatePersonRequest-objects as value to a dart map
  static Map<String, List<CreatePersonRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreatePersonRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreatePersonRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
  };
}
