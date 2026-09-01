//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HabitLogDelta {
  /// Returns a new [HabitLogDelta] instance.
  HabitLogDelta({
    this.rows = const [],
    this.deleted = const [],
    this.cursor = const Optional.absent(),
    required this.hasMore,
  });

  /// Current state of everything created or changed.
  final List<HabitLog> rows;

  /// Always empty. A log is only ever written, never removed.
  final List<String> deleted;

  /// Where to resume. Null when this collection has never had a row, in which case the caller keeps the cursor it already had.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> cursor;

  /// True when the limit was reached and another page waits.
  final bool hasMore;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitLogDelta &&
          _deepEquality.equals(other.rows, rows) &&
          _deepEquality.equals(other.deleted, deleted) &&
          other.cursor == cursor &&
          other.hasMore == hasMore;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (rows.hashCode) +
      (deleted.hashCode) +
      (cursor == null ? 0 : cursor!.hashCode) +
      (hasMore.hashCode);

  @override
  String toString() =>
      'HabitLogDelta[rows=$rows, deleted=$deleted, cursor=$cursor, hasMore=$hasMore]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'rows'] = this.rows;
    json[r'deleted'] = this.deleted;
    if (this.cursor.isPresent) {
      final value = this.cursor.value;
      json[r'cursor'] = value;
    }
    json[r'hasMore'] = this.hasMore;
    return json;
  }

  /// Clones this instance of [HabitLogDelta] and returns a new one where some of the
  /// properties have changed.
  HabitLogDelta copyWith({
    List<HabitLog>? rows,
    List<String>? deleted,
    Optional<String?>? cursor,
    bool? hasMore,
  }) =>
      HabitLogDelta(
        rows: rows ?? this.rows,
        deleted: deleted ?? this.deleted,
        cursor: cursor ?? this.cursor,
        hasMore: hasMore ?? this.hasMore,
      );

  /// Returns a new [HabitLogDelta] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HabitLogDelta? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'rows'),
            'Required key "HabitLogDelta[rows]" is missing from JSON.');
        assert(json[r'rows'] != null,
            'Required key "HabitLogDelta[rows]" has a null value in JSON.');
        assert(json.containsKey(r'deleted'),
            'Required key "HabitLogDelta[deleted]" is missing from JSON.');
        assert(json[r'deleted'] != null,
            'Required key "HabitLogDelta[deleted]" has a null value in JSON.');
        assert(json.containsKey(r'hasMore'),
            'Required key "HabitLogDelta[hasMore]" is missing from JSON.');
        assert(json[r'hasMore'] != null,
            'Required key "HabitLogDelta[hasMore]" has a null value in JSON.');
        return true;
      }());

      return HabitLogDelta(
        rows: HabitLog.listFromJson(json[r'rows']),
        deleted: json[r'deleted'] is Iterable
            ? (json[r'deleted'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        cursor: json.containsKey(r'cursor')
            ? Optional.present(mapValueOfType<String>(json, r'cursor'))
            : const Optional.absent(),
        hasMore: mapValueOfType<bool>(json, r'hasMore')!,
      );
    }
    return null;
  }

  static List<HabitLogDelta> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HabitLogDelta>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HabitLogDelta.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HabitLogDelta> mapFromJson(dynamic json) {
    final map = <String, HabitLogDelta>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HabitLogDelta.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HabitLogDelta-objects as value to a dart map
  static Map<String, List<HabitLogDelta>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<HabitLogDelta>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HabitLogDelta.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'rows',
    'deleted',
    'hasMore',
  };
}
