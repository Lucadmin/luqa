import 'package:flutter/foundation.dart';

/// A person in Luqa's life, and everything the app knows about them.
///
/// There is exactly one `Person`. Money owned this row first and still owns
/// the ledger hanging off it, but identity is not money's: the same friend
/// appears on a bill, on a timeline entry, and on a map, and a second contact
/// model would mean two names for one person and an archive state that
/// disagrees with itself.
///
/// The profile fields are all optional and all default to empty. Somebody who
/// has only ever appeared on a restaurant bill is a complete `Person`; the
/// rest of the record accumulates if and when it is worth writing down.
@immutable
class Person {
  const Person({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.emoji,
    required this.defaultPercent,
    required this.order,
    required this.archived,
    this.nickname,
    this.photoUrl,
    this.birthday,
    this.cadenceDays,
    this.lastSeenAt,
    this.googleResourceName,
    this.places = const [],
    this.channels = const [],
    this.notes = const [],
    this.gifts = const [],
  });

  final String id;
  final String name;
  final int colorValue;

  /// An optional glyph on the avatar, e.g. "🧡".
  final String? emoji;

  /// The cut of a bill this person usually carries, in whole percent. Null
  /// means share equally with everyone else on it — right for most people.
  final int? defaultPercent;

  final int order;
  final bool archived;

  /// What Luca actually calls them, when it is not their contact-book name.
  final String? nickname;

  final String? photoUrl;

  final Birthday? birthday;

  /// How often being in touch is worth aiming for. Null for most people, and
  /// null means they never appear in an overdue list — a contact book where
  /// everyone is a duty is a contact book nobody opens.
  final int? cadenceDays;

  /// The last time they were actually seen. Set by hand, or derived from a
  /// tagged timeline entry or a shared bill, whichever is newest.
  final DateTime? lastSeenAt;

  /// The People API resource this row is linked to, e.g. "people/c1234".
  /// Null for someone who exists only in Luqa.
  final String? googleResourceName;

  final List<PersonPlace> places;
  final List<PersonChannel> channels;
  final List<PersonNote> notes;
  final List<GiftIdea> gifts;

  /// The name to show: the nickname when there is one, because that is the
  /// name the owner thinks in.
  String get displayName =>
      nickname != null && nickname!.trim().isNotEmpty ? nickname! : name;

  bool get isLinkedToGoogle => googleResourceName != null;

  /// Where they are, for the purpose of "who is in this city". The primary
  /// place if one is marked, otherwise the first one recorded.
  PersonPlace? get primaryPlace {
    if (places.isEmpty) return null;
    for (final place in places) {
      if (place.isPrimary) return place;
    }
    return places.first;
  }

  /// Notes worth showing first: pinned ones, then newest.
  List<PersonNote> get orderedNotes {
    final sorted = [...notes]
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    return sorted;
  }

  /// Gift ideas still on the table. A given one stays on the record — it is
  /// how you avoid giving the same book twice — but it stops being a plan.
  List<GiftIdea> get openGifts => [
    for (final gift in gifts)
      if (gift.givenAt == null) gift,
  ];

  Person copyWith({
    String? name,
    int? colorValue,
    String? emoji,
    bool clearEmoji = false,
    int? defaultPercent,
    bool clearDefaultPercent = false,
    int? order,
    bool? archived,
    String? nickname,
    bool clearNickname = false,
    String? photoUrl,
    Birthday? birthday,
    bool clearBirthday = false,
    int? cadenceDays,
    bool clearCadence = false,
    DateTime? lastSeenAt,
    bool clearLastSeen = false,
    String? googleResourceName,
    List<PersonPlace>? places,
    List<PersonChannel>? channels,
    List<PersonNote>? notes,
    List<GiftIdea>? gifts,
  }) => Person(
    id: id,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    emoji: clearEmoji ? null : emoji ?? this.emoji,
    defaultPercent: clearDefaultPercent
        ? null
        : defaultPercent ?? this.defaultPercent,
    order: order ?? this.order,
    archived: archived ?? this.archived,
    nickname: clearNickname ? null : nickname ?? this.nickname,
    photoUrl: photoUrl ?? this.photoUrl,
    birthday: clearBirthday ? null : birthday ?? this.birthday,
    cadenceDays: clearCadence ? null : cadenceDays ?? this.cadenceDays,
    lastSeenAt: clearLastSeen ? null : lastSeenAt ?? this.lastSeenAt,
    googleResourceName: googleResourceName ?? this.googleResourceName,
    places: places ?? this.places,
    channels: channels ?? this.channels,
    notes: notes ?? this.notes,
    gifts: gifts ?? this.gifts,
  );
}

/// A birthday, stored as the parts a contact book actually has.
///
/// Deliberately not a `DateTime`. Most contacts carry a day and a month and no
/// year at all, and forcing a year in means inventing one — which then shows
/// up as a confidently wrong age next to somebody's name. Here a missing year
/// is simply missing, and the age is not offered.
@immutable
class Birthday {
  const Birthday({required this.month, required this.day, this.year});

  final int month;
  final int day;
  final int? year;

