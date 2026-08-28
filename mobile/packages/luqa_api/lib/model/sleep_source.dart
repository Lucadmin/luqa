//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

enum SleepSource {
  HEALTH_CONNECT._(r'HEALTH_CONNECT'),
  APPLE_HEALTH._(r'APPLE_HEALTH'),
  GOOGLE_HEALTH._(r'GOOGLE_HEALTH'),
  MANUAL._(r'MANUAL'),
  unknownDefaultOpenApi._(r'unknown_default_open_api'),
  ;

  /// Instantiate a new enum with the provided value.
  const SleepSource._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SleepSource] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SleepSource? fromJson(dynamic value) =>
      SleepSourceTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SleepSource]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SleepSource> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SleepSource>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SleepSource.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SleepSource] to String,
/// and [decode] dynamic data back to [SleepSource].
class SleepSourceTypeTransformer {
  factory SleepSourceTypeTransformer() =>
      _instance ??= const SleepSourceTypeTransformer._();

  const SleepSourceTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(SleepSource data) => data._value;

  /// Returns the instance of [SleepSource] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SleepSource? decode(dynamic data, {bool allowNull = true}) {
    if (data is SleepSource) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'HEALTH_CONNECT':
          return SleepSource.HEALTH_CONNECT;
        case r'APPLE_HEALTH':
          return SleepSource.APPLE_HEALTH;
        case r'GOOGLE_HEALTH':
          return SleepSource.GOOGLE_HEALTH;
        case r'MANUAL':
          return SleepSource.MANUAL;
        case r'unknown_default_open_api':
          return SleepSource.unknownDefaultOpenApi;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SleepSourceTypeTransformer? _instance;
}
