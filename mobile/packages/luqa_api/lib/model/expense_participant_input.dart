//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ExpenseParticipantInput {
  /// Returns a new [ExpenseParticipantInput] instance.
  ExpenseParticipantInput({
    required this.personId,
    this.percentBp = const Optional.absent(),
    this.amountCents = const Optional.absent(),
    this.gifted = const Optional.absent(),
  });

  final String personId;

  /// PERCENT mode: this person's cut, in basis points.
  ///
  /// Minimum value: 0
  /// Maximum value: 10000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> percentBp;

  /// AMOUNT mode: the exact cents this person carries.
  ///
  /// Minimum value: 0
  /// Maximum value: 100000000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> amountCents;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> gifted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseParticipantInput &&
          other.personId == personId &&
          other.percentBp == percentBp &&
          other.amountCents == amountCents &&
          other.gifted == gifted;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (personId.hashCode) +
      (percentBp == null ? 0 : percentBp!.hashCode) +
      (amountCents == null ? 0 : amountCents!.hashCode) +
      (gifted == null ? 0 : gifted!.hashCode);

  @override
  String toString() =>
      'ExpenseParticipantInput[personId=$personId, percentBp=$percentBp, amountCents=$amountCents, gifted=$gifted]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'personId'] = this.personId;
    if (this.percentBp.isPresent) {
      final value = this.percentBp.value;
      json[r'percentBp'] = value;
    }
    if (this.amountCents.isPresent) {
      final value = this.amountCents.value;
      json[r'amountCents'] = value;
    }
    if (this.gifted.isPresent) {
      final value = this.gifted.value;
      json[r'gifted'] = value;
    }
    return json;
  }

  /// Clones this instance of [ExpenseParticipantInput] and returns a new one where some of the
  /// properties have changed.
  ExpenseParticipantInput copyWith({
    String? personId,
    Optional<int?>? percentBp,
    Optional<int?>? amountCents,
    Optional<bool?>? gifted,
  }) =>
      ExpenseParticipantInput(
        personId: personId ?? this.personId,
        percentBp: percentBp ?? this.percentBp,
        amountCents: amountCents ?? this.amountCents,
        gifted: gifted ?? this.gifted,
      );

  /// Returns a new [ExpenseParticipantInput] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ExpenseParticipantInput? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'personId'),
            'Required key "ExpenseParticipantInput[personId]" is missing from JSON.');
        assert(json[r'personId'] != null,
            'Required key "ExpenseParticipantInput[personId]" has a null value in JSON.');
        return true;
      }());

      return ExpenseParticipantInput(
        personId: mapValueOfType<String>(json, r'personId')!,
        percentBp: json.containsKey(r'percentBp')
            ? Optional.present(json[r'percentBp'] == null
                ? null
                : int.parse('${json[r'percentBp']}'))
            : const Optional.absent(),
        amountCents: json.containsKey(r'amountCents')
            ? Optional.present(json[r'amountCents'] == null
                ? null
                : int.parse('${json[r'amountCents']}'))
            : const Optional.absent(),
        gifted: json.containsKey(r'gifted')
            ? Optional.present(mapValueOfType<bool>(json, r'gifted'))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<ExpenseParticipantInput> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ExpenseParticipantInput>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ExpenseParticipantInput.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ExpenseParticipantInput> mapFromJson(dynamic json) {
    final map = <String, ExpenseParticipantInput>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ExpenseParticipantInput.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ExpenseParticipantInput-objects as value to a dart map
  static Map<String, List<ExpenseParticipantInput>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ExpenseParticipantInput>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ExpenseParticipantInput.listFromJson(
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
  };
}
