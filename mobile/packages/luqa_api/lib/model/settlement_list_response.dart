//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SettlementListResponse {
  /// Returns a new [SettlementListResponse] instance.
  SettlementListResponse({
    this.settlements = const [],
  });

  final List<Settlement> settlements;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettlementListResponse &&
          _deepEquality.equals(other.settlements, settlements);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (settlements.hashCode);

  @override
  String toString() => 'SettlementListResponse[settlements=$settlements]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'settlements'] = this.settlements;
    return json;
  }

  /// Clones this instance of [SettlementListResponse] and returns a new one where some of the
  /// properties have changed.
  SettlementListResponse copyWith({
    List<Settlement>? settlements,
  }) =>
      SettlementListResponse(
        settlements: settlements ?? this.settlements,
      );

  /// Returns a new [SettlementListResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SettlementListResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'settlements'),
            'Required key "SettlementListResponse[settlements]" is missing from JSON.');
        assert(json[r'settlements'] != null,
            'Required key "SettlementListResponse[settlements]" has a null value in JSON.');
        return true;
      }());

      return SettlementListResponse(
        settlements: Settlement.listFromJson(json[r'settlements']),
      );
    }
    return null;
  }

  static List<SettlementListResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SettlementListResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SettlementListResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SettlementListResponse> mapFromJson(dynamic json) {
    final map = <String, SettlementListResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SettlementListResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SettlementListResponse-objects as value to a dart map
  static Map<String, List<SettlementListResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SettlementListResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SettlementListResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'settlements',
  };
}
