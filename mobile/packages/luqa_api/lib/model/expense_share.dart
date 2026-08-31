//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ExpenseShare {
  /// Returns a new [ExpenseShare] instance.
  ExpenseShare({
    required this.personId,
    required this.amountCents,
    required this.percentBp,
    required this.gifted,
  });

  final String personId;

  final int amountCents;

  /// This slice as basis points of the bill; 10000 is 100%.
  final int? percentBp;

  /// Covered as a treat. Still totalled against the person, never a debt.
  final bool gifted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseShare &&
          other.personId == personId &&
          other.amountCents == amountCents &&
          other.percentBp == percentBp &&
          other.gifted == gifted;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (personId.hashCode) +
      (amountCents.hashCode) +
      (percentBp == null ? 0 : percentBp!.hashCode) +
      (gifted.hashCode);

  @override
  String toString() =>
      'ExpenseShare[personId=$personId, amountCents=$amountCents, percentBp=$percentBp, gifted=$gifted]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'personId'] = this.personId;
    json[r'amountCents'] = this.amountCents;
    if (this.percentBp != null) {
      json[r'percentBp'] = this.percentBp;
    } else {
      json[r'percentBp'] = null;
    }
    json[r'gifted'] = this.gifted;
    return json;
  }

  /// Clones this instance of [ExpenseShare] and returns a new one where some of the
  /// properties have changed.
  ExpenseShare copyWith({
    String? personId,
    int? amountCents,
    int? percentBp,
    bool percentBpSetToNull = false,
    bool? gifted,
  }) =>
      ExpenseShare(
        personId: personId ?? this.personId,
        amountCents: amountCents ?? this.amountCents,
        percentBp: percentBpSetToNull ? null : percentBp ?? this.percentBp,
        gifted: gifted ?? this.gifted,
      );

  /// Returns a new [ExpenseShare] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ExpenseShare? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'personId'),
            'Required key "ExpenseShare[personId]" is missing from JSON.');
        assert(json[r'personId'] != null,
            'Required key "ExpenseShare[personId]" has a null value in JSON.');
        assert(json.containsKey(r'amountCents'),
            'Required key "ExpenseShare[amountCents]" is missing from JSON.');
        assert(json[r'amountCents'] != null,
            'Required key "ExpenseShare[amountCents]" has a null value in JSON.');
        assert(json.containsKey(r'percentBp'),
            'Required key "ExpenseShare[percentBp]" is missing from JSON.');
        assert(json.containsKey(r'gifted'),
            'Required key "ExpenseShare[gifted]" is missing from JSON.');
        assert(json[r'gifted'] != null,
            'Required key "ExpenseShare[gifted]" has a null value in JSON.');
        return true;
      }());

      return ExpenseShare(
        personId: mapValueOfType<String>(json, r'personId')!,
        amountCents: mapValueOfType<int>(json, r'amountCents')!,
        percentBp: mapValueOfType<int>(json, r'percentBp'),
        gifted: mapValueOfType<bool>(json, r'gifted')!,
      );
    }
    return null;
  }

  static List<ExpenseShare> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ExpenseShare>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ExpenseShare.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ExpenseShare> mapFromJson(dynamic json) {
    final map = <String, ExpenseShare>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ExpenseShare.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ExpenseShare-objects as value to a dart map
  static Map<String, List<ExpenseShare>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ExpenseShare>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ExpenseShare.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'personId',
    'amountCents',
    'percentBp',
    'gifted',
  };
}
