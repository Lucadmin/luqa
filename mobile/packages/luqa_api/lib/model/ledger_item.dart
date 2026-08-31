//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LedgerItem {
  /// Returns a new [LedgerItem] instance.
  LedgerItem({
    required this.kind,
    required this.id,
    required this.date,
    required this.title,
    required this.deltaCents,
    required this.shareCents,
    required this.gifted,
    required this.amountCents,
    required this.paidByPersonId,
    required this.direction,
    required this.expense,
    required this.createdAt,
  });

  final LedgerItemKindEnum kind;

  final String id;

  final String date;

  final String title;

  /// Effect on the balance. Positive raises what they owe the user; a gift is zero.
  final int deltaCents;

  final int shareCents;

  final bool gifted;

  /// The whole bill, for context. Null on paybacks.
  final int? amountCents;

  final String? paidByPersonId;

  final SettlementDirection? direction;

  /// Full editor state for bill rows. Null on paybacks.
  final Expense? expense;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerItem &&
          other.kind == kind &&
          other.id == id &&
          other.date == date &&
          other.title == title &&
          other.deltaCents == deltaCents &&
          other.shareCents == shareCents &&
          other.gifted == gifted &&
          other.amountCents == amountCents &&
          other.paidByPersonId == paidByPersonId &&
          other.direction == direction &&
          other.expense == expense &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (kind.hashCode) +
      (id.hashCode) +
      (date.hashCode) +
      (title.hashCode) +
      (deltaCents.hashCode) +
      (shareCents.hashCode) +
      (gifted.hashCode) +
      (amountCents == null ? 0 : amountCents!.hashCode) +
      (paidByPersonId == null ? 0 : paidByPersonId!.hashCode) +
      (direction == null ? 0 : direction!.hashCode) +
      (expense == null ? 0 : expense!.hashCode) +
      (createdAt.hashCode);

  @override
  String toString() =>
      'LedgerItem[kind=$kind, id=$id, date=$date, title=$title, deltaCents=$deltaCents, shareCents=$shareCents, gifted=$gifted, amountCents=$amountCents, paidByPersonId=$paidByPersonId, direction=$direction, expense=$expense, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'kind'] = this.kind;
    json[r'id'] = this.id;
    json[r'date'] = this.date;
    json[r'title'] = this.title;
    json[r'deltaCents'] = this.deltaCents;
    json[r'shareCents'] = this.shareCents;
    json[r'gifted'] = this.gifted;
    if (this.amountCents != null) {
      json[r'amountCents'] = this.amountCents;
    } else {
      json[r'amountCents'] = null;
    }
    if (this.paidByPersonId != null) {
      json[r'paidByPersonId'] = this.paidByPersonId;
    } else {
      json[r'paidByPersonId'] = null;
    }
    if (this.direction != null) {
      json[r'direction'] = this.direction;
    } else {
      json[r'direction'] = null;
    }
    if (this.expense != null) {
      json[r'expense'] = this.expense;
    } else {
      json[r'expense'] = null;
    }
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Clones this instance of [LedgerItem] and returns a new one where some of the
  /// properties have changed.
  LedgerItem copyWith({
    LedgerItemKindEnum? kind,
    String? id,
    String? date,
    String? title,
    int? deltaCents,
    int? shareCents,
    bool? gifted,
    int? amountCents,
    bool amountCentsSetToNull = false,
    String? paidByPersonId,
    bool paidByPersonIdSetToNull = false,
    SettlementDirection? direction,
    bool directionSetToNull = false,
    Expense? expense,
    bool expenseSetToNull = false,
    DateTime? createdAt,
  }) =>
      LedgerItem(
        kind: kind ?? this.kind,
        id: id ?? this.id,
        date: date ?? this.date,
        title: title ?? this.title,
        deltaCents: deltaCents ?? this.deltaCents,
        shareCents: shareCents ?? this.shareCents,
        gifted: gifted ?? this.gifted,
        amountCents:
            amountCentsSetToNull ? null : amountCents ?? this.amountCents,
        paidByPersonId: paidByPersonIdSetToNull
            ? null
            : paidByPersonId ?? this.paidByPersonId,
        direction: directionSetToNull ? null : direction ?? this.direction,
        expense: expenseSetToNull ? null : expense ?? this.expense,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Returns a new [LedgerItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LedgerItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'kind'),
            'Required key "LedgerItem[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "LedgerItem[kind]" has a null value in JSON.');
        assert(json.containsKey(r'id'),
            'Required key "LedgerItem[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "LedgerItem[id]" has a null value in JSON.');
        assert(json.containsKey(r'date'),
            'Required key "LedgerItem[date]" is missing from JSON.');
        assert(json[r'date'] != null,
            'Required key "LedgerItem[date]" has a null value in JSON.');
        assert(json.containsKey(r'title'),
            'Required key "LedgerItem[title]" is missing from JSON.');
        assert(json[r'title'] != null,
            'Required key "LedgerItem[title]" has a null value in JSON.');
        assert(json.containsKey(r'deltaCents'),
            'Required key "LedgerItem[deltaCents]" is missing from JSON.');
        assert(json[r'deltaCents'] != null,
            'Required key "LedgerItem[deltaCents]" has a null value in JSON.');
        assert(json.containsKey(r'shareCents'),
            'Required key "LedgerItem[shareCents]" is missing from JSON.');
        assert(json[r'shareCents'] != null,
            'Required key "LedgerItem[shareCents]" has a null value in JSON.');
        assert(json.containsKey(r'gifted'),
            'Required key "LedgerItem[gifted]" is missing from JSON.');
        assert(json[r'gifted'] != null,
            'Required key "LedgerItem[gifted]" has a null value in JSON.');
        assert(json.containsKey(r'amountCents'),
            'Required key "LedgerItem[amountCents]" is missing from JSON.');
        assert(json.containsKey(r'paidByPersonId'),
            'Required key "LedgerItem[paidByPersonId]" is missing from JSON.');
        assert(json.containsKey(r'direction'),
            'Required key "LedgerItem[direction]" is missing from JSON.');
        assert(json.containsKey(r'expense'),
            'Required key "LedgerItem[expense]" is missing from JSON.');
        assert(json.containsKey(r'createdAt'),
            'Required key "LedgerItem[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null,
            'Required key "LedgerItem[createdAt]" has a null value in JSON.');
        return true;
      }());

      return LedgerItem(
        kind: LedgerItemKindEnum.fromJson(json[r'kind'])!,
        id: mapValueOfType<String>(json, r'id')!,
        date: mapValueOfType<String>(json, r'date')!,
        title: mapValueOfType<String>(json, r'title')!,
        deltaCents: mapValueOfType<int>(json, r'deltaCents')!,
        shareCents: mapValueOfType<int>(json, r'shareCents')!,
        gifted: mapValueOfType<bool>(json, r'gifted')!,
        amountCents: mapValueOfType<int>(json, r'amountCents'),
        paidByPersonId: mapValueOfType<String>(json, r'paidByPersonId'),
        direction: SettlementDirection.fromJson(json[r'direction']),
        expense: Expense.fromJson(json[r'expense']),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<LedgerItem> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <LedgerItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LedgerItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LedgerItem> mapFromJson(dynamic json) {
    final map = <String, LedgerItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LedgerItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LedgerItem-objects as value to a dart map
  static Map<String, List<LedgerItem>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<LedgerItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LedgerItem.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'kind',
    'id',
    'date',
    'title',
    'deltaCents',
    'shareCents',
    'gifted',
    'amountCents',
    'paidByPersonId',
    'direction',
    'expense',
    'createdAt',
  };
}

