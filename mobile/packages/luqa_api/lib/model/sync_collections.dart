//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SyncCollections {
  /// Returns a new [SyncCollections] instance.
  SyncCollections({
    this.categories = const Optional.absent(),
    this.people = const Optional.absent(),
    this.groups = const Optional.absent(),
    this.gymLocations = const Optional.absent(),
    this.exercises = const Optional.absent(),
    this.timeEntries = const Optional.absent(),
    this.sleepEntries = const Optional.absent(),
    this.expenses = const Optional.absent(),
    this.settlements = const Optional.absent(),
    this.gymSessions = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<CategoryDelta?> categories;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<PersonDelta?> people;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<PersonGroupDelta?> groups;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<GymLocationDelta?> gymLocations;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<GymExerciseDelta?> exercises;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<TimeEntryDelta?> timeEntries;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<SleepEntryDelta?> sleepEntries;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<ExpenseDelta?> expenses;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<SettlementDelta?> settlements;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<GymSessionDelta?> gymSessions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncCollections &&
          other.categories == categories &&
          other.people == people &&
          other.groups == groups &&
          other.gymLocations == gymLocations &&
          other.exercises == exercises &&
          other.timeEntries == timeEntries &&
          other.sleepEntries == sleepEntries &&
          other.expenses == expenses &&
          other.settlements == settlements &&
          other.gymSessions == gymSessions;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (categories == null ? 0 : categories!.hashCode) +
      (people == null ? 0 : people!.hashCode) +
      (groups == null ? 0 : groups!.hashCode) +
      (gymLocations == null ? 0 : gymLocations!.hashCode) +
      (exercises == null ? 0 : exercises!.hashCode) +
      (timeEntries == null ? 0 : timeEntries!.hashCode) +
      (sleepEntries == null ? 0 : sleepEntries!.hashCode) +
      (expenses == null ? 0 : expenses!.hashCode) +
      (settlements == null ? 0 : settlements!.hashCode) +
      (gymSessions == null ? 0 : gymSessions!.hashCode);

  @override
  String toString() =>
      'SyncCollections[categories=$categories, people=$people, groups=$groups, gymLocations=$gymLocations, exercises=$exercises, timeEntries=$timeEntries, sleepEntries=$sleepEntries, expenses=$expenses, settlements=$settlements, gymSessions=$gymSessions]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.categories.isPresent) {
      final value = this.categories.value;
      json[r'categories'] = value;
    }
    if (this.people.isPresent) {
      final value = this.people.value;
      json[r'people'] = value;
    }
    if (this.groups.isPresent) {
      final value = this.groups.value;
      json[r'groups'] = value;
    }
    if (this.gymLocations.isPresent) {
      final value = this.gymLocations.value;
      json[r'gymLocations'] = value;
    }
    if (this.exercises.isPresent) {
      final value = this.exercises.value;
      json[r'exercises'] = value;
    }
    if (this.timeEntries.isPresent) {
      final value = this.timeEntries.value;
      json[r'timeEntries'] = value;
    }
    if (this.sleepEntries.isPresent) {
      final value = this.sleepEntries.value;
      json[r'sleepEntries'] = value;
    }
    if (this.expenses.isPresent) {
      final value = this.expenses.value;
      json[r'expenses'] = value;
    }
    if (this.settlements.isPresent) {
      final value = this.settlements.value;
      json[r'settlements'] = value;
    }
    if (this.gymSessions.isPresent) {
      final value = this.gymSessions.value;
      json[r'gymSessions'] = value;
    }
    return json;
  }

  /// Clones this instance of [SyncCollections] and returns a new one where some of the
  /// properties have changed.
  SyncCollections copyWith({
    Optional<CategoryDelta?>? categories,
    Optional<PersonDelta?>? people,
    Optional<PersonGroupDelta?>? groups,
    Optional<GymLocationDelta?>? gymLocations,
    Optional<GymExerciseDelta?>? exercises,
    Optional<TimeEntryDelta?>? timeEntries,
    Optional<SleepEntryDelta?>? sleepEntries,
    Optional<ExpenseDelta?>? expenses,
    Optional<SettlementDelta?>? settlements,
    Optional<GymSessionDelta?>? gymSessions,
  }) =>
      SyncCollections(
        categories: categories ?? this.categories,
        people: people ?? this.people,
        groups: groups ?? this.groups,
        gymLocations: gymLocations ?? this.gymLocations,
        exercises: exercises ?? this.exercises,
        timeEntries: timeEntries ?? this.timeEntries,
        sleepEntries: sleepEntries ?? this.sleepEntries,
        expenses: expenses ?? this.expenses,
        settlements: settlements ?? this.settlements,
        gymSessions: gymSessions ?? this.gymSessions,
      );

  /// Returns a new [SyncCollections] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SyncCollections? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return SyncCollections(
        categories: json.containsKey(r'categories')
            ? Optional.present(CategoryDelta.fromJson(json[r'categories']))
            : const Optional.absent(),
        people: json.containsKey(r'people')
            ? Optional.present(PersonDelta.fromJson(json[r'people']))
            : const Optional.absent(),
        groups: json.containsKey(r'groups')
            ? Optional.present(PersonGroupDelta.fromJson(json[r'groups']))
            : const Optional.absent(),
        gymLocations: json.containsKey(r'gymLocations')
            ? Optional.present(GymLocationDelta.fromJson(json[r'gymLocations']))
            : const Optional.absent(),
        exercises: json.containsKey(r'exercises')
            ? Optional.present(GymExerciseDelta.fromJson(json[r'exercises']))
            : const Optional.absent(),
        timeEntries: json.containsKey(r'timeEntries')
            ? Optional.present(TimeEntryDelta.fromJson(json[r'timeEntries']))
            : const Optional.absent(),
        sleepEntries: json.containsKey(r'sleepEntries')
            ? Optional.present(SleepEntryDelta.fromJson(json[r'sleepEntries']))
            : const Optional.absent(),
        expenses: json.containsKey(r'expenses')
            ? Optional.present(ExpenseDelta.fromJson(json[r'expenses']))
            : const Optional.absent(),
        settlements: json.containsKey(r'settlements')
            ? Optional.present(SettlementDelta.fromJson(json[r'settlements']))
            : const Optional.absent(),
        gymSessions: json.containsKey(r'gymSessions')
            ? Optional.present(GymSessionDelta.fromJson(json[r'gymSessions']))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<SyncCollections> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SyncCollections>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SyncCollections.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SyncCollections> mapFromJson(dynamic json) {
    final map = <String, SyncCollections>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SyncCollections.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SyncCollections-objects as value to a dart map
  static Map<String, List<SyncCollections>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SyncCollections>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SyncCollections.listFromJson(
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
