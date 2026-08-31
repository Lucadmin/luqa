//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MoneyOverview {
  /// Returns a new [MoneyOverview] instance.
  MoneyOverview({
    required this.currency,
    this.people = const [],
    this.groups = const [],
    required this.owedToYouCents,
    required this.youOweCents,
    required this.netCents,
    required this.coveredCents,
  });

  final String currency;

  /// Biggest outstanding balance first; settled people sink to the bottom. Archived people are included — they may still carry a balance, and their names have to resolve on old bills.
  final List<PersonBalance> people;

  final List<PersonGroup> groups;

  final int owedToYouCents;

  /// Sum of the negative balances, as a positive number.
  final int youOweCents;

  final int netCents;

  final int coveredCents;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoneyOverview &&
          other.currency == currency &&
          _deepEquality.equals(other.people, people) &&
          _deepEquality.equals(other.groups, groups) &&
          other.owedToYouCents == owedToYouCents &&
          other.youOweCents == youOweCents &&
          other.netCents == netCents &&
          other.coveredCents == coveredCents;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (currency.hashCode) +
      (people.hashCode) +
      (groups.hashCode) +
      (owedToYouCents.hashCode) +
      (youOweCents.hashCode) +
      (netCents.hashCode) +
      (coveredCents.hashCode);

  @override
  String toString() =>
      'MoneyOverview[currency=$currency, people=$people, groups=$groups, owedToYouCents=$owedToYouCents, youOweCents=$youOweCents, netCents=$netCents, coveredCents=$coveredCents]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'currency'] = this.currency;
    json[r'people'] = this.people;
    json[r'groups'] = this.groups;
    json[r'owedToYouCents'] = this.owedToYouCents;
    json[r'youOweCents'] = this.youOweCents;
    json[r'netCents'] = this.netCents;
    json[r'coveredCents'] = this.coveredCents;
    return json;
  }

  /// Clones this instance of [MoneyOverview] and returns a new one where some of the
  /// properties have changed.
  MoneyOverview copyWith({
    String? currency,
    List<PersonBalance>? people,
    List<PersonGroup>? groups,
    int? owedToYouCents,
    int? youOweCents,
    int? netCents,
    int? coveredCents,
  }) =>
      MoneyOverview(
        currency: currency ?? this.currency,
        people: people ?? this.people,
        groups: groups ?? this.groups,
        owedToYouCents: owedToYouCents ?? this.owedToYouCents,
        youOweCents: youOweCents ?? this.youOweCents,
        netCents: netCents ?? this.netCents,
        coveredCents: coveredCents ?? this.coveredCents,
      );

  /// Returns a new [MoneyOverview] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MoneyOverview? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'currency'),
            'Required key "MoneyOverview[currency]" is missing from JSON.');
        assert(json[r'currency'] != null,
            'Required key "MoneyOverview[currency]" has a null value in JSON.');
        assert(json.containsKey(r'people'),
            'Required key "MoneyOverview[people]" is missing from JSON.');
        assert(json[r'people'] != null,
            'Required key "MoneyOverview[people]" has a null value in JSON.');
        assert(json.containsKey(r'groups'),
            'Required key "MoneyOverview[groups]" is missing from JSON.');
        assert(json[r'groups'] != null,
            'Required key "MoneyOverview[groups]" has a null value in JSON.');
        assert(json.containsKey(r'owedToYouCents'),
            'Required key "MoneyOverview[owedToYouCents]" is missing from JSON.');
        assert(json[r'owedToYouCents'] != null,
            'Required key "MoneyOverview[owedToYouCents]" has a null value in JSON.');
        assert(json.containsKey(r'youOweCents'),
            'Required key "MoneyOverview[youOweCents]" is missing from JSON.');
        assert(json[r'youOweCents'] != null,
            'Required key "MoneyOverview[youOweCents]" has a null value in JSON.');
        assert(json.containsKey(r'netCents'),
            'Required key "MoneyOverview[netCents]" is missing from JSON.');
        assert(json[r'netCents'] != null,
            'Required key "MoneyOverview[netCents]" has a null value in JSON.');
        assert(json.containsKey(r'coveredCents'),
            'Required key "MoneyOverview[coveredCents]" is missing from JSON.');
        assert(json[r'coveredCents'] != null,
            'Required key "MoneyOverview[coveredCents]" has a null value in JSON.');
        return true;
      }());

      return MoneyOverview(
        currency: mapValueOfType<String>(json, r'currency')!,
        people: PersonBalance.listFromJson(json[r'people']),
        groups: PersonGroup.listFromJson(json[r'groups']),
        owedToYouCents: mapValueOfType<int>(json, r'owedToYouCents')!,
        youOweCents: mapValueOfType<int>(json, r'youOweCents')!,
        netCents: mapValueOfType<int>(json, r'netCents')!,
        coveredCents: mapValueOfType<int>(json, r'coveredCents')!,
      );
    }
    return null;
  }

  static List<MoneyOverview> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MoneyOverview>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MoneyOverview.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MoneyOverview> mapFromJson(dynamic json) {
    final map = <String, MoneyOverview>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MoneyOverview.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MoneyOverview-objects as value to a dart map
  static Map<String, List<MoneyOverview>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MoneyOverview>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MoneyOverview.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'currency',
    'people',
    'groups',
    'owedToYouCents',
    'youOweCents',
    'netCents',
    'coveredCents',
  };
}
