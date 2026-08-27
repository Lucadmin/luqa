//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SleepSessionImport {
  /// Returns a new [SleepSessionImport] instance.
  SleepSessionImport({
    this.externalId = const Optional.absent(),
    this.title = const Optional.absent(),
    this.notes = const Optional.absent(),
    this.sourceApp = const Optional.absent(),
    required this.startTime,
    required this.endTime,
    this.startZoneOffset = const Optional.absent(),
    this.endZoneOffset = const Optional.absent(),
    this.sleepMinutes = const Optional.absent(),
    this.awakeMinutes = const Optional.absent(),
    this.awakeInBedMinutes = const Optional.absent(),
    this.outOfBedMinutes = const Optional.absent(),
    this.lightMinutes = const Optional.absent(),
    this.deepMinutes = const Optional.absent(),
    this.remMinutes = const Optional.absent(),
    this.unknownMinutes = const Optional.absent(),
    this.isNap = const Optional.absent(),
    this.recordingMethod = const Optional.absent(),
    this.deviceModel = const Optional.absent(),
    this.stages = const Optional.present(const []),
  });

  /// Provider record id. Falls back to a start/end key when absent.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> externalId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> title;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> notes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> sourceApp;

  final DateTime startTime;

  final DateTime endTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> startZoneOffset;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> endZoneOffset;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> sleepMinutes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> awakeMinutes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> awakeInBedMinutes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> outOfBedMinutes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> lightMinutes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> deepMinutes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> remMinutes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> unknownMinutes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> isNap;

  final Optional<SleepSessionImportRecordingMethodEnum?> recordingMethod;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> deviceModel;

  final Optional<List<SleepStage>?> stages;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepSessionImport &&
          other.externalId == externalId &&
          other.title == title &&
          other.notes == notes &&
          other.sourceApp == sourceApp &&
          other.startTime == startTime &&
          other.endTime == endTime &&
          other.startZoneOffset == startZoneOffset &&
          other.endZoneOffset == endZoneOffset &&
          other.sleepMinutes == sleepMinutes &&
          other.awakeMinutes == awakeMinutes &&
          other.awakeInBedMinutes == awakeInBedMinutes &&
          other.outOfBedMinutes == outOfBedMinutes &&
          other.lightMinutes == lightMinutes &&
          other.deepMinutes == deepMinutes &&
          other.remMinutes == remMinutes &&
          other.unknownMinutes == unknownMinutes &&
          other.isNap == isNap &&
          other.recordingMethod == recordingMethod &&
          other.deviceModel == deviceModel &&
          _deepEquality.equals(other.stages, stages);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (externalId == null ? 0 : externalId!.hashCode) +
      (title == null ? 0 : title!.hashCode) +
      (notes == null ? 0 : notes!.hashCode) +
      (sourceApp == null ? 0 : sourceApp!.hashCode) +
      (startTime.hashCode) +
      (endTime.hashCode) +
      (startZoneOffset == null ? 0 : startZoneOffset!.hashCode) +
      (endZoneOffset == null ? 0 : endZoneOffset!.hashCode) +
      (sleepMinutes == null ? 0 : sleepMinutes!.hashCode) +
      (awakeMinutes == null ? 0 : awakeMinutes!.hashCode) +
      (awakeInBedMinutes == null ? 0 : awakeInBedMinutes!.hashCode) +
      (outOfBedMinutes == null ? 0 : outOfBedMinutes!.hashCode) +
      (lightMinutes == null ? 0 : lightMinutes!.hashCode) +
      (deepMinutes == null ? 0 : deepMinutes!.hashCode) +
      (remMinutes == null ? 0 : remMinutes!.hashCode) +
      (unknownMinutes == null ? 0 : unknownMinutes!.hashCode) +
      (isNap == null ? 0 : isNap!.hashCode) +
      (recordingMethod == null ? 0 : recordingMethod!.hashCode) +
      (deviceModel == null ? 0 : deviceModel!.hashCode) +
      (stages.hashCode);

  @override
  String toString() =>
      'SleepSessionImport[externalId=$externalId, title=$title, notes=$notes, sourceApp=$sourceApp, startTime=$startTime, endTime=$endTime, startZoneOffset=$startZoneOffset, endZoneOffset=$endZoneOffset, sleepMinutes=$sleepMinutes, awakeMinutes=$awakeMinutes, awakeInBedMinutes=$awakeInBedMinutes, outOfBedMinutes=$outOfBedMinutes, lightMinutes=$lightMinutes, deepMinutes=$deepMinutes, remMinutes=$remMinutes, unknownMinutes=$unknownMinutes, isNap=$isNap, recordingMethod=$recordingMethod, deviceModel=$deviceModel, stages=$stages]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.externalId.isPresent) {
      final value = this.externalId.value;
      json[r'externalId'] = value;
    }
    if (this.title.isPresent) {
      final value = this.title.value;
      json[r'title'] = value;
    }
    if (this.notes.isPresent) {
      final value = this.notes.value;
      json[r'notes'] = value;
    }
    if (this.sourceApp.isPresent) {
      final value = this.sourceApp.value;
      json[r'sourceApp'] = value;
    }
    json[r'startTime'] = this.startTime.toUtc().toIso8601String();
    json[r'endTime'] = this.endTime.toUtc().toIso8601String();
    if (this.startZoneOffset.isPresent) {
      final value = this.startZoneOffset.value;
      json[r'startZoneOffset'] = value;
    }
    if (this.endZoneOffset.isPresent) {
      final value = this.endZoneOffset.value;
      json[r'endZoneOffset'] = value;
    }
    if (this.sleepMinutes.isPresent) {
      final value = this.sleepMinutes.value;
      json[r'sleepMinutes'] = value;
    }
    if (this.awakeMinutes.isPresent) {
      final value = this.awakeMinutes.value;
      json[r'awakeMinutes'] = value;
    }
    if (this.awakeInBedMinutes.isPresent) {
      final value = this.awakeInBedMinutes.value;
      json[r'awakeInBedMinutes'] = value;
    }
    if (this.outOfBedMinutes.isPresent) {
      final value = this.outOfBedMinutes.value;
      json[r'outOfBedMinutes'] = value;
    }
    if (this.lightMinutes.isPresent) {
      final value = this.lightMinutes.value;
      json[r'lightMinutes'] = value;
    }
    if (this.deepMinutes.isPresent) {
      final value = this.deepMinutes.value;
      json[r'deepMinutes'] = value;
    }
    if (this.remMinutes.isPresent) {
      final value = this.remMinutes.value;
      json[r'remMinutes'] = value;
    }
    if (this.unknownMinutes.isPresent) {
      final value = this.unknownMinutes.value;
      json[r'unknownMinutes'] = value;
    }
    if (this.isNap.isPresent) {
      final value = this.isNap.value;
      json[r'isNap'] = value;
    }
    if (this.recordingMethod.isPresent) {
      final value = this.recordingMethod.value;
      json[r'recordingMethod'] = value;
    }
    if (this.deviceModel.isPresent) {
      final value = this.deviceModel.value;
      json[r'deviceModel'] = value;
    }
    if (this.stages.isPresent) {
      final value = this.stages.value;
      json[r'stages'] = value;
    }
    return json;
  }

  /// Clones this instance of [SleepSessionImport] and returns a new one where some of the
  /// properties have changed.
  SleepSessionImport copyWith({
    Optional<String?>? externalId,
    Optional<String?>? title,
    Optional<String?>? notes,
    Optional<String?>? sourceApp,
    DateTime? startTime,
    DateTime? endTime,
    Optional<String?>? startZoneOffset,
    Optional<String?>? endZoneOffset,
    Optional<int?>? sleepMinutes,
    Optional<int?>? awakeMinutes,
    Optional<int?>? awakeInBedMinutes,
    Optional<int?>? outOfBedMinutes,
    Optional<int?>? lightMinutes,
    Optional<int?>? deepMinutes,
    Optional<int?>? remMinutes,
    Optional<int?>? unknownMinutes,
    Optional<bool?>? isNap,
    Optional<SleepSessionImportRecordingMethodEnum?>? recordingMethod,
    Optional<String?>? deviceModel,
    Optional<List<SleepStage>?>? stages,
  }) =>
      SleepSessionImport(
        externalId: externalId ?? this.externalId,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        sourceApp: sourceApp ?? this.sourceApp,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        startZoneOffset: startZoneOffset ?? this.startZoneOffset,
        endZoneOffset: endZoneOffset ?? this.endZoneOffset,
        sleepMinutes: sleepMinutes ?? this.sleepMinutes,
        awakeMinutes: awakeMinutes ?? this.awakeMinutes,
        awakeInBedMinutes: awakeInBedMinutes ?? this.awakeInBedMinutes,
        outOfBedMinutes: outOfBedMinutes ?? this.outOfBedMinutes,
        lightMinutes: lightMinutes ?? this.lightMinutes,
        deepMinutes: deepMinutes ?? this.deepMinutes,
        remMinutes: remMinutes ?? this.remMinutes,
        unknownMinutes: unknownMinutes ?? this.unknownMinutes,
        isNap: isNap ?? this.isNap,
        recordingMethod: recordingMethod ?? this.recordingMethod,
        deviceModel: deviceModel ?? this.deviceModel,
        stages: stages ?? this.stages,
      );

  /// Returns a new [SleepSessionImport] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SleepSessionImport? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'startTime'),
            'Required key "SleepSessionImport[startTime]" is missing from JSON.');
        assert(json[r'startTime'] != null,
            'Required key "SleepSessionImport[startTime]" has a null value in JSON.');
        assert(json.containsKey(r'endTime'),
            'Required key "SleepSessionImport[endTime]" is missing from JSON.');
        assert(json[r'endTime'] != null,
            'Required key "SleepSessionImport[endTime]" has a null value in JSON.');
        return true;
      }());

      return SleepSessionImport(
        externalId: json.containsKey(r'externalId')
            ? Optional.present(mapValueOfType<String>(json, r'externalId'))
            : const Optional.absent(),
        title: json.containsKey(r'title')
            ? Optional.present(mapValueOfType<String>(json, r'title'))
            : const Optional.absent(),
        notes: json.containsKey(r'notes')
            ? Optional.present(mapValueOfType<String>(json, r'notes'))
            : const Optional.absent(),
        sourceApp: json.containsKey(r'sourceApp')
            ? Optional.present(mapValueOfType<String>(json, r'sourceApp'))
            : const Optional.absent(),
        startTime: mapDateTime(json, r'startTime', r'')!,
        endTime: mapDateTime(json, r'endTime', r'')!,
        startZoneOffset: json.containsKey(r'startZoneOffset')
            ? Optional.present(mapValueOfType<String>(json, r'startZoneOffset'))
            : const Optional.absent(),
        endZoneOffset: json.containsKey(r'endZoneOffset')
            ? Optional.present(mapValueOfType<String>(json, r'endZoneOffset'))
            : const Optional.absent(),
        sleepMinutes: json.containsKey(r'sleepMinutes')
            ? Optional.present(json[r'sleepMinutes'] == null
                ? null
                : int.parse('${json[r'sleepMinutes']}'))
            : const Optional.absent(),
        awakeMinutes: json.containsKey(r'awakeMinutes')
            ? Optional.present(json[r'awakeMinutes'] == null
                ? null
                : int.parse('${json[r'awakeMinutes']}'))
            : const Optional.absent(),
        awakeInBedMinutes: json.containsKey(r'awakeInBedMinutes')
            ? Optional.present(json[r'awakeInBedMinutes'] == null
                ? null
                : int.parse('${json[r'awakeInBedMinutes']}'))
            : const Optional.absent(),
        outOfBedMinutes: json.containsKey(r'outOfBedMinutes')
            ? Optional.present(json[r'outOfBedMinutes'] == null
                ? null
                : int.parse('${json[r'outOfBedMinutes']}'))
            : const Optional.absent(),
        lightMinutes: json.containsKey(r'lightMinutes')
            ? Optional.present(json[r'lightMinutes'] == null
                ? null
                : int.parse('${json[r'lightMinutes']}'))
            : const Optional.absent(),
        deepMinutes: json.containsKey(r'deepMinutes')
            ? Optional.present(json[r'deepMinutes'] == null
                ? null
                : int.parse('${json[r'deepMinutes']}'))
            : const Optional.absent(),
        remMinutes: json.containsKey(r'remMinutes')
            ? Optional.present(json[r'remMinutes'] == null
                ? null
                : int.parse('${json[r'remMinutes']}'))
            : const Optional.absent(),
        unknownMinutes: json.containsKey(r'unknownMinutes')
            ? Optional.present(json[r'unknownMinutes'] == null
                ? null
                : int.parse('${json[r'unknownMinutes']}'))
            : const Optional.absent(),
        isNap: json.containsKey(r'isNap')
            ? Optional.present(mapValueOfType<bool>(json, r'isNap'))
            : const Optional.absent(),
        recordingMethod: json.containsKey(r'recordingMethod')
            ? Optional.present(SleepSessionImportRecordingMethodEnum.fromJson(
                json[r'recordingMethod']))
            : const Optional.absent(),
        deviceModel: json.containsKey(r'deviceModel')
            ? Optional.present(mapValueOfType<String>(json, r'deviceModel'))
            : const Optional.absent(),
        stages: json.containsKey(r'stages')
            ? Optional.present(SleepStage.listFromJson(json[r'stages']))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<SleepSessionImport> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SleepSessionImport>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SleepSessionImport.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SleepSessionImport> mapFromJson(dynamic json) {
    final map = <String, SleepSessionImport>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SleepSessionImport.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SleepSessionImport-objects as value to a dart map
  static Map<String, List<SleepSessionImport>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SleepSessionImport>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SleepSessionImport.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'startTime',
    'endTime',
  };
}

