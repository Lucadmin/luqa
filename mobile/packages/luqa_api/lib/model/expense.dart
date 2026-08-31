//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Expense {
  /// Returns a new [Expense] instance.
  Expense({
    required this.id,
    required this.description,
    required this.amountCents,
    required this.date,
    required this.paidByPersonId,
    required this.groupId,
    required this.splitMode,
    required this.myShareCents,
    required this.notes,
    this.shares = const [],
    required this.createdAt,
  });

  final String id;

  final String description;

  final int amountCents;

  final String date;

  /// Who fronted the money. Null means the user did. When someone else paid, only the user's own share moves a balance.
  final String? paidByPersonId;

  final String? groupId;

  final SplitMode splitMode;

  /// The user's own slice. Shares plus this equals the bill.
  final int myShareCents;

  final String notes;

  final List<ExpenseShare> shares;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          other.id == id &&
          other.description == description &&
          other.amountCents == amountCents &&
          other.date == date &&
          other.paidByPersonId == paidByPersonId &&
          other.groupId == groupId &&
          other.splitMode == splitMode &&
          other.myShareCents == myShareCents &&
          other.notes == notes &&
          _deepEquality.equals(other.shares, shares) &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (description.hashCode) +
      (amountCents.hashCode) +
      (date.hashCode) +
      (paidByPersonId == null ? 0 : paidByPersonId!.hashCode) +
      (groupId == null ? 0 : groupId!.hashCode) +
      (splitMode.hashCode) +
      (myShareCents.hashCode) +
      (notes.hashCode) +
      (shares.hashCode) +
      (createdAt.hashCode);

  @override
  String toString() =>
      'Expense[id=$id, description=$description, amountCents=$amountCents, date=$date, paidByPersonId=$paidByPersonId, groupId=$groupId, splitMode=$splitMode, myShareCents=$myShareCents, notes=$notes, shares=$shares, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'description'] = this.description;
    json[r'amountCents'] = this.amountCents;
    json[r'date'] = this.date;
    if (this.paidByPersonId != null) {
      json[r'paidByPersonId'] = this.paidByPersonId;
    } else {
      json[r'paidByPersonId'] = null;
    }
    if (this.groupId != null) {
      json[r'groupId'] = this.groupId;
    } else {
      json[r'groupId'] = null;
    }
    json[r'splitMode'] = this.splitMode;
    json[r'myShareCents'] = this.myShareCents;
    json[r'notes'] = this.notes;
    json[r'shares'] = this.shares;
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [Expense] and returns a new one where some of the
  /// properties have changed.
  Expense copyWith({
    String? id,
    String? description,
    int? amountCents,
    String? date,
    String? paidByPersonId,
    bool paidByPersonIdSetToNull = false,
    String? groupId,
    bool groupIdSetToNull = false,
    SplitMode? splitMode,
    int? myShareCents,
    String? notes,
    List<ExpenseShare>? shares,
    DateTime? createdAt,
  }) =>
      Expense(
        id: id ?? this.id,
        description: description ?? this.description,
        amountCents: amountCents ?? this.amountCents,
        date: date ?? this.date,
        paidByPersonId: paidByPersonIdSetToNull
            ? null
            : paidByPersonId ?? this.paidByPersonId,
        groupId: groupIdSetToNull ? null : groupId ?? this.groupId,
        splitMode: splitMode ?? this.splitMode,
        myShareCents: myShareCents ?? this.myShareCents,
        notes: notes ?? this.notes,
        shares: shares ?? this.shares,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Returns a new [Expense] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Expense? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "Expense[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "Expense[id]" has a null value in JSON.');
        assert(json.containsKey(r'description'),
            'Required key "Expense[description]" is missing from JSON.');
        assert(json[r'description'] != null,
            'Required key "Expense[description]" has a null value in JSON.');
        assert(json.containsKey(r'amountCents'),
            'Required key "Expense[amountCents]" is missing from JSON.');
        assert(json[r'amountCents'] != null,
            'Required key "Expense[amountCents]" has a null value in JSON.');
        assert(json.containsKey(r'date'),
            'Required key "Expense[date]" is missing from JSON.');
        assert(json[r'date'] != null,
            'Required key "Expense[date]" has a null value in JSON.');
        assert(json.containsKey(r'paidByPersonId'),
            'Required key "Expense[paidByPersonId]" is missing from JSON.');
        assert(json.containsKey(r'groupId'),
            'Required key "Expense[groupId]" is missing from JSON.');
        assert(json.containsKey(r'splitMode'),
            'Required key "Expense[splitMode]" is missing from JSON.');
        assert(json[r'splitMode'] != null,
            'Required key "Expense[splitMode]" has a null value in JSON.');
        assert(json.containsKey(r'myShareCents'),
            'Required key "Expense[myShareCents]" is missing from JSON.');
        assert(json[r'myShareCents'] != null,
            'Required key "Expense[myShareCents]" has a null value in JSON.');
        assert(json.containsKey(r'notes'),
            'Required key "Expense[notes]" is missing from JSON.');
        assert(json[r'notes'] != null,
            'Required key "Expense[notes]" has a null value in JSON.');
        assert(json.containsKey(r'shares'),
            'Required key "Expense[shares]" is missing from JSON.');
        assert(json[r'shares'] != null,
            'Required key "Expense[shares]" has a null value in JSON.');
        assert(json.containsKey(r'createdAt'),
            'Required key "Expense[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null,
            'Required key "Expense[createdAt]" has a null value in JSON.');
        return true;
      }());

      return Expense(
        id: mapValueOfType<String>(json, r'id')!,
        description: mapValueOfType<String>(json, r'description')!,
        amountCents: mapValueOfType<int>(json, r'amountCents')!,
        date: mapValueOfType<String>(json, r'date')!,
        paidByPersonId: mapValueOfType<String>(json, r'paidByPersonId'),
        groupId: mapValueOfType<String>(json, r'groupId'),
        splitMode: SplitMode.fromJson(json[r'splitMode'])!,
        myShareCents: mapValueOfType<int>(json, r'myShareCents')!,
        notes: mapValueOfType<String>(json, r'notes')!,
        shares: ExpenseShare.listFromJson(json[r'shares']),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<Expense> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Expense>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Expense.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Expense> mapFromJson(dynamic json) {
    final map = <String, Expense>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Expense.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Expense-objects as value to a dart map
  static Map<String, List<Expense>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Expense>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Expense.listFromJson(
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
    'description',
    'amountCents',
    'date',
    'paidByPersonId',
    'groupId',
    'splitMode',
    'myShareCents',
    'notes',
    'shares',
    'createdAt',
  };
}
