//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreatePersonPlaceRequest {
  /// Returns a new [CreatePersonPlaceRequest] instance.
  CreatePersonPlaceRequest({
    this.id = const Optional.absent(),
    required this.label,
    required this.city,
    this.region = const Optional.absent(),
    this.country = const Optional.absent(),
    this.address = const Optional.absent(),
    this.cityId = const Optional.absent(),
    this.isPrimary = const Optional.absent(),
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> id;

  final String label;

  final String city;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> region;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> country;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<String?> address;

  /// The city the owner picked, as a GeoNames id from `GET /people/places/search`. Sending it is what makes the place pin on write: the server resolves the point from the cache that search filled, so no third party is on this path. Leave it out for a city that was only typed — offline, say — and the place lands unlocated for the geocoding batch to guess at.  Note what this request cannot carry: coordinates. The client says which city, never where it is.
  ///
  /// Minimum value: 1
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<int?> cityId;

  /// The first place is primary whether or not this is set: a person with exactly one city and no primary has no answer to \"where are they\".
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  final Optional<bool?> isPrimary;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreatePersonPlaceRequest &&
          other.id == id &&
          other.label == label &&
          other.city == city &&
          other.region == region &&
          other.country == country &&
          other.address == address &&
          other.cityId == cityId &&
          other.isPrimary == isPrimary;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id == null ? 0 : id!.hashCode) +
      (label.hashCode) +
      (city.hashCode) +
      (region == null ? 0 : region!.hashCode) +
      (country == null ? 0 : country!.hashCode) +
      (address == null ? 0 : address!.hashCode) +
      (cityId == null ? 0 : cityId!.hashCode) +
      (isPrimary == null ? 0 : isPrimary!.hashCode);

  @override
  String toString() =>
      'CreatePersonPlaceRequest[id=$id, label=$label, city=$city, region=$region, country=$country, address=$address, cityId=$cityId, isPrimary=$isPrimary]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id.isPresent) {
      final value = this.id.value;
      json[r'id'] = value;
    }
    json[r'label'] = this.label;
    json[r'city'] = this.city;
    if (this.region.isPresent) {
      final value = this.region.value;
      json[r'region'] = value;
    }
    if (this.country.isPresent) {
      final value = this.country.value;
      json[r'country'] = value;
    }
    if (this.address.isPresent) {
      final value = this.address.value;
      json[r'address'] = value;
    }
    if (this.cityId.isPresent) {
      final value = this.cityId.value;
      json[r'cityId'] = value;
    }
    if (this.isPrimary.isPresent) {
      final value = this.isPrimary.value;
      json[r'isPrimary'] = value;
    }
    return json;
  }

  /// Clones this instance of [CreatePersonPlaceRequest] and returns a new one where some of the
  /// properties have changed.
  CreatePersonPlaceRequest copyWith({
    Optional<String?>? id,
    String? label,
    String? city,
    Optional<String?>? region,
    Optional<String?>? country,
    Optional<String?>? address,
    Optional<int?>? cityId,
    Optional<bool?>? isPrimary,
  }) =>
      CreatePersonPlaceRequest(
        id: id ?? this.id,
        label: label ?? this.label,
        city: city ?? this.city,
        region: region ?? this.region,
        country: country ?? this.country,
        address: address ?? this.address,
        cityId: cityId ?? this.cityId,
        isPrimary: isPrimary ?? this.isPrimary,
      );

  /// Returns a new [CreatePersonPlaceRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreatePersonPlaceRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'label'),
            'Required key "CreatePersonPlaceRequest[label]" is missing from JSON.');
        assert(json[r'label'] != null,
            'Required key "CreatePersonPlaceRequest[label]" has a null value in JSON.');
        assert(json.containsKey(r'city'),
            'Required key "CreatePersonPlaceRequest[city]" is missing from JSON.');
        assert(json[r'city'] != null,
            'Required key "CreatePersonPlaceRequest[city]" has a null value in JSON.');
        return true;
      }());

      return CreatePersonPlaceRequest(
        id: json.containsKey(r'id')
            ? Optional.present(mapValueOfType<String>(json, r'id'))
            : const Optional.absent(),
        label: mapValueOfType<String>(json, r'label')!,
        city: mapValueOfType<String>(json, r'city')!,
        region: json.containsKey(r'region')
            ? Optional.present(mapValueOfType<String>(json, r'region'))
            : const Optional.absent(),
        country: json.containsKey(r'country')
            ? Optional.present(mapValueOfType<String>(json, r'country'))
            : const Optional.absent(),
        address: json.containsKey(r'address')
            ? Optional.present(mapValueOfType<String>(json, r'address'))
            : const Optional.absent(),
        cityId: json.containsKey(r'cityId')
            ? Optional.present(json[r'cityId'] == null
                ? null
                : int.parse('${json[r'cityId']}'))
            : const Optional.absent(),
        isPrimary: json.containsKey(r'isPrimary')
            ? Optional.present(mapValueOfType<bool>(json, r'isPrimary'))
            : const Optional.absent(),
      );
    }
    return null;
  }

  static List<CreatePersonPlaceRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreatePersonPlaceRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreatePersonPlaceRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreatePersonPlaceRequest> mapFromJson(dynamic json) {
    final map = <String, CreatePersonPlaceRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreatePersonPlaceRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreatePersonPlaceRequest-objects as value to a dart map
  static Map<String, List<CreatePersonPlaceRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreatePersonPlaceRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreatePersonPlaceRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'label',
    'city',
  };
}
