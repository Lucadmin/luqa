import 'package:luqa/features/people/domain/person.dart';

/// The arithmetic the People tab runs on: who is coming up, who has been left
/// too long, and which of those two the screen should lead with.
///
/// Kept away from widgets so "is somebody overdue" can be argued with in a
/// unit test rather than by pumping a screen and reading pixels.

/// A birthday and how far off it is.
class UpcomingBirthday {
  const UpcomingBirthday({
    required this.person,
    required this.daysAway,
    required this.date,
    required this.turningAge,
  });

  final Person person;
  final int daysAway;
  final DateTime date;

  /// Null when the contact carries no birth year, which is most of them.
  final int? turningAge;

  bool get isToday => daysAway == 0;
}

/// Somebody whose cadence has run out.
class OverdueContact {
  const OverdueContact({
    required this.person,
    required this.daysSince,
    required this.cadenceDays,
  });

  final Person person;

  /// Days since they were last seen, or since the cadence was set when they
  /// have never been seen.
  final int daysSince;

  final int cadenceDays;

  /// How far past the target this is. Sorting on the overshoot rather than on
  /// raw elapsed time keeps a yearly friend at fourteen months above a monthly
  /// one at six weeks — which is the right order of concern.
  int get daysOverdue => daysSince - cadenceDays;
}

/// Birthdays falling inside [within] days of [from], soonest first.
List<UpcomingBirthday> upcomingBirthdays(
  Iterable<Person> people,
  DateTime from, {
  int within = 60,
}) {
  final found = <UpcomingBirthday>[];
  for (final person in people) {
    if (person.archived) continue;
    final birthday = person.birthday;
    if (birthday == null) continue;
    final days = birthday.daysUntil(from);
    if (days > within) continue;
    found.add(
      UpcomingBirthday(
        person: person,
        daysAway: days,
        date: birthday.nextOccurrence(from),
        turningAge: birthday.ageOnNext(from),
      ),
    );
  }
  found.sort((a, b) {
    final byDay = a.daysAway.compareTo(b.daysAway);
    return byDay != 0 ? byDay : a.person.name.compareTo(b.person.name);
  });
  return found;
}

/// When somebody was actually last seen, from everything the app knows.
///
/// The manual date is only one of the sources, and usually the worst one:
/// dinner logged on Tuesday already says Tuesday, and a bill split with them
/// says the same thing. Asking the user to also tick a box on the contact card
/// is asking twice for one fact.
///
/// [taggedAt] and [sharedAt] are the newest timeline entry and the newest
/// shared bill, which the caller reads from data the device already holds — so
/// this stays correct offline.
DateTime? effectiveLastSeen(
  Person person, {
  DateTime? taggedAt,
  DateTime? sharedAt,
}) {
  DateTime? newest;
  for (final candidate in [person.lastSeenAt, taggedAt, sharedAt]) {
    if (candidate == null) continue;
    if (newest == null || candidate.isAfter(newest)) newest = candidate;
  }
  return newest;
}

/// People whose cadence has elapsed, most overdue first.
///
/// Someone with a cadence and nothing on record counts from nothing rather
/// than from the epoch: setting a cadence must not instantly declare a person
/// neglected for fifty years.
/// [lastSeen] resolves a person to when they were really last seen, so a
/// dinner logged on the timeline counts without anybody recording it twice.
/// It defaults to the date on the person alone.
List<OverdueContact> overdueContacts(
  Iterable<Person> people,
  DateTime from, {
  DateTime? Function(Person person)? lastSeen,
}) {
  final resolve = lastSeen ?? (person) => person.lastSeenAt;
  final found = <OverdueContact>[];
  for (final person in people) {
    if (person.archived) continue;
    final cadence = person.cadenceDays;
    if (cadence == null || cadence <= 0) continue;
    final seen = resolve(person);
    if (seen == null) continue;
    final days = _wholeDaysBetween(seen, from);
    if (days <= cadence) continue;
    found.add(
      OverdueContact(person: person, daysSince: days, cadenceDays: cadence),
    );
  }
  found.sort((a, b) {
    final byOvershoot = b.daysOverdue.compareTo(a.daysOverdue);
    return byOvershoot != 0
        ? byOvershoot
        : a.person.name.compareTo(b.person.name);
  });
  return found;
}

/// What the screen leads with.
///
/// One thing, never two. A birthday inside [birthdayWindow] days outranks
/// everything because it expires; otherwise the longest-neglected person; and
/// when neither applies the tab simply has no headline, which is a perfectly
/// good state for a contact book to be in.
sealed class PeopleFocus {
  const PeopleFocus();
}

class BirthdayFocus extends PeopleFocus {
  const BirthdayFocus(this.birthday);
  final UpcomingBirthday birthday;
}

class ReconnectFocus extends PeopleFocus {
  const ReconnectFocus(this.contact);
  final OverdueContact contact;
}

class QuietFocus extends PeopleFocus {
  const QuietFocus(this.peopleCount);
  final int peopleCount;
}

