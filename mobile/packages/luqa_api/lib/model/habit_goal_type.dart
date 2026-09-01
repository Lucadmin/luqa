//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// What \"done\" means for one day. TASK is done or not; COUNT reaches a number of reps; TIME accumulates a duration.
enum HabitGoalType {
  TASK._(r'TASK'),
  COUNT._(r'COUNT'),
  TIME._(r'TIME'),
  unknownDefaultOpenApi._(r'unknown_default_open_api'),
  ;

  /// Instantiate a new enum with the provided value.
  const HabitGoalType._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [HabitGoalType] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static HabitGoalType? fromJson(dynamic value) =>
      HabitGoalTypeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [HabitGoalType]
  /// that were successfully decoded from the passed [JSON][json].
  static List<HabitGoalType> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HabitGoalType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HabitGoalType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [HabitGoalType] to String,
/// and [decode] dynamic data back to [HabitGoalType].
class HabitGoalTypeTypeTransformer {
  factory HabitGoalTypeTypeTransformer() =>
      _instance ??= const HabitGoalTypeTypeTransformer._();

  const HabitGoalTypeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(HabitGoalType data) => data._value;

  /// Returns the instance of [HabitGoalType] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  HabitGoalType? decode(dynamic data, {bool allowNull = true}) {
    if (data is HabitGoalType) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'TASK':
          return HabitGoalType.TASK;
        case r'COUNT':
          return HabitGoalType.COUNT;
        case r'TIME':
          return HabitGoalType.TIME;
        case r'unknown_default_open_api':
          return HabitGoalType.unknownDefaultOpenApi;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static HabitGoalTypeTypeTransformer? _instance;
}
