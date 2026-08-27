//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HealthSyncState {
  /// Returns a new [HealthSyncState] instance.
  HealthSyncState({
    required this.source_,
    required this.metric,
    required this.lastSyncedAt,
    required this.lastEntryAt,
    required this.backfilledFrom,
  });

  final HealthSyncStateSource_Enum source_;

  /// SLEEP tracks the sleep-session domain.
  final HealthSyncStateMetricEnum metric;

  final DateTime? lastSyncedAt;

  final DateTime? lastEntryAt;

  final DateTime? backfilledFrom;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthSyncState &&
          other.source_ == source_ &&
          other.metric == metric &&
          other.lastSyncedAt == lastSyncedAt &&
          other.lastEntryAt == lastEntryAt &&
          other.backfilledFrom == backfilledFrom;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (source_.hashCode) +
      (metric.hashCode) +
      (lastSyncedAt == null ? 0 : lastSyncedAt!.hashCode) +
      (lastEntryAt == null ? 0 : lastEntryAt!.hashCode) +
      (backfilledFrom == null ? 0 : backfilledFrom!.hashCode);

  @override
  String toString() =>
      'HealthSyncState[source_=$source_, metric=$metric, lastSyncedAt=$lastSyncedAt, lastEntryAt=$lastEntryAt, backfilledFrom=$backfilledFrom]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'source'] = this.source_;
    json[r'metric'] = this.metric;
    if (this.lastSyncedAt != null) {
      json[r'lastSyncedAt'] = this.lastSyncedAt!.toUtc().toIso8601String();
    } else {
      json[r'lastSyncedAt'] = null;
    }
    if (this.lastEntryAt != null) {
      json[r'lastEntryAt'] = this.lastEntryAt!.toUtc().toIso8601String();
    } else {
      json[r'lastEntryAt'] = null;
    }
    if (this.backfilledFrom != null) {
      json[r'backfilledFrom'] = this.backfilledFrom!.toUtc().toIso8601String();
    } else {
      json[r'backfilledFrom'] = null;
    }
    return json;
  }

  /// Clones this instance of [HealthSyncState] and returns a new one where some of the
  /// properties have changed.
  HealthSyncState copyWith({
    HealthSyncStateSource_Enum? source_,
    HealthSyncStateMetricEnum? metric,
    DateTime? lastSyncedAt,
    bool lastSyncedAtSetToNull = false,
    DateTime? lastEntryAt,
    bool lastEntryAtSetToNull = false,
    DateTime? backfilledFrom,
    bool backfilledFromSetToNull = false,
  }) =>
      HealthSyncState(
        source_: source_ ?? this.source_,
        metric: metric ?? this.metric,
        lastSyncedAt:
            lastSyncedAtSetToNull ? null : lastSyncedAt ?? this.lastSyncedAt,
        lastEntryAt:
            lastEntryAtSetToNull ? null : lastEntryAt ?? this.lastEntryAt,
        backfilledFrom: backfilledFromSetToNull
            ? null
            : backfilledFrom ?? this.backfilledFrom,
      );

  /// Returns a new [HealthSyncState] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HealthSyncState? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'source'),
            'Required key "HealthSyncState[source]" is missing from JSON.');
        assert(json[r'source'] != null,
            'Required key "HealthSyncState[source]" has a null value in JSON.');
        assert(json.containsKey(r'metric'),
            'Required key "HealthSyncState[metric]" is missing from JSON.');
        assert(json[r'metric'] != null,
            'Required key "HealthSyncState[metric]" has a null value in JSON.');
        assert(json.containsKey(r'lastSyncedAt'),
            'Required key "HealthSyncState[lastSyncedAt]" is missing from JSON.');
        assert(json.containsKey(r'lastEntryAt'),
            'Required key "HealthSyncState[lastEntryAt]" is missing from JSON.');
        assert(json.containsKey(r'backfilledFrom'),
            'Required key "HealthSyncState[backfilledFrom]" is missing from JSON.');
        return true;
      }());

      return HealthSyncState(
        source_: HealthSyncStateSource_Enum.fromJson(json[r'source'])!,
        metric: HealthSyncStateMetricEnum.fromJson(json[r'metric'])!,
        lastSyncedAt: mapDateTime(json, r'lastSyncedAt', r''),
        lastEntryAt: mapDateTime(json, r'lastEntryAt', r''),
        backfilledFrom: mapDateTime(json, r'backfilledFrom', r''),
      );
    }
    return null;
  }

  static List<HealthSyncState> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HealthSyncState>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HealthSyncState.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HealthSyncState> mapFromJson(dynamic json) {
    final map = <String, HealthSyncState>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HealthSyncState.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HealthSyncState-objects as value to a dart map
  static Map<String, List<HealthSyncState>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<HealthSyncState>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HealthSyncState.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'source',
    'metric',
    'lastSyncedAt',
    'lastEntryAt',
    'backfilledFrom',
  };
}

