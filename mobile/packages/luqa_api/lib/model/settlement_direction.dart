//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// Which way the money moved when a debt was paid off.
enum SettlementDirection {
  TO_ME._(r'TO_ME'),
  FROM_ME._(r'FROM_ME'),
  unknownDefaultOpenApi._(r'unknown_default_open_api'),
  ;

  /// Instantiate a new enum with the provided value.
  const SettlementDirection._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SettlementDirection] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SettlementDirection? fromJson(dynamic value) =>
      SettlementDirectionTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SettlementDirection]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SettlementDirection> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SettlementDirection>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SettlementDirection.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SettlementDirection] to String,
/// and [decode] dynamic data back to [SettlementDirection].
class SettlementDirectionTypeTransformer {
  factory SettlementDirectionTypeTransformer() =>
      _instance ??= const SettlementDirectionTypeTransformer._();

  const SettlementDirectionTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(SettlementDirection data) => data._value;

  /// Returns the instance of [SettlementDirection] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SettlementDirection? decode(dynamic data, {bool allowNull = true}) {
    if (data is SettlementDirection) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'TO_ME':
          return SettlementDirection.TO_ME;
        case r'FROM_ME':
          return SettlementDirection.FROM_ME;
        case r'unknown_default_open_api':
          return SettlementDirection.unknownDefaultOpenApi;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SettlementDirectionTypeTransformer? _instance;
}
