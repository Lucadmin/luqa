//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

enum HealthMetricType {
  STEPS._(r'STEPS'),
  DISTANCE_METERS._(r'DISTANCE_METERS'),
  ACTIVE_ENERGY_KCAL._(r'ACTIVE_ENERGY_KCAL'),
  TOTAL_ENERGY_KCAL._(r'TOTAL_ENERGY_KCAL'),
  EXERCISE_MINUTES._(r'EXERCISE_MINUTES'),
  HEART_RATE_BPM._(r'HEART_RATE_BPM'),
  RESTING_HEART_RATE_BPM._(r'RESTING_HEART_RATE_BPM'),
  HEART_RATE_VARIABILITY_MS._(r'HEART_RATE_VARIABILITY_MS'),
  RESPIRATORY_RATE_BPM._(r'RESPIRATORY_RATE_BPM'),
  BLOOD_OXYGEN_PERCENT._(r'BLOOD_OXYGEN_PERCENT'),
  BODY_TEMPERATURE_C._(r'BODY_TEMPERATURE_C'),
  WEIGHT_KG._(r'WEIGHT_KG'),
  BODY_FAT_PERCENT._(r'BODY_FAT_PERCENT'),
  VO2_MAX._(r'VO2_MAX'),
  unknownDefaultOpenApi._(r'unknown_default_open_api'),
  ;

  /// Instantiate a new enum with the provided value.
  const HealthMetricType._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [HealthMetricType] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static HealthMetricType? fromJson(dynamic value) =>
      HealthMetricTypeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [HealthMetricType]
  /// that were successfully decoded from the passed [JSON][json].
  static List<HealthMetricType> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HealthMetricType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HealthMetricType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [HealthMetricType] to String,
/// and [decode] dynamic data back to [HealthMetricType].
class HealthMetricTypeTypeTransformer {
  factory HealthMetricTypeTypeTransformer() =>
      _instance ??= const HealthMetricTypeTypeTransformer._();

  const HealthMetricTypeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(HealthMetricType data) => data._value;

  /// Returns the instance of [HealthMetricType] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  HealthMetricType? decode(dynamic data, {bool allowNull = true}) {
    if (data is HealthMetricType) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'STEPS':
          return HealthMetricType.STEPS;
        case r'DISTANCE_METERS':
          return HealthMetricType.DISTANCE_METERS;
        case r'ACTIVE_ENERGY_KCAL':
          return HealthMetricType.ACTIVE_ENERGY_KCAL;
        case r'TOTAL_ENERGY_KCAL':
          return HealthMetricType.TOTAL_ENERGY_KCAL;
        case r'EXERCISE_MINUTES':
          return HealthMetricType.EXERCISE_MINUTES;
        case r'HEART_RATE_BPM':
          return HealthMetricType.HEART_RATE_BPM;
        case r'RESTING_HEART_RATE_BPM':
          return HealthMetricType.RESTING_HEART_RATE_BPM;
        case r'HEART_RATE_VARIABILITY_MS':
          return HealthMetricType.HEART_RATE_VARIABILITY_MS;
        case r'RESPIRATORY_RATE_BPM':
          return HealthMetricType.RESPIRATORY_RATE_BPM;
        case r'BLOOD_OXYGEN_PERCENT':
          return HealthMetricType.BLOOD_OXYGEN_PERCENT;
        case r'BODY_TEMPERATURE_C':
          return HealthMetricType.BODY_TEMPERATURE_C;
        case r'WEIGHT_KG':
          return HealthMetricType.WEIGHT_KG;
        case r'BODY_FAT_PERCENT':
          return HealthMetricType.BODY_FAT_PERCENT;
        case r'VO2_MAX':
          return HealthMetricType.VO2_MAX;
        case r'unknown_default_open_api':
          return HealthMetricType.unknownDefaultOpenApi;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static HealthMetricTypeTypeTransformer? _instance;
}