  bool get hasYear => year != null;

  /// The next time this comes round, at or after [from]'s day.
  ///
  /// A 29 February birthday resolves to 1 March in a common year. Somebody has
  /// to decide that, and deciding it here beats letting `DateTime`'s rollover
  /// decide it by accident on one screen and not another.
  DateTime nextOccurrence(DateTime from) {
    final today = DateTime(from.year, from.month, from.day);
    final thisYear = _inYear(today.year);
    return !thisYear.isBefore(today) ? thisYear : _inYear(today.year + 1);
  }

  DateTime _inYear(int year) {
    if (month == 2 && day == 29 && !_isLeapYear(year)) {
      return DateTime(year, 3);
    }
    return DateTime(year, month, day);
  }

  int daysUntil(DateTime from) {
    final today = DateTime(from.year, from.month, from.day);
    return nextOccurrence(from).difference(today).inDays;
  }

  /// The age they are turning on the next occurrence, or null without a year.
  int? ageOnNext(DateTime from) {
    final born = year;
    if (born == null) return null;
    return nextOccurrence(from).year - born;
  }

  static bool _isLeapYear(int year) =>
      year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

  @override
  bool operator ==(Object other) =>
      other is Birthday &&
      other.month == month &&
      other.day == day &&
      other.year == year;

  @override
  int get hashCode => Object.hash(month, day, year);
}

/// Where a place came from, so a sync knows what it may overwrite.
enum PlaceSource { google, manual }

/// Somewhere a person can be found.
///
/// City-level on purpose. The question this answers is "I am in Hamburg on
/// Thursday, who is here" — which the city answers exactly as well as the
/// street does, while keeping a record of friends' addresses from becoming a
/// map of friends' front doors.
@immutable
class PersonPlace {
  const PersonPlace({
    required this.id,
    required this.label,
    required this.city,
    this.region,
    this.country,
    this.address,
    this.cityId,
    this.timezone,
    this.latitude,
    this.longitude,
    this.isPrimary = false,
    this.source = PlaceSource.manual,
  });

  final String id;

  /// What this place is to them — "Home", "Parents", "Summer".
  final String label;

  final String city;

  /// The first-level administrative area — state, province, Land. What tells
  /// Springfield, Illinois from Springfield, Missouri.
  final String? region;
  final String? country;

  /// The address as the contact book had it, kept for reference. Never the
  /// thing that gets plotted.
  final String? address;

  /// The GeoNames id of the city that was chosen from the search list.
  ///
  /// Null for a city that was only typed — added offline, or imported from a
  /// contact book — which is the place the geocoding batch is for. Two places
  /// with the same id are the same city whatever their names look like, and
  /// that is what keeps two Cambridges as two pins.
  final int? cityId;

  /// The IANA zone of that city, e.g. "Europe/Berlin".
  final String? timezone;

  /// The city centroid. Present from the start for a city that was chosen;
  /// null for one that was only typed, which is a place that lists but does
  /// not yet pin.
  final double? latitude;
  final double? longitude;

  final bool isPrimary;
  final PlaceSource source;

  bool get isMappable => latitude != null && longitude != null;

  /// "Munich, DE" — what a row shows when the city alone is ambiguous.
  String get shortLocation => country == null ? city : '$city, $country';

  /// How the map groups places into cities.
  ///
  /// The chosen city's id when there is one, and the name otherwise. Both
  /// halves matter: the id is what stops Cambridge, England and Cambridge,
  /// Massachusetts collapsing into one pin, and the name is what still groups
  /// places typed before anybody picked anything.
  String get cityKey =>
      cityId != null ? 'id:$cityId' : 'name:${city.trim().toLowerCase()}';
}

enum ChannelKind { phone, email, handle }

/// A way to reach someone.
@immutable
class PersonChannel {
  const PersonChannel({
    required this.id,
    required this.kind,
    required this.value,
    this.label,
  });

  final String id;
  final ChannelKind kind;
  final String value;

  /// "Mobile", "Work", "Signal" — whatever the contact book called it.
  final String? label;
}

/// Something worth remembering about a person.
///
/// A dated list rather than one text field, because the useful thing is
/// usually "what was going on with them last time", and a single blob loses
/// that the moment it is edited.
@immutable
class PersonNote {
  const PersonNote({
    required this.id,
    required this.body,
    required this.createdAt,
    this.pinned = false,
    this.happenedOn,
  });

  final String id;
  final String body;
  final DateTime createdAt;

  /// Kept at the top: the allergy, the kids' names, the thing not to bring up.
  final bool pinned;

  /// "YYYY-MM-DD" when the note is about a moment rather than a standing fact.
  final String? happenedOn;
}

/// Something to give them, and whether it has been given.
@immutable
class GiftIdea {
  const GiftIdea({
    required this.id,
    required this.idea,
    this.url,
    this.givenAt,
  });

  final String id;
  final String idea;
  final String? url;

  /// Set once it has actually been given. Kept rather than deleted, because
  /// the list's second job is not giving the same thing twice.
  final DateTime? givenAt;

  bool get isGiven => givenAt != null;
}
