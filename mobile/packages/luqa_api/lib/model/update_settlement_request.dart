//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UpdateSettlementRequest {
  /// Returns a new [UpdateSettlementRequest] instance.
  UpdateSettlementRequest({
    this.amountCents = const Optional.absent(),
    this.direction = const Optional.absent(),
    this.date = const Optional.absent(),
    this.notes = const Optional.absent(),
  });

  /// Minimum value: 1
  /// Maximum value: 100000000
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> amountCents;

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
      other is UpdateSettlementRequest &&
          other.amountCents == amountCents &&
          other.direction == direction &&
          other.date == date &&
          other.notes == notes;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (amountCents == null ? 0 : amountCents!.hashCode) +
      (direction == null ? 0 : direction!.hashCode) +
      (date == null ? 0 : date!.hashCode) +
      (notes == null ? 0 : notes!.hashCode);

  @override
  String toString() =>
      'UpdateSettlementRequest[amountCents=$amountCents, direction=$direction, date=$date, notes=$notes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.amountCents.isPresent) {
      final value = this.amountCents.value;
      json[r'amountCents'] = value;
    }
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

  /// Clones this instance of [UpdateSettlementRequest] and returns a new one where some of the
  /// properties have changed.
  UpdateSettlementRequest copyWith({
    Optional<int?>? amountCents,
    Optional<SettlementDirection?>? direction,
    Optional<String?>? date,
    Optional<String?>? notes,
  }) =>
      UpdateSettlementRequest(
        amountCents: amountCents ?? this.amountCents,
        direction: direction ?? this.direction,
        date: date ?? this.date,
        notes: notes ?? this.notes,
      );

  /// Returns a new [UpdateSettlementRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateSettlementRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UpdateSettlementRequest(
        amountCents: json.containsKey(r'amountCents')
            ? Optional.present(json[r'amountCents'] == null
                ? null
                : int.parse('${json[r'amountCents']}'))
            : const Optional.absent(),
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

  static List<UpdateSettlementRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UpdateSettlementRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateSettlementRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateSettlementRequest> mapFromJson(dynamic json) {
    final map = <String, UpdateSettlementRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateSettlementRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateSettlementRequest-objects as value to a dart map
  static Map<String, List<UpdateSettlementRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UpdateSettlementRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateSettlementRequest.listFromJson(
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
