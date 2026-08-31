//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ExpenseResponse {
  /// Returns a new [ExpenseResponse] instance.
  ExpenseResponse({
    required this.expense,
  });

  final Expense expense;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseResponse && other.expense == expense;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (expense.hashCode);

  @override
  String toString() => 'ExpenseResponse[expense=$expense]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'expense'] = this.expense;
    return json;
  }

  /// Clones this instance of [ExpenseResponse] and returns a new one where some of the
  /// properties have changed.
  ExpenseResponse copyWith({
    Expense? expense,
  }) =>
      ExpenseResponse(
        expense: expense ?? this.expense,
      );

  /// Returns a new [ExpenseResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ExpenseResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'expense'),
            'Required key "ExpenseResponse[expense]" is missing from JSON.');
        assert(json[r'expense'] != null,
            'Required key "ExpenseResponse[expense]" has a null value in JSON.');
        return true;
      }());

      return ExpenseResponse(
        expense: Expense.fromJson(json[r'expense'])!,
      );
    }
    return null;
  }

  static List<ExpenseResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ExpenseResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ExpenseResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ExpenseResponse> mapFromJson(dynamic json) {
    final map = <String, ExpenseResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ExpenseResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ExpenseResponse-objects as value to a dart map
  static Map<String, List<ExpenseResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ExpenseResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ExpenseResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'expense',
  };
}
