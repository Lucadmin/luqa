//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// How the per-person shares were arrived at. Stored so reopening a bill shows the editor state it was saved with.
enum SplitMode {
  EQUAL._(r'EQUAL'),
  PERCENT._(r'PERCENT'),
  AMOUNT._(r'AMOUNT'),
  unknownDefaultOpenApi._(r'unknown_default_open_api'),
  ;

  /// Instantiate a new enum with the provided value.
  const SplitMode._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SplitMode] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SplitMode? fromJson(dynamic value) =>
      SplitModeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SplitMode]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SplitMode> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SplitMode>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SplitMode.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SplitMode] to String,
/// and [decode] dynamic data back to [SplitMode].
class SplitModeTypeTransformer {
  factory SplitModeTypeTransformer() =>
      _instance ??= const SplitModeTypeTransformer._();

  const SplitModeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(SplitMode data) => data._value;

  /// Returns the instance of [SplitMode] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SplitMode? decode(dynamic data, {bool allowNull = true}) {
    if (data is SplitMode) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'EQUAL':
          return SplitMode.EQUAL;
        case r'PERCENT':
          return SplitMode.PERCENT;
        case r'AMOUNT':
          return SplitMode.AMOUNT;
        case r'unknown_default_open_api':
          return SplitMode.unknownDefaultOpenApi;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SplitModeTypeTransformer? _instance;
}
