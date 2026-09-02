//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PersonPlace {
  /// Returns a new [PersonPlace] instance.
  PersonPlace({
    required this.id,
    required this.label,
    required this.city,
    required this.region,
    required this.country,
    required this.address,
    required this.cityId,
    required this.timezone,
    required this.latitude,
    required this.longitude,
    required this.isPrimary,
    required this.source_,
  });

  final String id;

  /// What this place is to them — \"Home\", \"Parents\", \"Summer\".
  final String label;

  final String city;

  /// The first-level administrative area — state, province, Land. What tells two cities of the same name apart in a list.
  final String? region;

  final String? country;

  /// Kept for reference. Never the thing that gets plotted.
  final String? address;

  /// The GeoNames id of the city that was chosen from the search list. Null for a name that was only typed — offline, or imported from a contact book — which is the place the geocoding batch is for. Two places sharing this id are the same city whatever their names look like, which is how two Cambridges stay two pins.
  final int? cityId;

  /// The IANA zone of that city, e.g. \"Europe/Berlin\".
  final String? timezone;

  /// City centroid. Present from the start for a chosen city; null for a typed one until the batch resolves it — a place that lists but does not yet pin.
  final num? latitude;

  final num? longitude;

  final bool isPrimary;

  final PersonPlaceSource_Enum source_;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonPlace &&
          other.id == id &&
          other.label == label &&
          other.city == city &&
          other.region == region &&
          other.country == country &&
          other.address == address &&
          other.cityId == cityId &&
          other.timezone == timezone &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.isPrimary == isPrimary &&
          other.source_ == source_;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (label.hashCode) +
      (city.hashCode) +
      (region == null ? 0 : region!.hashCode) +
      (country == null ? 0 : country!.hashCode) +
      (address == null ? 0 : address!.hashCode) +
      (cityId == null ? 0 : cityId!.hashCode) +
      (timezone == null ? 0 : timezone!.hashCode) +
      (latitude == null ? 0 : latitude!.hashCode) +
      (longitude == null ? 0 : longitude!.hashCode) +
      (isPrimary.hashCode) +
      (source_.hashCode);

  @override
  String toString() =>
      'PersonPlace[id=$id, label=$label, city=$city, region=$region, country=$country, address=$address, cityId=$cityId, timezone=$timezone, latitude=$latitude, longitude=$longitude, isPrimary=$isPrimary, source_=$source_]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'label'] = this.label;
    json[r'city'] = this.city;
    if (this.region != null) {
      json[r'region'] = this.region;
    } else {
      json[r'region'] = null;
    }
    if (this.country != null) {
      json[r'country'] = this.country;
    } else {
      json[r'country'] = null;
    }
    if (this.address != null) {
      json[r'address'] = this.address;
    } else {
      json[r'address'] = null;
    }
    if (this.cityId != null) {
      json[r'cityId'] = this.cityId;
    } else {
      json[r'cityId'] = null;
    }
    if (this.timezone != null) {
      json[r'timezone'] = this.timezone;
    } else {
      json[r'timezone'] = null;
    }
    if (this.latitude != null) {
      json[r'latitude'] = this.latitude;
    } else {
      json[r'latitude'] = null;
    }
    if (this.longitude != null) {
      json[r'longitude'] = this.longitude;
    } else {
      json[r'longitude'] = null;
    }
    json[r'isPrimary'] = this.isPrimary;
    json[r'source'] = this.source_;
    return json;
  }

  /// Clones this instance of [PersonPlace] and returns a new one where some of the
  /// properties have changed.
  PersonPlace copyWith({
    String? id,
    String? label,
    String? city,
    String? region,
    bool regionSetToNull = false,
    String? country,
    bool countrySetToNull = false,
    String? address,
    bool addressSetToNull = false,
    int? cityId,
    bool cityIdSetToNull = false,
    String? timezone,
    bool timezoneSetToNull = false,
    num? latitude,
    bool latitudeSetToNull = false,
    num? longitude,
    bool longitudeSetToNull = false,
    bool? isPrimary,
    PersonPlaceSource_Enum? source_,
  }) =>
      PersonPlace(
        id: id ?? this.id,
        label: label ?? this.label,
        city: city ?? this.city,
        region: regionSetToNull ? null : region ?? this.region,
        country: countrySetToNull ? null : country ?? this.country,
        address: addressSetToNull ? null : address ?? this.address,
        cityId: cityIdSetToNull ? null : cityId ?? this.cityId,
        timezone: timezoneSetToNull ? null : timezone ?? this.timezone,
        latitude: latitudeSetToNull ? null : latitude ?? this.latitude,
        longitude: longitudeSetToNull ? null : longitude ?? this.longitude,
        isPrimary: isPrimary ?? this.isPrimary,
        source_: source_ ?? this.source_,
      );

  /// Returns a new [PersonPlace] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PersonPlace? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "PersonPlace[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "PersonPlace[id]" has a null value in JSON.');
        assert(json.containsKey(r'label'),
            'Required key "PersonPlace[label]" is missing from JSON.');
        assert(json[r'label'] != null,
            'Required key "PersonPlace[label]" has a null value in JSON.');
        assert(json.containsKey(r'city'),
            'Required key "PersonPlace[city]" is missing from JSON.');
        assert(json[r'city'] != null,
            'Required key "PersonPlace[city]" has a null value in JSON.');
        assert(json.containsKey(r'region'),
            'Required key "PersonPlace[region]" is missing from JSON.');
        assert(json.containsKey(r'country'),
            'Required key "PersonPlace[country]" is missing from JSON.');
        assert(json.containsKey(r'address'),
            'Required key "PersonPlace[address]" is missing from JSON.');
        assert(json.containsKey(r'cityId'),
            'Required key "PersonPlace[cityId]" is missing from JSON.');
        assert(json.containsKey(r'timezone'),
            'Required key "PersonPlace[timezone]" is missing from JSON.');
        assert(json.containsKey(r'latitude'),
            'Required key "PersonPlace[latitude]" is missing from JSON.');
        assert(json.containsKey(r'longitude'),
            'Required key "PersonPlace[longitude]" is missing from JSON.');
        assert(json.containsKey(r'isPrimary'),
            'Required key "PersonPlace[isPrimary]" is missing from JSON.');
        assert(json[r'isPrimary'] != null,
            'Required key "PersonPlace[isPrimary]" has a null value in JSON.');
        assert(json.containsKey(r'source'),
            'Required key "PersonPlace[source]" is missing from JSON.');
        assert(json[r'source'] != null,
            'Required key "PersonPlace[source]" has a null value in JSON.');
        return true;
      }());

      return PersonPlace(
        id: mapValueOfType<String>(json, r'id')!,
        label: mapValueOfType<String>(json, r'label')!,
        city: mapValueOfType<String>(json, r'city')!,
        region: mapValueOfType<String>(json, r'region'),
        country: mapValueOfType<String>(json, r'country'),
        address: mapValueOfType<String>(json, r'address'),
        cityId: mapValueOfType<int>(json, r'cityId'),
        timezone: mapValueOfType<String>(json, r'timezone'),
        latitude: json[r'latitude'] == null
            ? null
            : num.parse('${json[r'latitude']}'),
        longitude: json[r'longitude'] == null
            ? null
            : num.parse('${json[r'longitude']}'),
        isPrimary: mapValueOfType<bool>(json, r'isPrimary')!,
        source_: PersonPlaceSource_Enum.fromJson(json[r'source'])!,
      );
    }
    return null;
  }

  static List<PersonPlace> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PersonPlace>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PersonPlace.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PersonPlace> mapFromJson(dynamic json) {
    final map = <String, PersonPlace>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PersonPlace.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PersonPlace-objects as value to a dart map
  static Map<String, List<PersonPlace>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PersonPlace>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PersonPlace.listFromJson(
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
    'label',
    'city',
    'region',
    'country',
    'address',
    'cityId',
    'timezone',
    'latitude',
    'longitude',
    'isPrimary',
    'source',
  };
}

