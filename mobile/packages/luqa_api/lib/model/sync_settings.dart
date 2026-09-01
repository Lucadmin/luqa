//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SyncSettings {
  /// Returns a new [SyncSettings] instance.
  SyncSettings({
    required this.currency,
    required this.dayStartHour,
    required this.weekStartsOn,
  });

  /// ISO 4217 code the amounts are in.
  final String currency;

  /// The hour a logical day flips. Someone who logs a block at 01:00 means it for the day that has not ended yet, so the day a row belongs to is not the day its clock says.
  ///
  /// Minimum value: 0
  /// Maximum value: 23
  final int dayStartHour;

  /// 0 = Sunday, 1 = Monday. Habit weeks are counted from here, so a device that guessed would put a \"3x per week\" quota in the wrong week for half the world.
  ///
  /// Minimum value: 0
  /// Maximum value: 6
  final int weekStartsOn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncSettings &&
          other.currency == currency &&
          other.dayStartHour == dayStartHour &&
          other.weekStartsOn == weekStartsOn;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (currency.hashCode) + (dayStartHour.hashCode) + (weekStartsOn.hashCode);

  @override
  String toString() =>
      'SyncSettings[currency=$currency, dayStartHour=$dayStartHour, weekStartsOn=$weekStartsOn]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'currency'] = this.currency;
    json[r'dayStartHour'] = this.dayStartHour;
    json[r'weekStartsOn'] = this.weekStartsOn;
    return json;
  }

  /// Clones this instance of [SyncSettings] and returns a new one where some of the
  /// properties have changed.
  SyncSettings copyWith({
    String? currency,
    int? dayStartHour,
    int? weekStartsOn,
  }) =>
      SyncSettings(
        currency: currency ?? this.currency,
        dayStartHour: dayStartHour ?? this.dayStartHour,
        weekStartsOn: weekStartsOn ?? this.weekStartsOn,
      );

  /// Returns a new [SyncSettings] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SyncSettings? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'currency'),
            'Required key "SyncSettings[currency]" is missing from JSON.');
        assert(json[r'currency'] != null,
            'Required key "SyncSettings[currency]" has a null value in JSON.');
        assert(json.containsKey(r'dayStartHour'),
            'Required key "SyncSettings[dayStartHour]" is missing from JSON.');
        assert(json[r'dayStartHour'] != null,
            'Required key "SyncSettings[dayStartHour]" has a null value in JSON.');
        assert(json.containsKey(r'weekStartsOn'),
            'Required key "SyncSettings[weekStartsOn]" is missing from JSON.');
        assert(json[r'weekStartsOn'] != null,
            'Required key "SyncSettings[weekStartsOn]" has a null value in JSON.');
        return true;
      }());

      return SyncSettings(
        currency: mapValueOfType<String>(json, r'currency')!,
        dayStartHour: mapValueOfType<int>(json, r'dayStartHour')!,
        weekStartsOn: mapValueOfType<int>(json, r'weekStartsOn')!,
      );
    }
    return null;
  }

  static List<SyncSettings> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SyncSettings>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SyncSettings.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SyncSettings> mapFromJson(dynamic json) {
    final map = <String, SyncSettings>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SyncSettings.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SyncSettings-objects as value to a dart map
  static Map<String, List<SyncSettings>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SyncSettings>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SyncSettings.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'currency',
    'dayStartHour',
    'weekStartsOn',
  };
}
