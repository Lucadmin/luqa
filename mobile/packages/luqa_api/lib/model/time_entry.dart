//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TimeEntry {
  /// Returns a new [TimeEntry] instance.
  TimeEntry({
    required this.id,
    required this.description,
    required this.categoryId,
    required this.startTime,
    required this.endTime,
    required this.source_,
    this.personIds = const [],
  });

  final String id;

  final String description;

  final String? categoryId;

  final DateTime startTime;

  final DateTime? endTime;

  final EntrySource source_;

  /// Who was there. Rides inside the entry rather than syncing on its own, the same way a person's notes ride inside them: one row is one whole block of time. This is what lets \"last seen\" be a fact the app already knows rather than one the owner types twice.
  final List<String> personIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeEntry &&
          other.id == id &&
          other.description == description &&
          other.categoryId == categoryId &&
          other.startTime == startTime &&
          other.endTime == endTime &&
          other.source_ == source_ &&
          _deepEquality.equals(other.personIds, personIds);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (description.hashCode) +
      (categoryId == null ? 0 : categoryId!.hashCode) +
      (startTime.hashCode) +
      (endTime == null ? 0 : endTime!.hashCode) +
      (source_.hashCode) +
      (personIds.hashCode);

  @override
  String toString() =>
      'TimeEntry[id=$id, description=$description, categoryId=$categoryId, startTime=$startTime, endTime=$endTime, source_=$source_, personIds=$personIds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'description'] = this.description;
    if (this.categoryId != null) {
      json[r'categoryId'] = this.categoryId;
    } else {
      json[r'categoryId'] = null;
    }
    json[r'startTime'] = this.startTime.toUtc().toIso8601String();
    if (this.endTime != null) {
      json[r'endTime'] = this.endTime!.toUtc().toIso8601String();
    } else {
      json[r'endTime'] = null;
    }
    json[r'source'] = this.source_;
    json[r'personIds'] = this.personIds;
    return json;
  }

  /// Clones this instance of [TimeEntry] and returns a new one where some of the
  /// properties have changed.
  TimeEntry copyWith({
    String? id,
    String? description,
    String? categoryId,
    bool categoryIdSetToNull = false,
    DateTime? startTime,
    DateTime? endTime,
    bool endTimeSetToNull = false,
    EntrySource? source_,
    List<String>? personIds,
  }) =>
      TimeEntry(
        id: id ?? this.id,
        description: description ?? this.description,
        categoryId: categoryIdSetToNull ? null : categoryId ?? this.categoryId,
        startTime: startTime ?? this.startTime,
        endTime: endTimeSetToNull ? null : endTime ?? this.endTime,
        source_: source_ ?? this.source_,
        personIds: personIds ?? this.personIds,
      );

  /// Returns a new [TimeEntry] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TimeEntry? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "TimeEntry[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "TimeEntry[id]" has a null value in JSON.');
        assert(json.containsKey(r'description'),
            'Required key "TimeEntry[description]" is missing from JSON.');
        assert(json[r'description'] != null,
            'Required key "TimeEntry[description]" has a null value in JSON.');
        assert(json.containsKey(r'categoryId'),
            'Required key "TimeEntry[categoryId]" is missing from JSON.');
        assert(json.containsKey(r'startTime'),
            'Required key "TimeEntry[startTime]" is missing from JSON.');
        assert(json[r'startTime'] != null,
            'Required key "TimeEntry[startTime]" has a null value in JSON.');
        assert(json.containsKey(r'endTime'),
            'Required key "TimeEntry[endTime]" is missing from JSON.');
        assert(json.containsKey(r'source'),
            'Required key "TimeEntry[source]" is missing from JSON.');
        assert(json[r'source'] != null,
            'Required key "TimeEntry[source]" has a null value in JSON.');
        assert(json.containsKey(r'personIds'),
            'Required key "TimeEntry[personIds]" is missing from JSON.');
        assert(json[r'personIds'] != null,
            'Required key "TimeEntry[personIds]" has a null value in JSON.');
        return true;
      }());

      return TimeEntry(
        id: mapValueOfType<String>(json, r'id')!,
        description: mapValueOfType<String>(json, r'description')!,
        categoryId: mapValueOfType<String>(json, r'categoryId'),
        startTime: mapDateTime(json, r'startTime', r'')!,
        endTime: mapDateTime(json, r'endTime', r''),
        source_: EntrySource.fromJson(json[r'source'])!,
        personIds: json[r'personIds'] is Iterable
            ? (json[r'personIds'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<TimeEntry> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TimeEntry>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TimeEntry.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TimeEntry> mapFromJson(dynamic json) {
    final map = <String, TimeEntry>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TimeEntry.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TimeEntry-objects as value to a dart map
  static Map<String, List<TimeEntry>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<TimeEntry>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TimeEntry.listFromJson(
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
    'description',
    'categoryId',
    'startTime',
    'endTime',
    'source',
    'personIds',
  };
}
