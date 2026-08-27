//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SleepSyncPayload {
  /// Returns a new [SleepSyncPayload] instance.
  SleepSyncPayload({
    this.entries = const Optional.present(const []),
    this.deletedExternalIds = const Optional.present(const []),
    this.window = const Optional.absent(),
  });

  final Optional<List<SleepSessionImport>?> entries;

  final Optional<List<String>?> deletedExternalIds;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<SleepSyncWindow?> window;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepSyncPayload &&
          _deepEquality.equals(other.entries, entries) &&
          _deepEquality.equals(other.deletedExternalIds, deletedExternalIds) &&
          other.window == window;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (entries.hashCode) +
      (deletedExternalIds.hashCode) +
      (window == null ? 0 : window!.hashCode);

  @override
  String toString() =>
      'SleepSyncPayload[entries=$entries, deletedExternalIds=$deletedExternalIds, window=$window]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.entries.isPresent) {
      final value = this.entries.value;
      json[r'entries'] = value;
    }
    if (this.deletedExternalIds.isPresent) {
      final value = this.deletedExternalIds.value;
      json[r'deletedExternalIds'] = value;
    }
    if (this.window.isPresent) {
      final value = this.window.value;
      json[r'window'] = value;
    }
    return json;
  }

  /// Clones this instance of [SleepSyncPayload] and returns a new one where some of the
  /// properties have changed.
  SleepSyncPayload copyWith({
    Optional<List<SleepSessionImport>?>? entries,
    Optional<List<String>?>? deletedExternalIds,
    Optional<SleepSyncWindow?>? window,
  }) =>
      SleepSyncPayload(
        entries: entries ?? this.entries,
        deletedExternalIds: deletedExternalIds ?? this.deletedExternalIds,
        window: window ?? this.window,
      );

  /// Returns a new [SleepSyncPayload] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SleepSyncPayload? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return SleepSyncPayload(
        entries: json.containsKey(r'entries')
            ? Optional.present(
                SleepSessionImport.listFromJson(json[r'entries']))
            : const Optional.absent(),
        deletedExternalIds: json.containsKey(r'deletedExternalIds')
            ? Optional.present(json[r'deletedExternalIds'] is Iterable
                ? (json[r'deletedExternalIds'] as Iterable)
                    .cast<String>()
                    .toList(growable: false)
                : const [])
            : const Optional.absent(),
        window: json.containsKey(r'window')
            ? Optional.present(SleepSyncWindow.fromJson(json[r'window']))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<SleepSyncPayload> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SleepSyncPayload>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SleepSyncPayload.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SleepSyncPayload> mapFromJson(dynamic json) {
    final map = <String, SleepSyncPayload>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SleepSyncPayload.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SleepSyncPayload-objects as value to a dart map
  static Map<String, List<SleepSyncPayload>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SleepSyncPayload>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SleepSyncPayload.listFromJson(
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