PeopleFocus peopleFocus(
  List<Person> people,
  DateTime from, {
  int birthdayWindow = 30,
  DateTime? Function(Person person)? lastSeen,
}) {
  final birthdays = upcomingBirthdays(people, from, within: birthdayWindow);
  if (birthdays.isNotEmpty) return BirthdayFocus(birthdays.first);
  final overdue = overdueContacts(people, from, lastSeen: lastSeen);
  if (overdue.isNotEmpty) return ReconnectFocus(overdue.first);
  return QuietFocus(people.where((person) => !person.archived).length);
}

/// People grouped by the city they are in, biggest city first.
///
/// This is the map's answer without the map: it works offline, it survives a
/// place that has never been geocoded, and for "who is in Hamburg" it is
/// arguably the better surface anyway.
class PeopleInCity {
  const PeopleInCity({
    required this.key,
    required this.city,
    required this.region,
    required this.country,
    required this.people,
    required this.latitude,
    required this.longitude,
    this.nameIsShared = false,
  });

  /// What made these places one city — a chosen city's id, or a name. Stable
  /// enough to key a widget by, which a name alone is not once two cities can
  /// share one.
  final String key;

  final String city;

  /// The state, province or Land, when the city was chosen rather than typed.
  final String? region;
  final String? country;
  final List<Person> people;

  /// The city centroid, taken from the first place that has one. Null when
  /// nothing in this city has been geocoded yet — it lists, it does not pin.
  final double? latitude;
  final double? longitude;

  /// Whether another city in the same list reads the same way. Set by
  /// [peopleByCity], because no single group can know it.
  final bool nameIsShared;

  bool get isMappable => latitude != null && longitude != null;

  /// "Munich, DE", and "Springfield, Illinois, US" when there is a second
  /// Springfield on screen.
  ///
  /// The region is spent only where it is needed: it is the difference between
  /// two identical-looking rows and a list that is merely longer.
  String get label => [
    city,
    if (nameIsShared && region != null && region!.isNotEmpty) region,
    if (country != null) country,
  ].join(', ');
}

List<PeopleInCity> peopleByCity(Iterable<Person> people) {
  final byKey = <String, List<Person>>{};
  final places = <String, PersonPlace>{};

  for (final person in people) {
    if (person.archived) continue;
    // Everywhere they can be found, not only where they mostly are: the
    // parents' city is exactly the kind of place this is for.
    for (final place in person.places) {
      if (place.city.trim().isEmpty) continue;
      // The chosen city's id when there is one, the name otherwise. Grouping
      // by name alone put Cambridge, England and Cambridge, Massachusetts on
      // one pin, at whichever centroid happened to be resolved first.
      final key = place.cityKey;
      byKey.putIfAbsent(key, () => <Person>[]);
      if (!byKey[key]!.any((existing) => existing.id == person.id)) {
        byKey[key]!.add(person);
      }
      final known = places[key];
      if (known == null || (!known.isMappable && place.isMappable)) {
        places[key] = place;
      }
    }
  }

  // How many groups would read the same way without their region. Two
  // Springfields in the US are the case this exists for.
  final nameCounts = <String, int>{};
  for (final place in places.values) {
    final name = '${place.city.trim().toLowerCase()}|${place.country ?? ''}';
    nameCounts[name] = (nameCounts[name] ?? 0) + 1;
  }

  final cities = <PeopleInCity>[];
  for (final entry in byKey.entries) {
    final place = places[entry.key]!;
    final name = '${place.city.trim().toLowerCase()}|${place.country ?? ''}';
    cities.add(
      PeopleInCity(
        key: entry.key,
        city: place.city,
        region: place.region,
        country: place.country,
        people: entry.value..sort((a, b) => a.name.compareTo(b.name)),
        latitude: place.latitude,
        longitude: place.longitude,
        nameIsShared: (nameCounts[name] ?? 0) > 1,
      ),
    );
  }
  cities.sort((a, b) {
    final byCount = b.people.length.compareTo(a.people.length);
    if (byCount != 0) return byCount;
    final byCity = a.city.compareTo(b.city);
    // Two cities of the same name and size still need a settled order, or the
    // list reshuffles itself between reads.
    return byCity != 0 ? byCity : a.key.compareTo(b.key);
  });
  return cities;
}

/// Whole days between two instants, by calendar day rather than by elapsed
/// hours: "yesterday evening to this morning" is one day, not zero.
int _wholeDaysBetween(DateTime earlier, DateTime later) {
  final from = DateTime(earlier.year, earlier.month, earlier.day);
  final to = DateTime(later.year, later.month, later.day);
  return to.difference(from).inDays;
}

/// Elapsed time as a person would say it: "3 days", "5 weeks", "8 months".
///
/// Never "0 days ago" and never a decimal. The point is a sense of how long,
/// not a measurement.
String describeElapsed(int days) {
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  if (days < 14) return '$days days';
  if (days < 60) return '${(days / 7).round()} weeks';
  if (days < 365) return '${(days / 30.44).round()} months';
  final years = days / 365.25;
  return years < 1.5 ? 'over a year' : '${years.round()} years';
}

/// How a countdown reads next to a name.
String describeCountdown(int days) {
  if (days == 0) return 'today';
  if (days == 1) return 'tomorrow';
  if (days < 14) return 'in $days days';
  if (days < 45) return 'in ${(days / 7).round()} weeks';
  return 'in ${(days / 30.44).round()} months';
}
