//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PersonBalance {
  /// Returns a new [PersonBalance] instance.
  PersonBalance({
    required this.id,
    required this.name,
    required this.color,
    required this.emoji,
    required this.defaultPercent,
    required this.order,
    required this.archived,
    required this.balanceCents,
    required this.coveredCents,
    required this.lastActivity,
  });

  final String id;

  final String name;

  final String color;

  final String? emoji;

  /// Minimum value: 0
  /// Maximum value: 100
  final int? defaultPercent;

  final int order;

  final bool archived;

  /// Positive means they owe the user, negative means the user owes them, zero means settled up.
  final int balanceCents;

  /// All-time total the user covered for them as a treat. Recorded, but never part of a balance.
  final int coveredCents;

  final String? lastActivity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonBalance &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.emoji == emoji &&
          other.defaultPercent == defaultPercent &&
          other.order == order &&
          other.archived == archived &&
          other.balanceCents == balanceCents &&
          other.coveredCents == coveredCents &&
          other.lastActivity == lastActivity;

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
      (balanceCents.hashCode) +
      (coveredCents.hashCode) +
      (lastActivity == null ? 0 : lastActivity!.hashCode);

  @override
  String toString() =>
      'PersonBalance[id=$id, name=$name, color=$color, emoji=$emoji, defaultPercent=$defaultPercent, order=$order, archived=$archived, balanceCents=$balanceCents, coveredCents=$coveredCents, lastActivity=$lastActivity]';

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
    json[r'balanceCents'] = this.balanceCents;
    json[r'coveredCents'] = this.coveredCents;
    if (this.lastActivity != null) {
      json[r'lastActivity'] = this.lastActivity;
    } else {
      json[r'lastActivity'] = null;
    }
    return json;
  }

  /// Clones this instance of [PersonBalance] and returns a new one where some of the
  /// properties have changed.
  PersonBalance copyWith({
    String? id,
    String? name,
    String? color,
    String? emoji,
    bool emojiSetToNull = false,
    int? defaultPercent,
    bool defaultPercentSetToNull = false,
    int? order,
    bool? archived,
    int? balanceCents,
    int? coveredCents,
    String? lastActivity,
    bool lastActivitySetToNull = false,
  }) =>
      PersonBalance(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        emoji: emojiSetToNull ? null : emoji ?? this.emoji,
        defaultPercent: defaultPercentSetToNull
            ? null
            : defaultPercent ?? this.defaultPercent,
        order: order ?? this.order,
        archived: archived ?? this.archived,
        balanceCents: balanceCents ?? this.balanceCents,
        coveredCents: coveredCents ?? this.coveredCents,
        lastActivity:
            lastActivitySetToNull ? null : lastActivity ?? this.lastActivity,
      );

  /// Returns a new [PersonBalance] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PersonBalance? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "PersonBalance[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "PersonBalance[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "PersonBalance[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "PersonBalance[name]" has a null value in JSON.');
        assert(json.containsKey(r'color'),
            'Required key "PersonBalance[color]" is missing from JSON.');
        assert(json[r'color'] != null,
            'Required key "PersonBalance[color]" has a null value in JSON.');
        assert(json.containsKey(r'emoji'),
            'Required key "PersonBalance[emoji]" is missing from JSON.');
        assert(json.containsKey(r'defaultPercent'),
            'Required key "PersonBalance[defaultPercent]" is missing from JSON.');
        assert(json.containsKey(r'order'),
            'Required key "PersonBalance[order]" is missing from JSON.');
        assert(json[r'order'] != null,
            'Required key "PersonBalance[order]" has a null value in JSON.');
        assert(json.containsKey(r'archived'),
            'Required key "PersonBalance[archived]" is missing from JSON.');
        assert(json[r'archived'] != null,
            'Required key "PersonBalance[archived]" has a null value in JSON.');
        assert(json.containsKey(r'balanceCents'),
            'Required key "PersonBalance[balanceCents]" is missing from JSON.');
        assert(json[r'balanceCents'] != null,
            'Required key "PersonBalance[balanceCents]" has a null value in JSON.');
        assert(json.containsKey(r'coveredCents'),
            'Required key "PersonBalance[coveredCents]" is missing from JSON.');
        assert(json[r'coveredCents'] != null,
            'Required key "PersonBalance[coveredCents]" has a null value in JSON.');
        assert(json.containsKey(r'lastActivity'),
            'Required key "PersonBalance[lastActivity]" is missing from JSON.');
        return true;
      }());

      return PersonBalance(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        color: mapValueOfType<String>(json, r'color')!,
        emoji: mapValueOfType<String>(json, r'emoji'),
        defaultPercent: mapValueOfType<int>(json, r'defaultPercent'),
        order: mapValueOfType<int>(json, r'order')!,
        archived: mapValueOfType<bool>(json, r'archived')!,
        balanceCents: mapValueOfType<int>(json, r'balanceCents')!,
        coveredCents: mapValueOfType<int>(json, r'coveredCents')!,
        lastActivity: mapValueOfType<String>(json, r'lastActivity'),
      );
    }
    return null;
  }

  static List<PersonBalance> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PersonBalance>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PersonBalance.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PersonBalance> mapFromJson(dynamic json) {
    final map = <String, PersonBalance>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PersonBalance.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PersonBalance-objects as value to a dart map
  static Map<String, List<PersonBalance>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PersonBalance>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PersonBalance.listFromJson(
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
    'balanceCents',
    'coveredCents',
    'lastActivity',
  };
}
