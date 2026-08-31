//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateSettlementRequest {
  /// Returns a new [CreateSettlementRequest] instance.
  CreateSettlementRequest({
    this.id = const Optional.absent(),
    required this.personId,
    required this.amountCents,
    this.direction = const Optional.absent(),
    this.date = const Optional.absent(),
    this.notes = const Optional.absent(),
  });

  /// Client-minted identity, so a payback recorded offline is not double-counted when the create is retried.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> id;

  final String personId;

  /// Minimum value: 1
  /// Maximum value: 100000000
  final int amountCents;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<SettlementDirection?> direction;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> date;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> notes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateSettlementRequest &&
          other.id == id &&
          other.personId == personId &&
          other.amountCents == amountCents &&
          other.direction == direction &&
          other.date == date &&
          other.notes == notes;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id == null ? 0 : id!.hashCode) +
      (personId.hashCode) +
      (amountCents.hashCode) +
      (direction == null ? 0 : direction!.hashCode) +
      (date == null ? 0 : date!.hashCode) +
      (notes == null ? 0 : notes!.hashCode);

  @override
  String toString() =>
      'CreateSettlementRequest[id=$id, personId=$personId, amountCents=$amountCents, direction=$direction, date=$date, notes=$notes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id.isPresent) {
      final value = this.id.value;
      json[r'id'] = value;
    }
    json[r'personId'] = this.personId;
    json[r'amountCents'] = this.amountCents;
    if (this.direction.isPresent) {
      final value = this.direction.value;
      json[r'direction'] = value;
    }
    if (this.date.isPresent) {
      final value = this.date.value;
      json[r'date'] = value;
    }
    if (this.notes.isPresent) {
      final value = this.notes.value;
      json[r'notes'] = value;
    }
    return json;
  }

  /// Clones this instance of [CreateSettlementRequest] and returns a new one where some of the
  /// properties have changed.
  CreateSettlementRequest copyWith({
    Optional<String?>? id,
    String? personId,
    int? amountCents,
    Optional<SettlementDirection?>? direction,
    Optional<String?>? date,
    Optional<String?>? notes,
  }) =>
      CreateSettlementRequest(
        id: id ?? this.id,
        personId: personId ?? this.personId,
        amountCents: amountCents ?? this.amountCents,
        direction: direction ?? this.direction,
        date: date ?? this.date,
        notes: notes ?? this.notes,
      );

  /// Returns a new [CreateSettlementRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateSettlementRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'personId'),
            'Required key "CreateSettlementRequest[personId]" is missing from JSON.');
        assert(json[r'personId'] != null,
            'Required key "CreateSettlementRequest[personId]" has a null value in JSON.');
        assert(json.containsKey(r'amountCents'),
            'Required key "CreateSettlementRequest[amountCents]" is missing from JSON.');
        assert(json[r'amountCents'] != null,
            'Required key "CreateSettlementRequest[amountCents]" has a null value in JSON.');
        return true;
      }());

      return CreateSettlementRequest(
        id: json.containsKey(r'id')
            ? Optional.present(mapValueOfType<String>(json, r'id'))
            : const Optional.absent(),
        personId: mapValueOfType<String>(json, r'personId')!,
        amountCents: mapValueOfType<int>(json, r'amountCents')!,
        direction: json.containsKey(r'direction')
            ? Optional.present(SettlementDirection.fromJson(json[r'direction']))
            : const Optional.absent(),
        date: json.containsKey(r'date')
            ? Optional.present(mapValueOfType<String>(json, r'date'))
            : const Optional.absent(),
        notes: json.containsKey(r'notes')
            ? Optional.present(mapValueOfType<String>(json, r'notes'))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<CreateSettlementRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreateSettlementRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateSettlementRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateSettlementRequest> mapFromJson(dynamic json) {
    final map = <String, CreateSettlementRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateSettlementRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateSettlementRequest-objects as value to a dart map
  static Map<String, List<CreateSettlementRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreateSettlementRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateSettlementRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'personId',
    'amountCents',
  };
}
