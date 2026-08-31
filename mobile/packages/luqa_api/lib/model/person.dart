//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Person {
  /// Returns a new [Person] instance.
  Person({
    required this.id,
    required this.name,
    required this.color,
    required this.emoji,
    required this.defaultPercent,
    required this.order,
    required this.archived,
    required this.nickname,
    required this.photoUrl,
    required this.birthdayYear,
    required this.birthdayMonth,
    required this.birthdayDay,
    required this.cadenceDays,
    required this.lastSeenAt,
    required this.googleResourceName,
    this.places = const [],
    this.channels = const [],
    this.notes = const [],
    this.gifts = const [],
  });

  final String id;

  final String name;

  final String color;

  final String? emoji;

  /// The cut of a bill this person usually carries, in whole percent. Null means share equally with everyone else on it.
  ///
  /// Minimum value: 0
  /// Maximum value: 100
  final int? defaultPercent;

  final int order;

  final bool archived;

  /// What the owner actually calls them.
  final String? nickname;

  final String? photoUrl;

  /// Null far more often than not. Most contacts carry a day and a month and no year, and inventing one produces a confidently wrong age, so a missing year is simply missing and no age is offered.
  final int? birthdayYear;

  /// Minimum value: 1
  /// Maximum value: 12
  final int? birthdayMonth;

  /// 29 February is storable, because it is a real birthday. Which day it falls on in a common year is the client's next-occurrence rule.
  ///
  /// Minimum value: 1
  /// Maximum value: 31
  final int? birthdayDay;

  /// How often being in touch is worth aiming for. Null for most people, and null means they are never reported as overdue.
  final int? cadenceDays;

  final DateTime? lastSeenAt;

  /// The People API resource this row is linked to. Null for someone who exists only in Luqa.
  final String? googleResourceName;

  final List<PersonPlace> places;

  final List<PersonChannel> channels;

  final List<PersonNote> notes;

  final List<PersonGiftIdea> gifts;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.emoji == emoji &&
          other.defaultPercent == defaultPercent &&
          other.order == order &&
          other.archived == archived &&
          other.nickname == nickname &&
          other.photoUrl == photoUrl &&
          other.birthdayYear == birthdayYear &&
          other.birthdayMonth == birthdayMonth &&
          other.birthdayDay == birthdayDay &&
          other.cadenceDays == cadenceDays &&
          other.lastSeenAt == lastSeenAt &&
          other.googleResourceName == googleResourceName &&
          _deepEquality.equals(other.places, places) &&
          _deepEquality.equals(other.channels, channels) &&
          _deepEquality.equals(other.notes, notes) &&
          _deepEquality.equals(other.gifts, gifts);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (name.hashCode) +
      (color.hashCode) +
      (emoji == null ? 0 : emoji!.hashCode) +
      (defaultPercent == null ? 0 : defaultPercent!.hashCode) +
      (order.hashCode) +
      (archived.hashCode) +
      (nickname == null ? 0 : nickname!.hashCode) +
      (photoUrl == null ? 0 : photoUrl!.hashCode) +
      (birthdayYear == null ? 0 : birthdayYear!.hashCode) +
      (birthdayMonth == null ? 0 : birthdayMonth!.hashCode) +
      (birthdayDay == null ? 0 : birthdayDay!.hashCode) +
      (cadenceDays == null ? 0 : cadenceDays!.hashCode) +
      (lastSeenAt == null ? 0 : lastSeenAt!.hashCode) +
      (googleResourceName == null ? 0 : googleResourceName!.hashCode) +
      (places.hashCode) +
      (channels.hashCode) +
      (notes.hashCode) +
      (gifts.hashCode);

  @override
  String toString() =>
      'Person[id=$id, name=$name, color=$color, emoji=$emoji, defaultPercent=$defaultPercent, order=$order, archived=$archived, nickname=$nickname, photoUrl=$photoUrl, birthdayYear=$birthdayYear, birthdayMonth=$birthdayMonth, birthdayDay=$birthdayDay, cadenceDays=$cadenceDays, lastSeenAt=$lastSeenAt, googleResourceName=$googleResourceName, places=$places, channels=$channels, notes=$notes, gifts=$gifts]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'name'] = this.name;
    json[r'color'] = this.color;
    if (this.emoji != null) {
      json[r'emoji'] = this.emoji;
    } else {
      json[r'emoji'] = null;
    }
    if (this.defaultPercent != null) {
      json[r'defaultPercent'] = this.defaultPercent;
    } else {
      json[r'defaultPercent'] = null;
    }
    json[r'order'] = this.order;
    json[r'archived'] = this.archived;
    if (this.nickname != null) {
      json[r'nickname'] = this.nickname;
    } else {
      json[r'nickname'] = null;
    }
    if (this.photoUrl != null) {
      json[r'photoUrl'] = this.photoUrl;
    } else {
      json[r'photoUrl'] = null;
    }
    if (this.birthdayYear != null) {
      json[r'birthdayYear'] = this.birthdayYear;
    } else {
      json[r'birthdayYear'] = null;
    }
    if (this.birthdayMonth != null) {
      json[r'birthdayMonth'] = this.birthdayMonth;
    } else {
      json[r'birthdayMonth'] = null;
    }
    if (this.birthdayDay != null) {
      json[r'birthdayDay'] = this.birthdayDay;
    } else {
      json[r'birthdayDay'] = null;
    }
    if (this.cadenceDays != null) {
      json[r'cadenceDays'] = this.cadenceDays;
    } else {
      json[r'cadenceDays'] = null;
    }
    if (this.lastSeenAt != null) {
      json[r'lastSeenAt'] = this.lastSeenAt!.toUtc().toIso8601String();
    } else {
      json[r'lastSeenAt'] = null;
    }
    if (this.googleResourceName != null) {
      json[r'googleResourceName'] = this.googleResourceName;
    } else {
      json[r'googleResourceName'] = null;
    }
    json[r'places'] = this.places;
    json[r'channels'] = this.channels;
    json[r'notes'] = this.notes;
    json[r'gifts'] = this.gifts;
    return json;
  }

  /// Clones this instance of [Person] and returns a new one where some of the
  /// properties have changed.
  Person copyWith({
    String? id,
    String? name,
    String? color,
    String? emoji,
    bool emojiSetToNull = false,
    int? defaultPercent,
    bool defaultPercentSetToNull = false,
    int? order,
    bool? archived,
    String? nickname,
    bool nicknameSetToNull = false,
    String? photoUrl,
    bool photoUrlSetToNull = false,
    int? birthdayYear,
    bool birthdayYearSetToNull = false,
    int? birthdayMonth,
    bool birthdayMonthSetToNull = false,
    int? birthdayDay,
    bool birthdayDaySetToNull = false,
    int? cadenceDays,
    bool cadenceDaysSetToNull = false,
    DateTime? lastSeenAt,
    bool lastSeenAtSetToNull = false,
    String? googleResourceName,
    bool googleResourceNameSetToNull = false,
    List<PersonPlace>? places,
    List<PersonChannel>? channels,
    List<PersonNote>? notes,
    List<PersonGiftIdea>? gifts,
  }) =>
      Person(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        emoji: emojiSetToNull ? null : emoji ?? this.emoji,
        defaultPercent: defaultPercentSetToNull
            ? null
            : defaultPercent ?? this.defaultPercent,
        order: order ?? this.order,
        archived: archived ?? this.archived,
        nickname: nicknameSetToNull ? null : nickname ?? this.nickname,
        photoUrl: photoUrlSetToNull ? null : photoUrl ?? this.photoUrl,
        birthdayYear:
            birthdayYearSetToNull ? null : birthdayYear ?? this.birthdayYear,
        birthdayMonth:
            birthdayMonthSetToNull ? null : birthdayMonth ?? this.birthdayMonth,
        birthdayDay:
            birthdayDaySetToNull ? null : birthdayDay ?? this.birthdayDay,
        cadenceDays:
            cadenceDaysSetToNull ? null : cadenceDays ?? this.cadenceDays,
        lastSeenAt: lastSeenAtSetToNull ? null : lastSeenAt ?? this.lastSeenAt,
        googleResourceName: googleResourceNameSetToNull
            ? null
            : googleResourceName ?? this.googleResourceName,
        places: places ?? this.places,
        channels: channels ?? this.channels,
        notes: notes ?? this.notes,
        gifts: gifts ?? this.gifts,
      );

  /// Returns a new [Person] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Person? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "Person[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "Person[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "Person[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "Person[name]" has a null value in JSON.');
        assert(json.containsKey(r'color'),
            'Required key "Person[color]" is missing from JSON.');
        assert(json[r'color'] != null,
            'Required key "Person[color]" has a null value in JSON.');
        assert(json.containsKey(r'emoji'),
            'Required key "Person[emoji]" is missing from JSON.');
        assert(json.containsKey(r'defaultPercent'),
            'Required key "Person[defaultPercent]" is missing from JSON.');
        assert(json.containsKey(r'order'),
            'Required key "Person[order]" is missing from JSON.');
        assert(json[r'order'] != null,
            'Required key "Person[order]" has a null value in JSON.');
        assert(json.containsKey(r'archived'),
            'Required key "Person[archived]" is missing from JSON.');
        assert(json[r'archived'] != null,
            'Required key "Person[archived]" has a null value in JSON.');
        assert(json.containsKey(r'nickname'),
            'Required key "Person[nickname]" is missing from JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "Person[photoUrl]" is missing from JSON.');
        assert(json.containsKey(r'birthdayYear'),
            'Required key "Person[birthdayYear]" is missing from JSON.');
        assert(json.containsKey(r'birthdayMonth'),
            'Required key "Person[birthdayMonth]" is missing from JSON.');
        assert(json.containsKey(r'birthdayDay'),
            'Required key "Person[birthdayDay]" is missing from JSON.');
        assert(json.containsKey(r'cadenceDays'),
            'Required key "Person[cadenceDays]" is missing from JSON.');
        assert(json.containsKey(r'lastSeenAt'),
            'Required key "Person[lastSeenAt]" is missing from JSON.');
        assert(json.containsKey(r'googleResourceName'),
            'Required key "Person[googleResourceName]" is missing from JSON.');
        assert(json.containsKey(r'places'),
            'Required key "Person[places]" is missing from JSON.');
        assert(json[r'places'] != null,
            'Required key "Person[places]" has a null value in JSON.');
        assert(json.containsKey(r'channels'),
            'Required key "Person[channels]" is missing from JSON.');
        assert(json[r'channels'] != null,
            'Required key "Person[channels]" has a null value in JSON.');
        assert(json.containsKey(r'notes'),
            'Required key "Person[notes]" is missing from JSON.');
        assert(json[r'notes'] != null,
            'Required key "Person[notes]" has a null value in JSON.');
        assert(json.containsKey(r'gifts'),
            'Required key "Person[gifts]" is missing from JSON.');
        assert(json[r'gifts'] != null,
            'Required key "Person[gifts]" has a null value in JSON.');
        return true;
      }());

      return Person(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        color: mapValueOfType<String>(json, r'color')!,
        emoji: mapValueOfType<String>(json, r'emoji'),
        defaultPercent: mapValueOfType<int>(json, r'defaultPercent'),
        order: mapValueOfType<int>(json, r'order')!,
        archived: mapValueOfType<bool>(json, r'archived')!,
        nickname: mapValueOfType<String>(json, r'nickname'),
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
        birthdayYear: mapValueOfType<int>(json, r'birthdayYear'),
        birthdayMonth: mapValueOfType<int>(json, r'birthdayMonth'),
        birthdayDay: mapValueOfType<int>(json, r'birthdayDay'),
        cadenceDays: mapValueOfType<int>(json, r'cadenceDays'),
        lastSeenAt: mapDateTime(json, r'lastSeenAt', r''),
        googleResourceName: mapValueOfType<String>(json, r'googleResourceName'),
        places: PersonPlace.listFromJson(json[r'places']),
        channels: PersonChannel.listFromJson(json[r'channels']),
        notes: PersonNote.listFromJson(json[r'notes']),
        gifts: PersonGiftIdea.listFromJson(json[r'gifts']),
      );
    }
    return null;
  }

  static List<Person> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Person>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Person.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Person> mapFromJson(dynamic json) {
    final map = <String, Person>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Person.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Person-objects as value to a dart map
  static Map<String, List<Person>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Person>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Person.listFromJson(
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
    'name',
    'color',
    'emoji',
    'defaultPercent',
    'order',
    'archived',
    'nickname',
    'photoUrl',
    'birthdayYear',
    'birthdayMonth',
    'birthdayDay',
    'cadenceDays',
    'lastSeenAt',
    'googleResourceName',
    'places',
    'channels',
    'notes',
    'gifts',
  };
}
