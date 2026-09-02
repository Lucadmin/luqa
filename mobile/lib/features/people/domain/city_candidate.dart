import 'package:flutter/foundation.dart';

/// A city the geocoder knows about, offered so the owner can say which one
/// they meant.
///
/// The reason this type exists at all: a name is not an answer. There are two
/// dozen Springfields and two famous Cambridges, and the app used to pick
/// between them by taking whatever a geocoder listed first. A candidate
/// carries the context a person needs to choose — the region, the country and
/// how big it is — plus the id that makes the choice stick.
@immutable
class CityCandidate {
  const CityCandidate({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.admin1,
    this.country,
    this.countryCode,
    this.timezone,
    this.population,
  });

  /// The GeoNames id, and the only field sent back when this one is chosen.
  final int id;

  final String name;

  /// State, province or Land. The line under the name in the picker, because
  /// it is what actually separates two rows reading "Springfield".
  final String? admin1;

  final String? country;
  final String? countryCode;

  final double latitude;
  final double longitude;

  final String? timezone;

  /// Shown beside each candidate: size is how a person recognises which of two
  /// same-named cities they meant.
  final int? population;

  /// "Bavaria, Germany" — the region and country as one line, skipping
  /// whichever half is missing rather than leaving a stray comma.
  String get where => [
    if (admin1 != null && admin1!.isNotEmpty) admin1,
    if (country != null && country!.isNotEmpty) country,
  ].join(', ');
}
