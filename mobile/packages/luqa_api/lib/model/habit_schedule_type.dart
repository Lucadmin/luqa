//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// How a habit recurs. The TIMES_PER_* forms are active every day and track a quota across the period instead of naming particular days.
enum HabitScheduleType {
  DAILY._(r'DAILY'),
  WEEKDAYS._(r'WEEKDAYS'),
  INTERVAL._(r'INTERVAL'),
  TIMES_PER_WEEK._(r'TIMES_PER_WEEK'),
  TIMES_PER_MONTH._(r'TIMES_PER_MONTH'),
  TIMES_PER_YEAR._(r'TIMES_PER_YEAR'),
  DATES._(r'DATES'),
  unknownDefaultOpenApi._(r'unknown_default_open_api'),
  ;

  /// Instantiate a new enum with the provided value.
  const HabitScheduleType._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [HabitScheduleType] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static HabitScheduleType? fromJson(dynamic value) =>
      HabitScheduleTypeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [HabitScheduleType]
  /// that were successfully decoded from the passed [JSON][json].
  static List<HabitScheduleType> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HabitScheduleType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HabitScheduleType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [HabitScheduleType] to String,
/// and [decode] dynamic data back to [HabitScheduleType].
class HabitScheduleTypeTypeTransformer {
  factory HabitScheduleTypeTypeTransformer() =>
      _instance ??= const HabitScheduleTypeTypeTransformer._();

  const HabitScheduleTypeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(HabitScheduleType data) => data._value;

  /// Returns the instance of [HabitScheduleType] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  HabitScheduleType? decode(dynamic data, {bool allowNull = true}) {
    if (data is HabitScheduleType) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'DAILY':
          return HabitScheduleType.DAILY;
        case r'WEEKDAYS':
          return HabitScheduleType.WEEKDAYS;
        case r'INTERVAL':
          return HabitScheduleType.INTERVAL;
        case r'TIMES_PER_WEEK':
          return HabitScheduleType.TIMES_PER_WEEK;
        case r'TIMES_PER_MONTH':
          return HabitScheduleType.TIMES_PER_MONTH;
        case r'TIMES_PER_YEAR':
          return HabitScheduleType.TIMES_PER_YEAR;
        case r'DATES':
          return HabitScheduleType.DATES;
        case r'unknown_default_open_api':
          return HabitScheduleType.unknownDefaultOpenApi;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static HabitScheduleTypeTypeTransformer? _instance;
}
