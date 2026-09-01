//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// Whether a TIME target is a daily quota or a running total for the week or month.
enum HabitGoalPeriod {
  DAY._(r'DAY'),
  WEEK._(r'WEEK'),
  MONTH._(r'MONTH'),
  unknownDefaultOpenApi._(r'unknown_default_open_api'),
  ;

  /// Instantiate a new enum with the provided value.
  const HabitGoalPeriod._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [HabitGoalPeriod] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static HabitGoalPeriod? fromJson(dynamic value) =>
      HabitGoalPeriodTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [HabitGoalPeriod]
  /// that were successfully decoded from the passed [JSON][json].
  static List<HabitGoalPeriod> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HabitGoalPeriod>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HabitGoalPeriod.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [HabitGoalPeriod] to String,
/// and [decode] dynamic data back to [HabitGoalPeriod].
class HabitGoalPeriodTypeTransformer {
  factory HabitGoalPeriodTypeTransformer() =>
      _instance ??= const HabitGoalPeriodTypeTransformer._();

  const HabitGoalPeriodTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(HabitGoalPeriod data) => data._value;

  /// Returns the instance of [HabitGoalPeriod] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  HabitGoalPeriod? decode(dynamic data, {bool allowNull = true}) {
    if (data is HabitGoalPeriod) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'DAY':
          return HabitGoalPeriod.DAY;
        case r'WEEK':
          return HabitGoalPeriod.WEEK;
        case r'MONTH':
          return HabitGoalPeriod.MONTH;
        case r'unknown_default_open_api':
          return HabitGoalPeriod.unknownDefaultOpenApi;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static HabitGoalPeriodTypeTransformer? _instance;
}