enum LedgerItemKindEnum {
  expense._(r'expense'),
  settlement._(r'settlement'),
  unknownDefaultOpenApi._(r'unknown_default_open_api'),
  ;

  /// Instantiate a new enum with the provided value.
  const LedgerItemKindEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [LedgerItemKindEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static LedgerItemKindEnum? fromJson(dynamic value) =>
      LedgerItemKindEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [LedgerItemKindEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<LedgerItemKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <LedgerItemKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LedgerItemKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LedgerItemKindEnum] to String,
/// and [decode] dynamic data back to [LedgerItemKindEnum].
class LedgerItemKindEnumTypeTransformer {
  factory LedgerItemKindEnumTypeTransformer() =>
      _instance ??= const LedgerItemKindEnumTypeTransformer._();

  const LedgerItemKindEnumTypeTransformer._();

  String encode(LedgerItemKindEnum data) => data._value;

  /// Returns the instance of [LedgerItemKindEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LedgerItemKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is LedgerItemKindEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'expense':
          return LedgerItemKindEnum.expense;
        case r'settlement':
          return LedgerItemKindEnum.settlement;
        case r'unknown_default_open_api':
          return LedgerItemKindEnum.unknownDefaultOpenApi;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static LedgerItemKindEnumTypeTransformer? _instance;
}
