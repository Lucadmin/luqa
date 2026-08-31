//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GymSessionExercise {
  /// Returns a new [GymSessionExercise] instance.
  GymSessionExercise({
    required this.id,
    required this.exerciseId,
    required this.name,
    required this.order,
    required this.raw,
    required this.notes,
    this.sets = const [],
  });

  final String id;

  final String exerciseId;

  final String name;

  final int order;

  final String raw;

  final String notes;

  final List<GymSet> sets;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymSessionExercise &&
          other.id == id &&
          other.exerciseId == exerciseId &&
          other.name == name &&
          other.order == order &&
          other.raw == raw &&
          other.notes == notes &&
          _deepEquality.equals(other.sets, sets);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (exerciseId.hashCode) +
      (name.hashCode) +
      (order.hashCode) +
      (raw.hashCode) +
      (notes.hashCode) +
      (sets.hashCode);

  @override
  String toString() =>
      'GymSessionExercise[id=$id, exerciseId=$exerciseId, name=$name, order=$order, raw=$raw, notes=$notes, sets=$sets]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'exerciseId'] = this.exerciseId;
    json[r'name'] = this.name;
    json[r'order'] = this.order;
    json[r'raw'] = this.raw;
    json[r'notes'] = this.notes;
    json[r'sets'] = this.sets;
    return json;
  }

  /// Clones this instance of [GymSessionExercise] and returns a new one where some of the
  /// properties have changed.
  GymSessionExercise copyWith({
    String? id,
    String? exerciseId,
    String? name,
    int? order,
    String? raw,
    String? notes,
    List<GymSet>? sets,
  }) =>
      GymSessionExercise(
        id: id ?? this.id,
        exerciseId: exerciseId ?? this.exerciseId,
        name: name ?? this.name,
        order: order ?? this.order,
        raw: raw ?? this.raw,
        notes: notes ?? this.notes,
        sets: sets ?? this.sets,
      );

  /// Returns a new [GymSessionExercise] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GymSessionExercise? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "GymSessionExercise[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "GymSessionExercise[id]" has a null value in JSON.');
        assert(json.containsKey(r'exerciseId'),
            'Required key "GymSessionExercise[exerciseId]" is missing from JSON.');
        assert(json[r'exerciseId'] != null,
            'Required key "GymSessionExercise[exerciseId]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "GymSessionExercise[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "GymSessionExercise[name]" has a null value in JSON.');
        assert(json.containsKey(r'order'),
            'Required key "GymSessionExercise[order]" is missing from JSON.');
        assert(json[r'order'] != null,
            'Required key "GymSessionExercise[order]" has a null value in JSON.');
        assert(json.containsKey(r'raw'),
            'Required key "GymSessionExercise[raw]" is missing from JSON.');
        assert(json[r'raw'] != null,
            'Required key "GymSessionExercise[raw]" has a null value in JSON.');
        assert(json.containsKey(r'notes'),
            'Required key "GymSessionExercise[notes]" is missing from JSON.');
        assert(json[r'notes'] != null,
            'Required key "GymSessionExercise[notes]" has a null value in JSON.');
        assert(json.containsKey(r'sets'),
            'Required key "GymSessionExercise[sets]" is missing from JSON.');
        assert(json[r'sets'] != null,
            'Required key "GymSessionExercise[sets]" has a null value in JSON.');
        return true;
      }());

      return GymSessionExercise(
        id: mapValueOfType<String>(json, r'id')!,
        exerciseId: mapValueOfType<String>(json, r'exerciseId')!,
        name: mapValueOfType<String>(json, r'name')!,
        order: mapValueOfType<int>(json, r'order')!,
        raw: mapValueOfType<String>(json, r'raw')!,
        notes: mapValueOfType<String>(json, r'notes')!,
        sets: GymSet.listFromJson(json[r'sets']),
      );
    }
    return null;
  }

  static List<GymSessionExercise> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GymSessionExercise>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GymSessionExercise.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GymSessionExercise> mapFromJson(dynamic json) {
    final map = <String, GymSessionExercise>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GymSessionExercise.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GymSessionExercise-objects as value to a dart map
  static Map<String, List<GymSessionExercise>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GymSessionExercise>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GymSessionExercise.listFromJson(
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
    'exerciseId',
    'name',
    'order',
    'raw',
    'notes',
    'sets',
  };
}
