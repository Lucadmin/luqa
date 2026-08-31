//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SleepEntry {
  /// Returns a new [SleepEntry] instance.
  SleepEntry({
    required this.id,
    required this.source_,
    required this.title,
    required this.sourceApp,
    required this.startTime,
    required this.endTime,
    required this.sleepMinutes,
    required this.awakeMinutes,
    required this.awakeInBedMinutes,
    required this.outOfBedMinutes,
    required this.lightMinutes,
    required this.deepMinutes,
    required this.remMinutes,
    required this.unknownMinutes,
    required this.inBedMinutes,
    required this.efficiencyPercent,
    required this.latencyMinutes,
    required this.wasoMinutes,
    required this.awakeningCount,
    required this.midpoint,
    required this.isNap,
    required this.recordingMethod,
    required this.deviceModel,
    this.stages = const [],
  });

  final String id;

  final SleepSource source_;

  final String? title;

  /// Provider application that recorded the session, when known.
  final String? sourceApp;

  final DateTime startTime;

  final DateTime endTime;

  /// Asleep minutes. Null when the provider only reported time in bed.
  final int? sleepMinutes;

  final int? awakeMinutes;

  final int? awakeInBedMinutes;

  final int? outOfBedMinutes;

  final int? lightMinutes;

  final int? deepMinutes;

  final int? remMinutes;

  /// Staged time the provider could not classify.
  final int? unknownMinutes;

  /// Wall-clock session length.
  final int? inBedMinutes;

  /// Asleep over time in bed, 0-100.
  final num? efficiencyPercent;

  /// Session start until the first asleep stage.
  final int? latencyMinutes;

  /// Wake after sleep onset, before the final wake.
  final int? wasoMinutes;

  /// Distinct awake blocks after sleep onset.
  final int? awakeningCount;

  /// Midpoint of the asleep span, for chronotype drift.
  final DateTime? midpoint;

  final bool isNap;

  final String? recordingMethod;

  final String? deviceModel;

  /// The night's stage timeline, normalized server-side. Empty when the provider reported totals only.
  final List<SleepStage> stages;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepEntry &&
          other.id == id &&
          other.source_ == source_ &&
          other.title == title &&
          other.sourceApp == sourceApp &&
          other.startTime == startTime &&
          other.endTime == endTime &&
          other.sleepMinutes == sleepMinutes &&
          other.awakeMinutes == awakeMinutes &&
          other.awakeInBedMinutes == awakeInBedMinutes &&
          other.outOfBedMinutes == outOfBedMinutes &&
          other.lightMinutes == lightMinutes &&
          other.deepMinutes == deepMinutes &&
          other.remMinutes == remMinutes &&
          other.unknownMinutes == unknownMinutes &&
          other.inBedMinutes == inBedMinutes &&
          other.efficiencyPercent == efficiencyPercent &&
          other.latencyMinutes == latencyMinutes &&
          other.wasoMinutes == wasoMinutes &&
          other.awakeningCount == awakeningCount &&
          other.midpoint == midpoint &&
          other.isNap == isNap &&
          other.recordingMethod == recordingMethod &&
          other.deviceModel == deviceModel &&
          _deepEquality.equals(other.stages, stages);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (source_.hashCode) +
      (title == null ? 0 : title!.hashCode) +
      (sourceApp == null ? 0 : sourceApp!.hashCode) +
      (startTime.hashCode) +
      (endTime.hashCode) +
      (sleepMinutes == null ? 0 : sleepMinutes!.hashCode) +
      (awakeMinutes == null ? 0 : awakeMinutes!.hashCode) +
      (awakeInBedMinutes == null ? 0 : awakeInBedMinutes!.hashCode) +
      (outOfBedMinutes == null ? 0 : outOfBedMinutes!.hashCode) +
      (lightMinutes == null ? 0 : lightMinutes!.hashCode) +
      (deepMinutes == null ? 0 : deepMinutes!.hashCode) +
      (remMinutes == null ? 0 : remMinutes!.hashCode) +
      (unknownMinutes == null ? 0 : unknownMinutes!.hashCode) +
      (inBedMinutes == null ? 0 : inBedMinutes!.hashCode) +
      (efficiencyPercent == null ? 0 : efficiencyPercent!.hashCode) +
      (latencyMinutes == null ? 0 : latencyMinutes!.hashCode) +
      (wasoMinutes == null ? 0 : wasoMinutes!.hashCode) +
      (awakeningCount == null ? 0 : awakeningCount!.hashCode) +
      (midpoint == null ? 0 : midpoint!.hashCode) +
      (isNap.hashCode) +
      (recordingMethod == null ? 0 : recordingMethod!.hashCode) +
      (deviceModel == null ? 0 : deviceModel!.hashCode) +
      (stages.hashCode);

  @override
  String toString() =>
      'SleepEntry[id=$id, source_=$source_, title=$title, sourceApp=$sourceApp, startTime=$startTime, endTime=$endTime, sleepMinutes=$sleepMinutes, awakeMinutes=$awakeMinutes, awakeInBedMinutes=$awakeInBedMinutes, outOfBedMinutes=$outOfBedMinutes, lightMinutes=$lightMinutes, deepMinutes=$deepMinutes, remMinutes=$remMinutes, unknownMinutes=$unknownMinutes, inBedMinutes=$inBedMinutes, efficiencyPercent=$efficiencyPercent, latencyMinutes=$latencyMinutes, wasoMinutes=$wasoMinutes, awakeningCount=$awakeningCount, midpoint=$midpoint, isNap=$isNap, recordingMethod=$recordingMethod, deviceModel=$deviceModel, stages=$stages]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'source'] = this.source_;
    if (this.title != null) {
      json[r'title'] = this.title;
    } else {
      json[r'title'] = null;
    }
    if (this.sourceApp != null) {
      json[r'sourceApp'] = this.sourceApp;
    } else {
      json[r'sourceApp'] = null;
    }
    json[r'startTime'] = this.startTime.toUtc().toIso8601String();
    json[r'endTime'] = this.endTime.toUtc().toIso8601String();
    if (this.sleepMinutes != null) {
      json[r'sleepMinutes'] = this.sleepMinutes;
    } else {
      json[r'sleepMinutes'] = null;
    }
    if (this.awakeMinutes != null) {
      json[r'awakeMinutes'] = this.awakeMinutes;
    } else {
      json[r'awakeMinutes'] = null;
    }
    if (this.awakeInBedMinutes != null) {
      json[r'awakeInBedMinutes'] = this.awakeInBedMinutes;
    } else {
      json[r'awakeInBedMinutes'] = null;
    }
    if (this.outOfBedMinutes != null) {
      json[r'outOfBedMinutes'] = this.outOfBedMinutes;
    } else {
      json[r'outOfBedMinutes'] = null;
    }
    if (this.lightMinutes != null) {
      json[r'lightMinutes'] = this.lightMinutes;
    } else {
      json[r'lightMinutes'] = null;
    }
    if (this.deepMinutes != null) {
      json[r'deepMinutes'] = this.deepMinutes;
    } else {
      json[r'deepMinutes'] = null;
    }
    if (this.remMinutes != null) {
      json[r'remMinutes'] = this.remMinutes;
    } else {
      json[r'remMinutes'] = null;
    }
    if (this.unknownMinutes != null) {
      json[r'unknownMinutes'] = this.unknownMinutes;
    } else {
      json[r'unknownMinutes'] = null;
    }
    if (this.inBedMinutes != null) {
      json[r'inBedMinutes'] = this.inBedMinutes;
    } else {
      json[r'inBedMinutes'] = null;
    }
    if (this.efficiencyPercent != null) {
      json[r'efficiencyPercent'] = this.efficiencyPercent;
    } else {
      json[r'efficiencyPercent'] = null;
    }
    if (this.latencyMinutes != null) {
      json[r'latencyMinutes'] = this.latencyMinutes;
    } else {
      json[r'latencyMinutes'] = null;
    }
    if (this.wasoMinutes != null) {
      json[r'wasoMinutes'] = this.wasoMinutes;
    } else {
      json[r'wasoMinutes'] = null;
    }
    if (this.awakeningCount != null) {
      json[r'awakeningCount'] = this.awakeningCount;
    } else {
      json[r'awakeningCount'] = null;
    }
    if (this.midpoint != null) {
      json[r'midpoint'] = this.midpoint!.toUtc().toIso8601String();
    } else {
      json[r'midpoint'] = null;
    }
    json[r'isNap'] = this.isNap;
    if (this.recordingMethod != null) {
      json[r'recordingMethod'] = this.recordingMethod;
    } else {
      json[r'recordingMethod'] = null;
    }
    if (this.deviceModel != null) {
      json[r'deviceModel'] = this.deviceModel;
    } else {
      json[r'deviceModel'] = null;
    }
    json[r'stages'] = this.stages;
    return json;
  }

  /// Clones this instance of [SleepEntry] and returns a new one where some of the
  /// properties have changed.
  SleepEntry copyWith({
    String? id,
    SleepSource? source_,
    String? title,
    bool titleSetToNull = false,
    String? sourceApp,
    bool sourceAppSetToNull = false,
    DateTime? startTime,
    DateTime? endTime,
    int? sleepMinutes,
    bool sleepMinutesSetToNull = false,
    int? awakeMinutes,
    bool awakeMinutesSetToNull = false,
    int? awakeInBedMinutes,
    bool awakeInBedMinutesSetToNull = false,
    int? outOfBedMinutes,
    bool outOfBedMinutesSetToNull = false,
    int? lightMinutes,
    bool lightMinutesSetToNull = false,
    int? deepMinutes,
    bool deepMinutesSetToNull = false,
    int? remMinutes,
    bool remMinutesSetToNull = false,
    int? unknownMinutes,
    bool unknownMinutesSetToNull = false,
    int? inBedMinutes,
    bool inBedMinutesSetToNull = false,
    num? efficiencyPercent,
    bool efficiencyPercentSetToNull = false,
    int? latencyMinutes,
    bool latencyMinutesSetToNull = false,
    int? wasoMinutes,
    bool wasoMinutesSetToNull = false,
    int? awakeningCount,
    bool awakeningCountSetToNull = false,
    DateTime? midpoint,
    bool midpointSetToNull = false,
    bool? isNap,
    String? recordingMethod,
    bool recordingMethodSetToNull = false,
    String? deviceModel,
    bool deviceModelSetToNull = false,
    List<SleepStage>? stages,
  }) =>
      SleepEntry(
        id: id ?? this.id,
        source_: source_ ?? this.source_,
        title: titleSetToNull ? null : title ?? this.title,
        sourceApp: sourceAppSetToNull ? null : sourceApp ?? this.sourceApp,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        sleepMinutes:
            sleepMinutesSetToNull ? null : sleepMinutes ?? this.sleepMinutes,
        awakeMinutes:
            awakeMinutesSetToNull ? null : awakeMinutes ?? this.awakeMinutes,
        awakeInBedMinutes: awakeInBedMinutesSetToNull
            ? null
            : awakeInBedMinutes ?? this.awakeInBedMinutes,
        outOfBedMinutes: outOfBedMinutesSetToNull
            ? null
            : outOfBedMinutes ?? this.outOfBedMinutes,
        lightMinutes:
            lightMinutesSetToNull ? null : lightMinutes ?? this.lightMinutes,
        deepMinutes:
            deepMinutesSetToNull ? null : deepMinutes ?? this.deepMinutes,
        remMinutes: remMinutesSetToNull ? null : remMinutes ?? this.remMinutes,
        unknownMinutes: unknownMinutesSetToNull
            ? null
            : unknownMinutes ?? this.unknownMinutes,
        inBedMinutes:
            inBedMinutesSetToNull ? null : inBedMinutes ?? this.inBedMinutes,
        efficiencyPercent: efficiencyPercentSetToNull
            ? null
            : efficiencyPercent ?? this.efficiencyPercent,
        latencyMinutes: latencyMinutesSetToNull
            ? null
            : latencyMinutes ?? this.latencyMinutes,
        wasoMinutes:
            wasoMinutesSetToNull ? null : wasoMinutes ?? this.wasoMinutes,
        awakeningCount: awakeningCountSetToNull
            ? null
            : awakeningCount ?? this.awakeningCount,
        midpoint: midpointSetToNull ? null : midpoint ?? this.midpoint,
        isNap: isNap ?? this.isNap,
        recordingMethod: recordingMethodSetToNull
            ? null
            : recordingMethod ?? this.recordingMethod,
        deviceModel:
            deviceModelSetToNull ? null : deviceModel ?? this.deviceModel,
        stages: stages ?? this.stages,
      );

  /// Returns a new [SleepEntry] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SleepEntry? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "SleepEntry[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "SleepEntry[id]" has a null value in JSON.');
        assert(json.containsKey(r'source'),
            'Required key "SleepEntry[source]" is missing from JSON.');
        assert(json[r'source'] != null,
            'Required key "SleepEntry[source]" has a null value in JSON.');
        assert(json.containsKey(r'title'),
            'Required key "SleepEntry[title]" is missing from JSON.');
        assert(json.containsKey(r'sourceApp'),
            'Required key "SleepEntry[sourceApp]" is missing from JSON.');
        assert(json.containsKey(r'startTime'),
            'Required key "SleepEntry[startTime]" is missing from JSON.');
        assert(json[r'startTime'] != null,
            'Required key "SleepEntry[startTime]" has a null value in JSON.');
        assert(json.containsKey(r'endTime'),
            'Required key "SleepEntry[endTime]" is missing from JSON.');
        assert(json[r'endTime'] != null,
            'Required key "SleepEntry[endTime]" has a null value in JSON.');
        assert(json.containsKey(r'sleepMinutes'),
            'Required key "SleepEntry[sleepMinutes]" is missing from JSON.');
        assert(json.containsKey(r'awakeMinutes'),
            'Required key "SleepEntry[awakeMinutes]" is missing from JSON.');
        assert(json.containsKey(r'awakeInBedMinutes'),
            'Required key "SleepEntry[awakeInBedMinutes]" is missing from JSON.');
        assert(json.containsKey(r'outOfBedMinutes'),
            'Required key "SleepEntry[outOfBedMinutes]" is missing from JSON.');
        assert(json.containsKey(r'lightMinutes'),
            'Required key "SleepEntry[lightMinutes]" is missing from JSON.');
        assert(json.containsKey(r'deepMinutes'),
            'Required key "SleepEntry[deepMinutes]" is missing from JSON.');
        assert(json.containsKey(r'remMinutes'),
            'Required key "SleepEntry[remMinutes]" is missing from JSON.');
        assert(json.containsKey(r'unknownMinutes'),
            'Required key "SleepEntry[unknownMinutes]" is missing from JSON.');
        assert(json.containsKey(r'inBedMinutes'),
            'Required key "SleepEntry[inBedMinutes]" is missing from JSON.');
        assert(json.containsKey(r'efficiencyPercent'),
            'Required key "SleepEntry[efficiencyPercent]" is missing from JSON.');
        assert(json.containsKey(r'latencyMinutes'),
            'Required key "SleepEntry[latencyMinutes]" is missing from JSON.');
        assert(json.containsKey(r'wasoMinutes'),
            'Required key "SleepEntry[wasoMinutes]" is missing from JSON.');
        assert(json.containsKey(r'awakeningCount'),
            'Required key "SleepEntry[awakeningCount]" is missing from JSON.');
        assert(json.containsKey(r'midpoint'),
            'Required key "SleepEntry[midpoint]" is missing from JSON.');
        assert(json.containsKey(r'isNap'),
            'Required key "SleepEntry[isNap]" is missing from JSON.');
        assert(json[r'isNap'] != null,
            'Required key "SleepEntry[isNap]" has a null value in JSON.');
        assert(json.containsKey(r'recordingMethod'),
            'Required key "SleepEntry[recordingMethod]" is missing from JSON.');
        assert(json.containsKey(r'deviceModel'),
            'Required key "SleepEntry[deviceModel]" is missing from JSON.');
        assert(json.containsKey(r'stages'),
            'Required key "SleepEntry[stages]" is missing from JSON.');
        assert(json[r'stages'] != null,
            'Required key "SleepEntry[stages]" has a null value in JSON.');
        return true;
      }());

      return SleepEntry(
        id: mapValueOfType<String>(json, r'id')!,
        source_: SleepSource.fromJson(json[r'source'])!,
        title: mapValueOfType<String>(json, r'title'),
        sourceApp: mapValueOfType<String>(json, r'sourceApp'),
        startTime: mapDateTime(json, r'startTime', r'')!,
        endTime: mapDateTime(json, r'endTime', r'')!,
        sleepMinutes: mapValueOfType<int>(json, r'sleepMinutes'),
        awakeMinutes: mapValueOfType<int>(json, r'awakeMinutes'),
        awakeInBedMinutes: mapValueOfType<int>(json, r'awakeInBedMinutes'),
        outOfBedMinutes: mapValueOfType<int>(json, r'outOfBedMinutes'),
        lightMinutes: mapValueOfType<int>(json, r'lightMinutes'),
        deepMinutes: mapValueOfType<int>(json, r'deepMinutes'),
        remMinutes: mapValueOfType<int>(json, r'remMinutes'),
        unknownMinutes: mapValueOfType<int>(json, r'unknownMinutes'),
        inBedMinutes: mapValueOfType<int>(json, r'inBedMinutes'),
        efficiencyPercent: json[r'efficiencyPercent'] == null
            ? null
            : num.parse('${json[r'efficiencyPercent']}'),
        latencyMinutes: mapValueOfType<int>(json, r'latencyMinutes'),
        wasoMinutes: mapValueOfType<int>(json, r'wasoMinutes'),
        awakeningCount: mapValueOfType<int>(json, r'awakeningCount'),
        midpoint: mapDateTime(json, r'midpoint', r''),
        isNap: mapValueOfType<bool>(json, r'isNap')!,
        recordingMethod: mapValueOfType<String>(json, r'recordingMethod'),
        deviceModel: mapValueOfType<String>(json, r'deviceModel'),
        stages: SleepStage.listFromJson(json[r'stages']),
      );
    }
    return null;
  }

  static List<SleepEntry> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SleepEntry>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SleepEntry.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SleepEntry> mapFromJson(dynamic json) {
    final map = <String, SleepEntry>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SleepEntry.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SleepEntry-objects as value to a dart map
  static Map<String, List<SleepEntry>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SleepEntry>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SleepEntry.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'source',
    'title',
    'sourceApp',
    'startTime',
    'endTime',
    'sleepMinutes',
    'awakeMinutes',
    'awakeInBedMinutes',
    'outOfBedMinutes',
    'lightMinutes',
    'deepMinutes',
    'remMinutes',
    'unknownMinutes',
    'inBedMinutes',
    'efficiencyPercent',
    'latencyMinutes',
    'wasoMinutes',
    'awakeningCount',
    'midpoint',
    'isNap',
    'recordingMethod',
    'deviceModel',
    'stages',
  };
}
