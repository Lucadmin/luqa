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
    required this.lightMinutes,
    required this.deepMinutes,
    required this.remMinutes,
    this.efficiencyPercent = const Optional.absent(),
    required this.isNap,
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

  final int? lightMinutes;

  final int? deepMinutes;

  final int? remMinutes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<num?> efficiencyPercent;

  final bool isNap;

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
          other.lightMinutes == lightMinutes &&
          other.deepMinutes == deepMinutes &&
          other.remMinutes == remMinutes &&
          other.efficiencyPercent == efficiencyPercent &&
          other.isNap == isNap;

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
      (lightMinutes == null ? 0 : lightMinutes!.hashCode) +
      (deepMinutes == null ? 0 : deepMinutes!.hashCode) +
      (remMinutes == null ? 0 : remMinutes!.hashCode) +
      (efficiencyPercent == null ? 0 : efficiencyPercent!.hashCode) +
      (isNap.hashCode);

  @override
  String toString() =>
      'SleepEntry[id=$id, source_=$source_, title=$title, sourceApp=$sourceApp, startTime=$startTime, endTime=$endTime, sleepMinutes=$sleepMinutes, awakeMinutes=$awakeMinutes, lightMinutes=$lightMinutes, deepMinutes=$deepMinutes, remMinutes=$remMinutes, efficiencyPercent=$efficiencyPercent, isNap=$isNap]';

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
    if (this.efficiencyPercent.isPresent) {
      final value = this.efficiencyPercent.value;
      json[r'efficiencyPercent'] = value;
    }
    json[r'isNap'] = this.isNap;
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
    int? lightMinutes,
    bool lightMinutesSetToNull = false,
    int? deepMinutes,
    bool deepMinutesSetToNull = false,
    int? remMinutes,
    bool remMinutesSetToNull = false,
    Optional<num?>? efficiencyPercent,
    bool? isNap,
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
        lightMinutes:
            lightMinutesSetToNull ? null : lightMinutes ?? this.lightMinutes,
        deepMinutes:
            deepMinutesSetToNull ? null : deepMinutes ?? this.deepMinutes,
        remMinutes: remMinutesSetToNull ? null : remMinutes ?? this.remMinutes,
        efficiencyPercent: efficiencyPercent ?? this.efficiencyPercent,
        isNap: isNap ?? this.isNap,
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
        assert(json.containsKey(r'lightMinutes'),
            'Required key "SleepEntry[lightMinutes]" is missing from JSON.');
        assert(json.containsKey(r'deepMinutes'),
            'Required key "SleepEntry[deepMinutes]" is missing from JSON.');
        assert(json.containsKey(r'remMinutes'),
            'Required key "SleepEntry[remMinutes]" is missing from JSON.');
        assert(json.containsKey(r'isNap'),
            'Required key "SleepEntry[isNap]" is missing from JSON.');
        assert(json[r'isNap'] != null,
            'Required key "SleepEntry[isNap]" has a null value in JSON.');
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
        lightMinutes: mapValueOfType<int>(json, r'lightMinutes'),
        deepMinutes: mapValueOfType<int>(json, r'deepMinutes'),
        remMinutes: mapValueOfType<int>(json, r'remMinutes'),
        efficiencyPercent: json.containsKey(r'efficiencyPercent')
            ? Optional.present(json[r'efficiencyPercent'] == null
                ? null
                : num.parse('${json[r'efficiencyPercent']}'))
            : const Optional.absent(),
        isNap: mapValueOfType<bool>(json, r'isNap')!,
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
    'lightMinutes',
    'deepMinutes',
    'remMinutes',
    'isNap',
  };
}
