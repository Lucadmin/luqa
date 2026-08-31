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

/// People whose cadence has elapsed, most overdue first.
///
/// Someone with a cadence and nothing on record counts from nothing rather
/// than from the epoch: setting a cadence must not instantly declare a person
/// neglected for fifty years.
List<OverdueContact> overdueContacts(Iterable<Person> people, DateTime from) {
  final found = <OverdueContact>[];
  for (final person in people) {
    if (person.archived) continue;
    final cadence = person.cadenceDays;
    if (cadence == null || cadence <= 0) continue;
    final seen = person.lastSeenAt;
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
}) {
  final birthdays = upcomingBirthdays(people, from, within: birthdayWindow);
  if (birthdays.isNotEmpty) return BirthdayFocus(birthdays.first);
  final overdue = overdueContacts(people, from);
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
    required this.city,
    required this.country,
    required this.people,
    required this.latitude,
    required this.longitude,
  });

  final String city;
  final String? country;
  final List<Person> people;

  /// The city centroid, taken from the first place that has one. Null when
  /// nothing in this city has been geocoded yet — it lists, it does not pin.
  final double? latitude;
  final double? longitude;

  bool get isMappable => latitude != null && longitude != null;

  String get label => country == null ? city : '$city, $country';
}

List<PeopleInCity> peopleByCity(Iterable<Person> people) {
  final byKey = <String, List<Person>>{};
  final places = <String, PersonPlace>{};

  for (final person in people) {
    if (person.archived) continue;
    // Everywhere they can be found, not only where they mostly are: the
    // parents' city is exactly the kind of place this is for.
    for (final place in person.places) {
      final key = place.city.trim().toLowerCase();
      if (key.isEmpty) continue;
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

  final cities = <PeopleInCity>[];
  for (final entry in byKey.entries) {
    final place = places[entry.key]!;
    cities.add(
      PeopleInCity(
        city: place.city,
        country: place.country,
        people: entry.value..sort((a, b) => a.name.compareTo(b.name)),
        latitude: place.latitude,
        longitude: place.longitude,
      ),
    );
  }
  cities.sort((a, b) {
    final byCount = b.people.length.compareTo(a.people.length);
    return byCount != 0 ? byCount : a.city.compareTo(b.city);
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
