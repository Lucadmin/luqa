//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ExpenseListResponse {
  /// Returns a new [ExpenseListResponse] instance.
  ExpenseListResponse({
    this.expenses = const [],
    required this.nextCursor,
  });

  final List<Expense> expenses;

  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseListResponse &&
          _deepEquality.equals(other.expenses, expenses) &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (expenses.hashCode) + (nextCursor == null ? 0 : nextCursor!.hashCode);

  @override
  String toString() =>
      'ExpenseListResponse[expenses=$expenses, nextCursor=$nextCursor]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'expenses'] = this.expenses;
    if (this.nextCursor != null) {
      json[r'nextCursor'] = this.nextCursor;
    } else {
      json[r'nextCursor'] = null;
    }
    return json;
  }

  /// Clones this instance of [ExpenseListResponse] and returns a new one where some of the
  /// properties have changed.
  ExpenseListResponse copyWith({
    List<Expense>? expenses,
    String? nextCursor,
    bool nextCursorSetToNull = false,
  }) =>
      ExpenseListResponse(
        expenses: expenses ?? this.expenses,
        nextCursor: nextCursorSetToNull ? null : nextCursor ?? this.nextCursor,
      );

  /// Returns a new [ExpenseListResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ExpenseListResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'expenses'),
            'Required key "ExpenseListResponse[expenses]" is missing from JSON.');
        assert(json[r'expenses'] != null,
            'Required key "ExpenseListResponse[expenses]" has a null value in JSON.');
        assert(json.containsKey(r'nextCursor'),
            'Required key "ExpenseListResponse[nextCursor]" is missing from JSON.');
        return true;
      }());

      return ExpenseListResponse(
        expenses: Expense.listFromJson(json[r'expenses']),
        nextCursor: mapValueOfType<String>(json, r'nextCursor'),
      );
    }
    return null;
  }

  static List<ExpenseListResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ExpenseListResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ExpenseListResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ExpenseListResponse> mapFromJson(dynamic json) {
    final map = <String, ExpenseListResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ExpenseListResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ExpenseListResponse-objects as value to a dart map
  static Map<String, List<ExpenseListResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ExpenseListResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ExpenseListResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'expenses',
    'nextCursor',
  };
}
