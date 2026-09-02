//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CityCandidate {
  /// Returns a new [CityCandidate] instance.
  CityCandidate({
    required this.id,
    required this.name,
    required this.admin1,
    required this.country,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.population,
    required this.featureCode,
  });

  /// The GeoNames id. Stable, and the only thing the client sends back when this candidate is chosen.
  final int id;

  final String name;

  /// State, province or Land. The single most useful field for telling Springfield, Illinois from Springfield, Missouri.
  final String? admin1;

  final String? country;

  final String? countryCode;

  final num latitude;

  final num longitude;

  final String? timezone;

  /// Shown beside each candidate, because size is how a person actually recognises which city was meant.
  final int? population;

  /// GeoNames' kind: PPLC for a national capital, PPLA for a regional one, PPL for an ordinary settlement.
  final String? featureCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CityCandidate &&
          other.id == id &&
          other.name == name &&
          other.admin1 == admin1 &&
          other.country == country &&
          other.countryCode == countryCode &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.timezone == timezone &&
          other.population == population &&
          other.featureCode == featureCode;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (name.hashCode) +
      (admin1 == null ? 0 : admin1!.hashCode) +
      (country == null ? 0 : country!.hashCode) +
      (countryCode == null ? 0 : countryCode!.hashCode) +
      (latitude.hashCode) +
      (longitude.hashCode) +
      (timezone == null ? 0 : timezone!.hashCode) +
      (population == null ? 0 : population!.hashCode) +
      (featureCode == null ? 0 : featureCode!.hashCode);

  @override
  String toString() =>
      'CityCandidate[id=$id, name=$name, admin1=$admin1, country=$country, countryCode=$countryCode, latitude=$latitude, longitude=$longitude, timezone=$timezone, population=$population, featureCode=$featureCode]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'name'] = this.name;
    if (this.admin1 != null) {
      json[r'admin1'] = this.admin1;
    } else {
      json[r'admin1'] = null;
    }
    if (this.country != null) {
      json[r'country'] = this.country;
    } else {
      json[r'country'] = null;
    }
    if (this.countryCode != null) {
      json[r'countryCode'] = this.countryCode;
    } else {
      json[r'countryCode'] = null;
    }
    json[r'latitude'] = this.latitude;
    json[r'longitude'] = this.longitude;
    if (this.timezone != null) {
      json[r'timezone'] = this.timezone;
    } else {
      json[r'timezone'] = null;
    }
    if (this.population != null) {
      json[r'population'] = this.population;
    } else {
      json[r'population'] = null;
    }
    if (this.featureCode != null) {
      json[r'featureCode'] = this.featureCode;
    } else {
      json[r'featureCode'] = null;
    }
    return json;
  }

  /// Clones this instance of [CityCandidate] and returns a new one where some of the
  /// properties have changed.
  CityCandidate copyWith({
    int? id,
    String? name,
    String? admin1,
    bool admin1SetToNull = false,
    String? country,
    bool countrySetToNull = false,
    String? countryCode,
    bool countryCodeSetToNull = false,
    num? latitude,
    num? longitude,
    String? timezone,
    bool timezoneSetToNull = false,
    int? population,
    bool populationSetToNull = false,
    String? featureCode,
    bool featureCodeSetToNull = false,
  }) =>
      CityCandidate(
        id: id ?? this.id,
        name: name ?? this.name,
        admin1: admin1SetToNull ? null : admin1 ?? this.admin1,
        country: countrySetToNull ? null : country ?? this.country,
        countryCode:
            countryCodeSetToNull ? null : countryCode ?? this.countryCode,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        timezone: timezoneSetToNull ? null : timezone ?? this.timezone,
        population: populationSetToNull ? null : population ?? this.population,
        featureCode:
            featureCodeSetToNull ? null : featureCode ?? this.featureCode,
      );

  /// Returns a new [CityCandidate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CityCandidate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "CityCandidate[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "CityCandidate[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "CityCandidate[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "CityCandidate[name]" has a null value in JSON.');
        assert(json.containsKey(r'admin1'),
            'Required key "CityCandidate[admin1]" is missing from JSON.');
        assert(json.containsKey(r'country'),
            'Required key "CityCandidate[country]" is missing from JSON.');
        assert(json.containsKey(r'countryCode'),
            'Required key "CityCandidate[countryCode]" is missing from JSON.');
        assert(json.containsKey(r'latitude'),
            'Required key "CityCandidate[latitude]" is missing from JSON.');
        assert(json[r'latitude'] != null,
            'Required key "CityCandidate[latitude]" has a null value in JSON.');
        assert(json.containsKey(r'longitude'),
            'Required key "CityCandidate[longitude]" is missing from JSON.');
        assert(json[r'longitude'] != null,
            'Required key "CityCandidate[longitude]" has a null value in JSON.');
        assert(json.containsKey(r'timezone'),
            'Required key "CityCandidate[timezone]" is missing from JSON.');
        assert(json.containsKey(r'population'),
            'Required key "CityCandidate[population]" is missing from JSON.');
        assert(json.containsKey(r'featureCode'),
            'Required key "CityCandidate[featureCode]" is missing from JSON.');
        return true;
      }());

      return CityCandidate(
        id: mapValueOfType<int>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        admin1: mapValueOfType<String>(json, r'admin1'),
        country: mapValueOfType<String>(json, r'country'),
        countryCode: mapValueOfType<String>(json, r'countryCode'),
        latitude: num.parse('${json[r'latitude']}'),
        longitude: num.parse('${json[r'longitude']}'),
        timezone: mapValueOfType<String>(json, r'timezone'),
        population: mapValueOfType<int>(json, r'population'),
        featureCode: mapValueOfType<String>(json, r'featureCode'),
      );
    }
    return null;
  }

  static List<CityCandidate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CityCandidate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CityCandidate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CityCandidate> mapFromJson(dynamic json) {
    final map = <String, CityCandidate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CityCandidate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CityCandidate-objects as value to a dart map
  static Map<String, List<CityCandidate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CityCandidate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CityCandidate.listFromJson(
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
    'name',
    'admin1',
    'country',
    'countryCode',
    'latitude',
    'longitude',
    'timezone',
    'population',
    'featureCode',
  };
}