enum PersonPlaceSource_Enum {
  GOOGLE._(r'GOOGLE'),
  MANUAL._(r'MANUAL'),
  unknownDefaultOpenApi._(r'unknown_default_open_api'),
  ;

  /// Instantiate a new enum with the provided value.
  const PersonPlaceSource_Enum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PersonPlaceSource_Enum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PersonPlaceSource_Enum? fromJson(dynamic value) =>
      PersonPlaceSource_EnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PersonPlaceSource_Enum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PersonPlaceSource_Enum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PersonPlaceSource_Enum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PersonPlaceSource_Enum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PersonPlaceSource_Enum] to String,
/// and [decode] dynamic data back to [PersonPlaceSource_Enum].
class PersonPlaceSource_EnumTypeTransformer {
  factory PersonPlaceSource_EnumTypeTransformer() =>
      _instance ??= const PersonPlaceSource_EnumTypeTransformer._();

  const PersonPlaceSource_EnumTypeTransformer._();

  String encode(PersonPlaceSource_Enum data) => data._value;

  /// Returns the instance of [PersonPlaceSource_Enum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PersonPlaceSource_Enum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PersonPlaceSource_Enum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'GOOGLE':
          return PersonPlaceSource_Enum.GOOGLE;
        case r'MANUAL':
          return PersonPlaceSource_Enum.MANUAL;
        case r'unknown_default_open_api':
          return PersonPlaceSource_Enum.unknownDefaultOpenApi;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PersonPlaceSource_EnumTypeTransformer? _instance;
}
