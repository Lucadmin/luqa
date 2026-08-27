//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HealthSyncRequest {
  /// Returns a new [HealthSyncRequest] instance.
  HealthSyncRequest({
    this.source_ = const Optional.absent(),
    this.deviceId = const Optional.absent(),
    this.sleep = const Optional.absent(),
    this.samples = const Optional.present(const []),
    this.deletedSamples = const Optional.present(const []),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<DeviceHealthSource?> source_;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> deviceId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<SleepSyncPayload?> sleep;

  final Optional<List<HealthSampleImport>?> samples;

  final Optional<List<HealthSampleRef>?> deletedSamples;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthSyncRequest &&
          other.source_ == source_ &&
          other.deviceId == deviceId &&
          other.sleep == sleep &&
          _deepEquality.equals(other.samples, samples) &&
          _deepEquality.equals(other.deletedSamples, deletedSamples);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (source_ == null ? 0 : source_!.hashCode) +
      (deviceId == null ? 0 : deviceId!.hashCode) +
      (sleep == null ? 0 : sleep!.hashCode) +
      (samples.hashCode) +
      (deletedSamples.hashCode);

  @override
  String toString() =>
      'HealthSyncRequest[source_=$source_, deviceId=$deviceId, sleep=$sleep, samples=$samples, deletedSamples=$deletedSamples]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.source_.isPresent) {
      final value = this.source_.value;
      json[r'source'] = value;
    }
    if (this.deviceId.isPresent) {
      final value = this.deviceId.value;
      json[r'deviceId'] = value;
    }
    if (this.sleep.isPresent) {
      final value = this.sleep.value;
      json[r'sleep'] = value;
    }
    if (this.samples.isPresent) {
      final value = this.samples.value;
      json[r'samples'] = value;
    }
    if (this.deletedSamples.isPresent) {
      final value = this.deletedSamples.value;
      json[r'deletedSamples'] = value;
    }
    return json;
  }

  /// Clones this instance of [HealthSyncRequest] and returns a new one where some of the
  /// properties have changed.
  HealthSyncRequest copyWith({
    Optional<DeviceHealthSource?>? source_,
    Optional<String?>? deviceId,
    Optional<SleepSyncPayload?>? sleep,
    Optional<List<HealthSampleImport>?>? samples,
    Optional<List<HealthSampleRef>?>? deletedSamples,
  }) =>
      HealthSyncRequest(
        source_: source_ ?? this.source_,
        deviceId: deviceId ?? this.deviceId,
        sleep: sleep ?? this.sleep,
        samples: samples ?? this.samples,
        deletedSamples: deletedSamples ?? this.deletedSamples,
      );

  /// Returns a new [HealthSyncRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HealthSyncRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return HealthSyncRequest(
        source_: json.containsKey(r'source')
            ? Optional.present(DeviceHealthSource.fromJson(json[r'source']))
            : const Optional.absent(),
        deviceId: json.containsKey(r'deviceId')
            ? Optional.present(mapValueOfType<String>(json, r'deviceId'))
            : const Optional.absent(),
        sleep: json.containsKey(r'sleep')
            ? Optional.present(SleepSyncPayload.fromJson(json[r'sleep']))
            : const Optional.absent(),
        samples: json.containsKey(r'samples')
            ? Optional.present(
                HealthSampleImport.listFromJson(json[r'samples']))
            : const Optional.absent(),
        deletedSamples: json.containsKey(r'deletedSamples')
            ? Optional.present(
                HealthSampleRef.listFromJson(json[r'deletedSamples']))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<HealthSyncRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HealthSyncRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HealthSyncRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HealthSyncRequest> mapFromJson(dynamic json) {
    final map = <String, HealthSyncRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HealthSyncRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HealthSyncRequest-objects as value to a dart map
  static Map<String, List<HealthSyncRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<HealthSyncRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HealthSyncRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{};
}
