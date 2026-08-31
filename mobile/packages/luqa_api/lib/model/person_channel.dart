//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PersonChannel {
  /// Returns a new [PersonChannel] instance.
  PersonChannel({
    required this.id,
    required this.kind,
    required this.label,
    required this.value,
    required this.source_,
  });

  final String id;

  final PersonChannelKindEnum kind;

  final String? label;

  final String value;

  final PersonChannelSource_Enum source_;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonChannel &&
          other.id == id &&
          other.kind == kind &&
          other.label == label &&
          other.value == value &&
          other.source_ == source_;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (kind.hashCode) +
      (label == null ? 0 : label!.hashCode) +
      (value.hashCode) +
      (source_.hashCode);

  @override
  String toString() =>
      'PersonChannel[id=$id, kind=$kind, label=$label, value=$value, source_=$source_]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'kind'] = this.kind;
    if (this.label != null) {
      json[r'label'] = this.label;
    } else {
      json[r'label'] = null;
    }
    json[r'value'] = this.value;
    json[r'source'] = this.source_;
    return json;
  }

  /// Clones this instance of [PersonChannel] and returns a new one where some of the
  /// properties have changed.
  PersonChannel copyWith({
    String? id,
    PersonChannelKindEnum? kind,
    String? label,
    bool labelSetToNull = false,
    String? value,
    PersonChannelSource_Enum? source_,
  }) =>
      PersonChannel(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        label: labelSetToNull ? null : label ?? this.label,
        value: value ?? this.value,
        source_: source_ ?? this.source_,
      );

  /// Returns a new [PersonChannel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PersonChannel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "PersonChannel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "PersonChannel[id]" has a null value in JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "PersonChannel[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "PersonChannel[kind]" has a null value in JSON.');
        assert(json.containsKey(r'label'),
            'Required key "PersonChannel[label]" is missing from JSON.');
        assert(json.containsKey(r'value'),
            'Required key "PersonChannel[value]" is missing from JSON.');
        assert(json[r'value'] != null,
            'Required key "PersonChannel[value]" has a null value in JSON.');
        assert(json.containsKey(r'source'),
            'Required key "PersonChannel[source]" is missing from JSON.');
        assert(json[r'source'] != null,
            'Required key "PersonChannel[source]" has a null value in JSON.');
        return true;
      }());

      return PersonChannel(
        id: mapValueOfType<String>(json, r'id')!,
        kind: PersonChannelKindEnum.fromJson(json[r'kind'])!,
        label: mapValueOfType<String>(json, r'label'),
        value: mapValueOfType<String>(json, r'value')!,
        source_: PersonChannelSource_Enum.fromJson(json[r'source'])!,
      );
    }
    return null;
  }

  static List<PersonChannel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PersonChannel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PersonChannel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PersonChannel> mapFromJson(dynamic json) {
    final map = <String, PersonChannel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PersonChannel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PersonChannel-objects as value to a dart map
  static Map<String, List<PersonChannel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PersonChannel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PersonChannel.listFromJson(
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
    'kind',
    'label',
    'value',
    'source',
  };
}

enum PersonChannelKindEnum {
  PHONE._(r'PHONE'),
  EMAIL._(r'EMAIL'),
  HANDLE._(r'HANDLE'),
  unknownDefaultOpenApi._(r'unknown_default_open_api'),
  ;

  /// Instantiate a new enum with the provided value.
  const PersonChannelKindEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PersonChannelKindEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PersonChannelKindEnum? fromJson(dynamic value) =>
      PersonChannelKindEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PersonChannelKindEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PersonChannelKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PersonChannelKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PersonChannelKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PersonChannelKindEnum] to String,
/// and [decode] dynamic data back to [PersonChannelKindEnum].
class PersonChannelKindEnumTypeTransformer {
  factory PersonChannelKindEnumTypeTransformer() =>
      _instance ??= const PersonChannelKindEnumTypeTransformer._();

  const PersonChannelKindEnumTypeTransformer._();

  String encode(PersonChannelKindEnum data) => data._value;

  /// Returns the instance of [PersonChannelKindEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PersonChannelKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PersonChannelKindEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'PHONE':
          return PersonChannelKindEnum.PHONE;
        case r'EMAIL':
          return PersonChannelKindEnum.EMAIL;
        case r'HANDLE':
          return PersonChannelKindEnum.HANDLE;
        case r'unknown_default_open_api':
          return PersonChannelKindEnum.unknownDefaultOpenApi;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PersonChannelKindEnumTypeTransformer? _instance;
}

enum PersonChannelSource_Enum {
  GOOGLE._(r'GOOGLE'),
  MANUAL._(r'MANUAL'),
  unknownDefaultOpenApi._(r'unknown_default_open_api'),
  ;

  /// Instantiate a new enum with the provided value.
  const PersonChannelSource_Enum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PersonChannelSource_Enum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PersonChannelSource_Enum? fromJson(dynamic value) =>
      PersonChannelSource_EnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PersonChannelSource_Enum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PersonChannelSource_Enum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PersonChannelSource_Enum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PersonChannelSource_Enum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PersonChannelSource_Enum] to String,
/// and [decode] dynamic data back to [PersonChannelSource_Enum].
class PersonChannelSource_EnumTypeTransformer {
  factory PersonChannelSource_EnumTypeTransformer() =>
      _instance ??= const PersonChannelSource_EnumTypeTransformer._();

  const PersonChannelSource_EnumTypeTransformer._();

  String encode(PersonChannelSource_Enum data) => data._value;

  /// Returns the instance of [PersonChannelSource_Enum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PersonChannelSource_Enum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PersonChannelSource_Enum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'GOOGLE':
          return PersonChannelSource_Enum.GOOGLE;
        case r'MANUAL':
          return PersonChannelSource_Enum.MANUAL;
        case r'unknown_default_open_api':
          return PersonChannelSource_Enum.unknownDefaultOpenApi;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PersonChannelSource_EnumTypeTransformer? _instance;
}