enum HealthSyncStateSource_Enum {
  HEALTH_CONNECT._(r'HEALTH_CONNECT'),
  APPLE_HEALTH._(r'APPLE_HEALTH'),
  GOOGLE_HEALTH._(r'GOOGLE_HEALTH'),
  MANUAL._(r'MANUAL'),
  unknownDefaultOpenApi._(r'unknown_default_open_api'),
  ;

  /// Instantiate a new enum with the provided value.
  const HealthSyncStateSource_Enum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [HealthSyncStateSource_Enum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static HealthSyncStateSource_Enum? fromJson(dynamic value) =>
      HealthSyncStateSource_EnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [HealthSyncStateSource_Enum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<HealthSyncStateSource_Enum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HealthSyncStateSource_Enum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HealthSyncStateSource_Enum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [HealthSyncStateSource_Enum] to String,
/// and [decode] dynamic data back to [HealthSyncStateSource_Enum].
class HealthSyncStateSource_EnumTypeTransformer {
  factory HealthSyncStateSource_EnumTypeTransformer() =>
      _instance ??= const HealthSyncStateSource_EnumTypeTransformer._();

  const HealthSyncStateSource_EnumTypeTransformer._();

  String encode(HealthSyncStateSource_Enum data) => data._value;

  /// Returns the instance of [HealthSyncStateSource_Enum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  HealthSyncStateSource_Enum? decode(dynamic data, {bool allowNull = true}) {
    if (data is HealthSyncStateSource_Enum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'HEALTH_CONNECT':
          return HealthSyncStateSource_Enum.HEALTH_CONNECT;
        case r'APPLE_HEALTH':
          return HealthSyncStateSource_Enum.APPLE_HEALTH;
        case r'GOOGLE_HEALTH':
          return HealthSyncStateSource_Enum.GOOGLE_HEALTH;
        case r'MANUAL':
          return HealthSyncStateSource_Enum.MANUAL;
        case r'unknown_default_open_api':
          return HealthSyncStateSource_Enum.unknownDefaultOpenApi;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static HealthSyncStateSource_EnumTypeTransformer? _instance;
}

/// SLEEP tracks the sleep-session domain.
enum HealthSyncStateMetricEnum {
  SLEEP._(r'SLEEP'),
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
  const HealthSyncStateMetricEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [HealthSyncStateMetricEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static HealthSyncStateMetricEnum? fromJson(dynamic value) =>
      HealthSyncStateMetricEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [HealthSyncStateMetricEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<HealthSyncStateMetricEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HealthSyncStateMetricEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HealthSyncStateMetricEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [HealthSyncStateMetricEnum] to String,
/// and [decode] dynamic data back to [HealthSyncStateMetricEnum].
class HealthSyncStateMetricEnumTypeTransformer {
  factory HealthSyncStateMetricEnumTypeTransformer() =>
      _instance ??= const HealthSyncStateMetricEnumTypeTransformer._();

  const HealthSyncStateMetricEnumTypeTransformer._();

  String encode(HealthSyncStateMetricEnum data) => data._value;

  /// Returns the instance of [HealthSyncStateMetricEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  HealthSyncStateMetricEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is HealthSyncStateMetricEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'SLEEP':
          return HealthSyncStateMetricEnum.SLEEP;
        case r'STEPS':
          return HealthSyncStateMetricEnum.STEPS;
        case r'DISTANCE_METERS':
          return HealthSyncStateMetricEnum.DISTANCE_METERS;
        case r'ACTIVE_ENERGY_KCAL':
          return HealthSyncStateMetricEnum.ACTIVE_ENERGY_KCAL;
        case r'TOTAL_ENERGY_KCAL':
          return HealthSyncStateMetricEnum.TOTAL_ENERGY_KCAL;
        case r'EXERCISE_MINUTES':
          return HealthSyncStateMetricEnum.EXERCISE_MINUTES;
        case r'HEART_RATE_BPM':
          return HealthSyncStateMetricEnum.HEART_RATE_BPM;
        case r'RESTING_HEART_RATE_BPM':
          return HealthSyncStateMetricEnum.RESTING_HEART_RATE_BPM;
        case r'HEART_RATE_VARIABILITY_MS':
          return HealthSyncStateMetricEnum.HEART_RATE_VARIABILITY_MS;
        case r'RESPIRATORY_RATE_BPM':
          return HealthSyncStateMetricEnum.RESPIRATORY_RATE_BPM;
        case r'BLOOD_OXYGEN_PERCENT':
          return HealthSyncStateMetricEnum.BLOOD_OXYGEN_PERCENT;
        case r'BODY_TEMPERATURE_C':
          return HealthSyncStateMetricEnum.BODY_TEMPERATURE_C;
        case r'WEIGHT_KG':
          return HealthSyncStateMetricEnum.WEIGHT_KG;
        case r'BODY_FAT_PERCENT':
          return HealthSyncStateMetricEnum.BODY_FAT_PERCENT;
        case r'VO2_MAX':
          return HealthSyncStateMetricEnum.VO2_MAX;
        case r'unknown_default_open_api':
          return HealthSyncStateMetricEnum.unknownDefaultOpenApi;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static HealthSyncStateMetricEnumTypeTransformer? _instance;
}
