import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/people/domain/people_math.dart';
import 'package:luqa/features/people/domain/person.dart';

Person person(
  String id, {
  Birthday? birthday,
  int? cadenceDays,
  DateTime? lastSeenAt,
  bool archived = false,
  List<PersonPlace> places = const [],
}) => Person(
  id: id,
  name: id,
  colorValue: 0xFF2563EB,
  emoji: null,
  defaultPercent: null,
  order: 0,
  archived: archived,
  birthday: birthday,
  cadenceDays: cadenceDays,
  lastSeenAt: lastSeenAt,
  places: places,
);

void main() {
  group('Birthday', () {
    test('counts to this year while the day is still ahead', () {
      const birthday = Birthday(month: 9, day: 4, year: 1997);
      expect(birthday.daysUntil(DateTime(2026, 8, 27)), 8);
      expect(birthday.nextOccurrence(DateTime(2026, 8, 27)), DateTime(2026, 9, 4));
    });

    test('the birthday itself is zero days away, not a year', () {
      const birthday = Birthday(month: 8, day: 27);
      expect(birthday.daysUntil(DateTime(2026, 8, 27, 23)), 0);
    });

    test('rolls to next year once the day has passed', () {
      const birthday = Birthday(month: 3, day: 14, year: 1990);
      expect(birthday.nextOccurrence(DateTime(2026, 8, 27)), DateTime(2027, 3, 14));
      expect(birthday.ageOnNext(DateTime(2026, 8, 27)), 37);
    });

    test('29 February lands on 1 March in a common year', () {
      const birthday = Birthday(month: 2, day: 29, year: 1996);
      // 2027 is common: the day does not exist, and rolling into March is a
      // decision rather than something DateTime does behind our backs.
      expect(birthday.nextOccurrence(DateTime(2027, 1, 1)), DateTime(2027, 3));
      // 2028 is a leap year and the real day is available.
      expect(birthday.nextOccurrence(DateTime(2028, 1, 1)), DateTime(2028, 2, 29));
    });

    test('offers no age without a birth year', () {
      const birthday = Birthday(month: 11, day: 12);
      expect(birthday.ageOnNext(DateTime(2026, 8, 27)), isNull);
      expect(birthday.hasYear, isFalse);
    });
  });

  group('upcomingBirthdays', () {
    final now = DateTime(2026, 8, 27);

    test('is ordered by how soon, and respects the window', () {
      final people = [
        person('far', birthday: const Birthday(month: 12, day: 25)),
        person('soon', birthday: const Birthday(month: 9, day: 4)),
        person('none'),
      ];
      final found = upcomingBirthdays(people, now, within: 60);
      expect(found.map((b) => b.person.id), ['soon']);
    });

    test('leaves archived people out', () {
      final people = [
        person('gone', birthday: const Birthday(month: 9, day: 4), archived: true),
      ];
      expect(upcomingBirthdays(people, now), isEmpty);
    });
  });

  group('overdueContacts', () {
    final now = DateTime(2026, 8, 27);

    test('lists only people past their own cadence', () {
      final people = [
        person(
          'overdue',
          cadenceDays: 30,
          lastSeenAt: DateTime(2026, 6, 1),
        ),
        person(
          'fine',
          cadenceDays: 90,
          lastSeenAt: DateTime(2026, 8, 1),
        ),
        // No cadence at all: never a duty, never on the list.
        person('unrhythmed', lastSeenAt: DateTime(2020, 1, 1)),
      ];
      expect(overdueContacts(people, now).map((c) => c.person.id), ['overdue']);
    });

    test('never declares someone overdue with nothing on record', () {
      // Setting a cadence must not instantly report fifty years of neglect.
      final people = [person('new', cadenceDays: 30)];
      expect(overdueContacts(people, now), isEmpty);
    });

    test('sorts by how far past the target, not by raw elapsed time', () {
      final people = [
        // 14 months against a yearly rhythm: two months over.
        person('yearly', cadenceDays: 365, lastSeenAt: DateTime(2025, 6, 27)),
        // 4 months against a monthly rhythm: three months over, and the one
        // actually being neglected.
        person('monthly', cadenceDays: 30, lastSeenAt: DateTime(2026, 4, 27)),
      ];
      expect(
        overdueContacts(people, now).map((c) => c.person.id),
        ['monthly', 'yearly'],
      );
    });
  });

  group('peopleFocus', () {
    final now = DateTime(2026, 8, 27);

    test('a near birthday outranks an overdue friend', () {
      final people = [
        person('overdue', cadenceDays: 30, lastSeenAt: DateTime(2024, 1, 1)),
        person('birthday', birthday: const Birthday(month: 9, day: 4)),
      ];
      final focus = peopleFocus(people, now);
      expect(focus, isA<BirthdayFocus>());
      expect((focus as BirthdayFocus).birthday.person.id, 'birthday');
    });

    test('falls back to the longest overdue when no birthday is close', () {
      final people = [
        person('overdue', cadenceDays: 30, lastSeenAt: DateTime(2024, 1, 1)),
        person('birthday', birthday: const Birthday(month: 12, day: 25)),
      ];
      expect(peopleFocus(people, now), isA<ReconnectFocus>());
    });

    test('says so plainly when there is nothing to lead with', () {
      final focus = peopleFocus([person('a'), person('b')], now);
      expect(focus, isA<QuietFocus>());
      expect((focus as QuietFocus).peopleCount, 2);
    });
  });

  group('peopleByCity', () {
    const munich = PersonPlace(
      id: 'p1',
      label: 'Home',
      city: 'Munich',
      country: 'DE',
      latitude: 48.13,
      longitude: 11.57,
      isPrimary: true,
    );
    const hamburgNoCoords = PersonPlace(
      id: 'p2',
      label: 'Parents',
      city: 'Hamburg',
      country: 'DE',
    );
    const hamburgCoords = PersonPlace(
      id: 'p3',
      label: 'Home',
      city: 'Hamburg',
      country: 'DE',
      latitude: 53.55,
      longitude: 9.99,
    );

    test('counts a person in every city they can be found in', () {
      final cities = peopleByCity([
        person('jonas', places: const [munich, hamburgNoCoords]),
      ]);
      expect(cities.map((c) => c.city).toSet(), {'Munich', 'Hamburg'});
    });

    test('biggest city first', () {
      final cities = peopleByCity([
        person('a', places: const [hamburgCoords]),
        person('b', places: const [hamburgCoords]),
        person('c', places: const [munich]),
      ]);
      expect(cities.first.city, 'Hamburg');
      expect(cities.first.people.length, 2);
    });

    test('a city takes coordinates from whichever place has them', () {
      // One friend's address geocoded and another's did not; the pin still
      // lands rather than the whole city dropping off the map.
      final cities = peopleByCity([
        person('a', places: const [hamburgNoCoords]),
        person('b', places: const [hamburgCoords]),
      ]);
      expect(cities.single.isMappable, isTrue);
    });

    test('matches city names regardless of case and spacing', () {
      final cities = peopleByCity([
        person('a', places: const [munich]),
        person(
          'b',
          places: const [
            PersonPlace(id: 'p4', label: 'Home', city: ' munich ', country: 'DE'),
          ],
        ),
      ]);
      expect(cities.length, 1);
      expect(cities.single.people.length, 2);
    });
  });

  group('describeElapsed', () {
    test('never reports zero days ago', () {
      expect(describeElapsed(0), 'today');
      expect(describeElapsed(1), 'yesterday');
    });

    test('changes unit as the gap grows', () {
      expect(describeElapsed(5), '5 days');
      expect(describeElapsed(21), '3 weeks');
      expect(describeElapsed(152), '5 months');
      expect(describeElapsed(400), 'over a year');
      expect(describeElapsed(1100), '3 years');
    });
  });

  group('effectiveLastSeen', () {
    test('takes the newest of everything the app knows', () {
      // A dinner logged on the timeline is more recent than the date typed on
      // the contact card, so it wins — which is the point of tagging it.
      final seen = effectiveLastSeen(
        person('mira', lastSeenAt: DateTime(2026, 3, 1)),
        taggedAt: DateTime(2026, 8, 20),
        sharedAt: DateTime(2026, 6, 1),
      );
      expect(seen, DateTime(2026, 8, 20));
    });

    test('a shared bill counts as having seen them', () {
      // Money already knows you had dinner together; asking the owner to tick
      // a box as well is asking twice for one fact.
      final seen = effectiveLastSeen(
        person('mira'),
        sharedAt: DateTime(2026, 8, 26),
      );
      expect(seen, DateTime(2026, 8, 26));
    });

    test('a typed date still wins when it is the newest', () {
      // Seeing somebody without logging it or splitting a bill is normal, and
      // the manual record has to be able to say so.
      final seen = effectiveLastSeen(
        person('mira', lastSeenAt: DateTime(2026, 8, 27)),
        taggedAt: DateTime(2026, 1, 4),
      );
      expect(seen, DateTime(2026, 8, 27));
    });

    test('nothing on record stays nothing', () {
      expect(effectiveLastSeen(person('mira')), isNull);
    });
  });

  test('a tagged block of time keeps somebody off the overdue list', () {
    final now = DateTime(2026, 8, 27);
    final jonas = person(
      'jonas',
      cadenceDays: 30,
      lastSeenAt: DateTime(2026, 1, 1),
    );

    // By the contact card alone he is eight months overdue.
    expect(overdueContacts([jonas], now).map((c) => c.person.id), ['jonas']);

    // With the timeline consulted, he was seen last week.
    expect(
      overdueContacts(
        [jonas],
        now,
        lastSeen: (_) => DateTime(2026, 8, 20),
      ),
      isEmpty,
    );
  });
}
