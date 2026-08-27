//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// Platform store the device read. Server-pull sources are not accepted here.
enum DeviceHealthSource {
  HEALTH_CONNECT._(r'HEALTH_CONNECT'),
  APPLE_HEALTH._(r'APPLE_HEALTH'),
  unknownDefaultOpenApi._(r'unknown_default_open_api'),
  ;

  /// Instantiate a new enum with the provided value.
  const DeviceHealthSource._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [DeviceHealthSource] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static DeviceHealthSource? fromJson(dynamic value) =>
      DeviceHealthSourceTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [DeviceHealthSource]
  /// that were successfully decoded from the passed [JSON][json].
  static List<DeviceHealthSource> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <DeviceHealthSource>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DeviceHealthSource.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DeviceHealthSource] to String,
/// and [decode] dynamic data back to [DeviceHealthSource].
class DeviceHealthSourceTypeTransformer {
  factory DeviceHealthSourceTypeTransformer() =>
      _instance ??= const DeviceHealthSourceTypeTransformer._();

  const DeviceHealthSourceTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(DeviceHealthSource data) => data._value;

  /// Returns the instance of [DeviceHealthSource] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DeviceHealthSource? decode(dynamic data, {bool allowNull = true}) {
    if (data is DeviceHealthSource) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'HEALTH_CONNECT':
          return DeviceHealthSource.HEALTH_CONNECT;
        case r'APPLE_HEALTH':
          return DeviceHealthSource.APPLE_HEALTH;
        case r'unknown_default_open_api':
          return DeviceHealthSource.unknownDefaultOpenApi;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static DeviceHealthSourceTypeTransformer? _instance;
}