enum SleepSessionImportRecordingMethodEnum {
  AUTOMATICALLY_RECORDED._(r'AUTOMATICALLY_RECORDED'),
  ACTIVELY_RECORDED._(r'ACTIVELY_RECORDED'),
  MANUAL_ENTRY._(r'MANUAL_ENTRY'),
  UNKNOWN._(r'UNKNOWN'),
  unknownDefaultOpenApi._(r'unknown_default_open_api'),
  ;

  /// Instantiate a new enum with the provided value.
  const SleepSessionImportRecordingMethodEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SleepSessionImportRecordingMethodEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SleepSessionImportRecordingMethodEnum? fromJson(dynamic value) =>
      SleepSessionImportRecordingMethodEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SleepSessionImportRecordingMethodEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SleepSessionImportRecordingMethodEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SleepSessionImportRecordingMethodEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SleepSessionImportRecordingMethodEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SleepSessionImportRecordingMethodEnum] to Optional<String?>,
/// and [decode] dynamic data back to [SleepSessionImportRecordingMethodEnum].
class SleepSessionImportRecordingMethodEnumTypeTransformer {
  factory SleepSessionImportRecordingMethodEnumTypeTransformer() =>
      _instance ??=
          const SleepSessionImportRecordingMethodEnumTypeTransformer._();

  const SleepSessionImportRecordingMethodEnumTypeTransformer._();

  String encode(SleepSessionImportRecordingMethodEnum data) => data._value;

  /// Returns the instance of [SleepSessionImportRecordingMethodEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SleepSessionImportRecordingMethodEnum? decode(dynamic data,
      {bool allowNull = true}) {
    if (data is SleepSessionImportRecordingMethodEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'AUTOMATICALLY_RECORDED':
          return SleepSessionImportRecordingMethodEnum.AUTOMATICALLY_RECORDED;
        case r'ACTIVELY_RECORDED':
          return SleepSessionImportRecordingMethodEnum.ACTIVELY_RECORDED;
        case r'MANUAL_ENTRY':
          return SleepSessionImportRecordingMethodEnum.MANUAL_ENTRY;
        case r'UNKNOWN':
          return SleepSessionImportRecordingMethodEnum.UNKNOWN;
        case r'unknown_default_open_api':
          return SleepSessionImportRecordingMethodEnum.unknownDefaultOpenApi;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SleepSessionImportRecordingMethodEnumTypeTransformer? _instance;
}
