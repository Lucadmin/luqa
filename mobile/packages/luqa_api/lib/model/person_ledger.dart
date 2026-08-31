//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PersonLedger {
  /// Returns a new [PersonLedger] instance.
  PersonLedger({
    required this.person,
    required this.currency,
    required this.balanceCents,
    required this.coveredCents,
    required this.coveredThisYearCents,
    this.items = const [],
  });

  final Person person;

  final String currency;

  final int balanceCents;

  final int coveredCents;

  final int coveredThisYearCents;

  final List<LedgerItem> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonLedger &&
          other.person == person &&
          other.currency == currency &&
          other.balanceCents == balanceCents &&
          other.coveredCents == coveredCents &&
          other.coveredThisYearCents == coveredThisYearCents &&
          _deepEquality.equals(other.items, items);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (person.hashCode) +
      (currency.hashCode) +
      (balanceCents.hashCode) +
      (coveredCents.hashCode) +
      (coveredThisYearCents.hashCode) +
      (items.hashCode);

  @override
  String toString() =>
      'PersonLedger[person=$person, currency=$currency, balanceCents=$balanceCents, coveredCents=$coveredCents, coveredThisYearCents=$coveredThisYearCents, items=$items]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'person'] = this.person;
    json[r'currency'] = this.currency;
    json[r'balanceCents'] = this.balanceCents;
    json[r'coveredCents'] = this.coveredCents;
    json[r'coveredThisYearCents'] = this.coveredThisYearCents;
    json[r'items'] = this.items;
    return json;
  }

  /// Clones this instance of [PersonLedger] and returns a new one where some of the
  /// properties have changed.
  PersonLedger copyWith({
    Person? person,
    String? currency,
    int? balanceCents,
    int? coveredCents,
    int? coveredThisYearCents,
    List<LedgerItem>? items,
  }) =>
      PersonLedger(
        person: person ?? this.person,
        currency: currency ?? this.currency,
        balanceCents: balanceCents ?? this.balanceCents,
        coveredCents: coveredCents ?? this.coveredCents,
        coveredThisYearCents: coveredThisYearCents ?? this.coveredThisYearCents,
        items: items ?? this.items,
      );

  /// Returns a new [PersonLedger] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PersonLedger? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'person'),
            'Required key "PersonLedger[person]" is missing from JSON.');
        assert(json[r'person'] != null,
            'Required key "PersonLedger[person]" has a null value in JSON.');
        assert(json.containsKey(r'currency'),
            'Required key "PersonLedger[currency]" is missing from JSON.');
        assert(json[r'currency'] != null,
            'Required key "PersonLedger[currency]" has a null value in JSON.');
        assert(json.containsKey(r'balanceCents'),
            'Required key "PersonLedger[balanceCents]" is missing from JSON.');
        assert(json[r'balanceCents'] != null,
            'Required key "PersonLedger[balanceCents]" has a null value in JSON.');
        assert(json.containsKey(r'coveredCents'),
            'Required key "PersonLedger[coveredCents]" is missing from JSON.');
        assert(json[r'coveredCents'] != null,
            'Required key "PersonLedger[coveredCents]" has a null value in JSON.');
        assert(json.containsKey(r'coveredThisYearCents'),
            'Required key "PersonLedger[coveredThisYearCents]" is missing from JSON.');
        assert(json[r'coveredThisYearCents'] != null,
            'Required key "PersonLedger[coveredThisYearCents]" has a null value in JSON.');
        assert(json.containsKey(r'items'),
            'Required key "PersonLedger[items]" is missing from JSON.');
        assert(json[r'items'] != null,
            'Required key "PersonLedger[items]" has a null value in JSON.');
        return true;
      }());

      return PersonLedger(
        person: Person.fromJson(json[r'person'])!,
        currency: mapValueOfType<String>(json, r'currency')!,
        balanceCents: mapValueOfType<int>(json, r'balanceCents')!,
        coveredCents: mapValueOfType<int>(json, r'coveredCents')!,
        coveredThisYearCents:
            mapValueOfType<int>(json, r'coveredThisYearCents')!,
        items: LedgerItem.listFromJson(json[r'items']),
      );
    }
    return null;
  }

  static List<PersonLedger> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PersonLedger>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PersonLedger.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PersonLedger> mapFromJson(dynamic json) {
    final map = <String, PersonLedger>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PersonLedger.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PersonLedger-objects as value to a dart map
  static Map<String, List<PersonLedger>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PersonLedger>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PersonLedger.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'person',
    'currency',
    'balanceCents',
    'coveredCents',
    'coveredThisYearCents',
    'items',
  };
}
