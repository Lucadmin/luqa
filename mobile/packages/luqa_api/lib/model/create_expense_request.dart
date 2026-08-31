//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateExpenseRequest {
  /// Returns a new [CreateExpenseRequest] instance.
  CreateExpenseRequest({
    this.id = const Optional.absent(),
    this.description = const Optional.absent(),
    required this.amountCents,
    this.date = const Optional.absent(),
    this.paidByPersonId = const Optional.absent(),
    this.groupId = const Optional.absent(),
    this.splitMode = const Optional.absent(),
    this.includeMe = const Optional.absent(),
    this.participants = const Optional.present(const []),
    this.notes = const Optional.absent(),
  });

  /// Client-minted identity for the bill, so one split at the table with no signal can still be edited and referred to. Supplying it makes the create idempotent.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> id;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> description;

  /// Minimum value: 1
  /// Maximum value: 100000000
  final int amountCents;

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
  final Optional<String?> paidByPersonId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> groupId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<SplitMode?> splitMode;

  /// EQUAL mode: whether the user is one of the equal parts.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> includeMe;

  final Optional<List<ExpenseParticipantInput>?> participants;

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
      other is CreateExpenseRequest &&
          other.id == id &&
          other.description == description &&
          other.amountCents == amountCents &&
          other.date == date &&
          other.paidByPersonId == paidByPersonId &&
          other.groupId == groupId &&
          other.splitMode == splitMode &&
          other.includeMe == includeMe &&
          _deepEquality.equals(other.participants, participants) &&
          other.notes == notes;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id == null ? 0 : id!.hashCode) +
      (description == null ? 0 : description!.hashCode) +
      (amountCents.hashCode) +
      (date == null ? 0 : date!.hashCode) +
      (paidByPersonId == null ? 0 : paidByPersonId!.hashCode) +
      (groupId == null ? 0 : groupId!.hashCode) +
      (splitMode == null ? 0 : splitMode!.hashCode) +
      (includeMe == null ? 0 : includeMe!.hashCode) +
      (participants.hashCode) +
      (notes == null ? 0 : notes!.hashCode);

  @override
  String toString() =>
      'CreateExpenseRequest[id=$id, description=$description, amountCents=$amountCents, date=$date, paidByPersonId=$paidByPersonId, groupId=$groupId, splitMode=$splitMode, includeMe=$includeMe, participants=$participants, notes=$notes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id.isPresent) {
      final value = this.id.value;
      json[r'id'] = value;
    }
    if (this.description.isPresent) {
      final value = this.description.value;
      json[r'description'] = value;
    }
    json[r'amountCents'] = this.amountCents;
    if (this.date.isPresent) {
      final value = this.date.value;
      json[r'date'] = value;
    }
    if (this.paidByPersonId.isPresent) {
      final value = this.paidByPersonId.value;
      json[r'paidByPersonId'] = value;
    }
    if (this.groupId.isPresent) {
      final value = this.groupId.value;
      json[r'groupId'] = value;
    }
    if (this.splitMode.isPresent) {
      final value = this.splitMode.value;
      json[r'splitMode'] = value;
    }
    if (this.includeMe.isPresent) {
      final value = this.includeMe.value;
      json[r'includeMe'] = value;
    }
    if (this.participants.isPresent) {
      final value = this.participants.value;
      json[r'participants'] = value;
    }
    if (this.notes.isPresent) {
      final value = this.notes.value;
      json[r'notes'] = value;
    }
    return json;
  }

  /// Clones this instance of [CreateExpenseRequest] and returns a new one where some of the
  /// properties have changed.
  CreateExpenseRequest copyWith({
    Optional<String?>? id,
    Optional<String?>? description,
    int? amountCents,
    Optional<String?>? date,
    Optional<String?>? paidByPersonId,
    Optional<String?>? groupId,
    Optional<SplitMode?>? splitMode,
    Optional<bool?>? includeMe,
    Optional<List<ExpenseParticipantInput>?>? participants,
    Optional<String?>? notes,
  }) =>
      CreateExpenseRequest(
        id: id ?? this.id,
        description: description ?? this.description,
        amountCents: amountCents ?? this.amountCents,
        date: date ?? this.date,
        paidByPersonId: paidByPersonId ?? this.paidByPersonId,
        groupId: groupId ?? this.groupId,
        splitMode: splitMode ?? this.splitMode,
        includeMe: includeMe ?? this.includeMe,
        participants: participants ?? this.participants,
        notes: notes ?? this.notes,
      );

  /// Returns a new [CreateExpenseRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateExpenseRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'amountCents'),
            'Required key "CreateExpenseRequest[amountCents]" is missing from JSON.');
        assert(json[r'amountCents'] != null,
            'Required key "CreateExpenseRequest[amountCents]" has a null value in JSON.');
        return true;
      }());

      return CreateExpenseRequest(
        id: json.containsKey(r'id')
            ? Optional.present(mapValueOfType<String>(json, r'id'))
            : const Optional.absent(),
        description: json.containsKey(r'description')
            ? Optional.present(mapValueOfType<String>(json, r'description'))
            : const Optional.absent(),
        amountCents: mapValueOfType<int>(json, r'amountCents')!,
        date: json.containsKey(r'date')
            ? Optional.present(mapValueOfType<String>(json, r'date'))
            : const Optional.absent(),
        paidByPersonId: json.containsKey(r'paidByPersonId')
            ? Optional.present(mapValueOfType<String>(json, r'paidByPersonId'))
            : const Optional.absent(),
        groupId: json.containsKey(r'groupId')
            ? Optional.present(mapValueOfType<String>(json, r'groupId'))
            : const Optional.absent(),
        splitMode: json.containsKey(r'splitMode')
            ? Optional.present(SplitMode.fromJson(json[r'splitMode']))
            : const Optional.absent(),
        includeMe: json.containsKey(r'includeMe')
            ? Optional.present(mapValueOfType<bool>(json, r'includeMe'))
            : const Optional.absent(),
        participants: json.containsKey(r'participants')
            ? Optional.present(
                ExpenseParticipantInput.listFromJson(json[r'participants']))
            : const Optional.absent(),
        notes: json.containsKey(r'notes')
            ? Optional.present(mapValueOfType<String>(json, r'notes'))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<CreateExpenseRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreateExpenseRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateExpenseRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateExpenseRequest> mapFromJson(dynamic json) {
    final map = <String, CreateExpenseRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateExpenseRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateExpenseRequest-objects as value to a dart map
  static Map<String, List<CreateExpenseRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreateExpenseRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateExpenseRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'amountCents',
  };
}
