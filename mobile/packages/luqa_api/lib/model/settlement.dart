//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Settlement {
  /// Returns a new [Settlement] instance.
  Settlement({
    required this.id,
    required this.personId,
    required this.amountCents,
    required this.direction,
    required this.date,
    required this.notes,
    required this.createdAt,
  });

  final String id;

  final String personId;

  final int amountCents;

  final SettlementDirection direction;

  final String date;

  final String notes;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Settlement &&
          other.id == id &&
          other.personId == personId &&
          other.amountCents == amountCents &&
          other.direction == direction &&
          other.date == date &&
          other.notes == notes &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (personId.hashCode) +
      (amountCents.hashCode) +
      (direction.hashCode) +
      (date.hashCode) +
      (notes.hashCode) +
      (createdAt.hashCode);

  @override
  String toString() =>
      'Settlement[id=$id, personId=$personId, amountCents=$amountCents, direction=$direction, date=$date, notes=$notes, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'personId'] = this.personId;
    json[r'amountCents'] = this.amountCents;
    json[r'direction'] = this.direction;
    json[r'date'] = this.date;
    json[r'notes'] = this.notes;
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [Settlement] and returns a new one where some of the
  /// properties have changed.
  Settlement copyWith({
    String? id,
    String? personId,
    int? amountCents,
    SettlementDirection? direction,
    String? date,
    String? notes,
    DateTime? createdAt,
  }) =>
      Settlement(
        id: id ?? this.id,
        personId: personId ?? this.personId,
        amountCents: amountCents ?? this.amountCents,
        direction: direction ?? this.direction,
        date: date ?? this.date,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Returns a new [Settlement] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Settlement? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "Settlement[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "Settlement[id]" has a null value in JSON.');
        assert(json.containsKey(r'personId'),
            'Required key "Settlement[personId]" is missing from JSON.');
        assert(json[r'personId'] != null,
            'Required key "Settlement[personId]" has a null value in JSON.');
        assert(json.containsKey(r'amountCents'),
            'Required key "Settlement[amountCents]" is missing from JSON.');
        assert(json[r'amountCents'] != null,
            'Required key "Settlement[amountCents]" has a null value in JSON.');
        assert(json.containsKey(r'direction'),
            'Required key "Settlement[direction]" is missing from JSON.');
        assert(json[r'direction'] != null,
            'Required key "Settlement[direction]" has a null value in JSON.');
        assert(json.containsKey(r'date'),
            'Required key "Settlement[date]" is missing from JSON.');
        assert(json[r'date'] != null,
            'Required key "Settlement[date]" has a null value in JSON.');
        assert(json.containsKey(r'notes'),
            'Required key "Settlement[notes]" is missing from JSON.');
        assert(json[r'notes'] != null,
            'Required key "Settlement[notes]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'),
            'Required key "Settlement[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null,
            'Required key "Settlement[createdAt]" has a null value in JSON.');
        return true;
      }());

      return Settlement(
        id: mapValueOfType<String>(json, r'id')!,
        personId: mapValueOfType<String>(json, r'personId')!,
        amountCents: mapValueOfType<int>(json, r'amountCents')!,
        direction: SettlementDirection.fromJson(json[r'direction'])!,
        date: mapValueOfType<String>(json, r'date')!,
        notes: mapValueOfType<String>(json, r'notes')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<Settlement> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Settlement>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Settlement.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Settlement> mapFromJson(dynamic json) {
    final map = <String, Settlement>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Settlement.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Settlement-objects as value to a dart map
  static Map<String, List<Settlement>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Settlement>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Settlement.listFromJson(
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
    'personId',
    'amountCents',
    'direction',
    'date',
    'notes',
    'createdAt',
  };
}
