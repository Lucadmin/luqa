import 'in_memory_people_repository.dart';
import 'package:luqa/features/people/domain/person.dart';

/// A roster with enough shape in it to exercise every state the People tab
/// has: a birthday inside the window, one outside it, a contact with no birth
/// year, two cities, somebody overdue, somebody with a cadence who is fine,
/// somebody with nothing on record at all, and an archived person.
///
/// Pinned to [fixedNow] = 27 August 2026 so the countdowns in the goldens do
/// not change tomorrow.
InMemoryPeopleRepository fakePeopleRepository({DateTime? now}) {
  final today = now ?? DateTime(2026, 8, 27, 15);

  return InMemoryPeopleRepository(
    seed: [
      Person(
        id: 'mira',
        name: 'Mira Hensel',
        colorValue: 0xFFBE185D,
        emoji: null,
        defaultPercent: null,
        order: 0,
        archived: false,
        // 4 September: eight days out, inside the headline window.
        birthday: const Birthday(month: 9, day: 4, year: 1997),
        cadenceDays: 30,
        closeness: Closeness.innerCircle,
        connections: const [
          PersonConnection(personId: 'jonas', closeness: Closeness.close),
          PersonConnection(personId: 'tessa', closeness: Closeness.inMyLife),
        ],
        lastSeenAt: today.subtract(const Duration(days: 6)),
        places: const [
          PersonPlace(
            id: 'mira-home',
            label: 'Home',
            city: 'Munich',
            country: 'DE',
            latitude: 48.1374,
            longitude: 11.5755,
            isPrimary: true,
          ),
        ],
        notes: [
          PersonNote(
            id: 'mira-note-1',
            body: 'Allergic to hazelnuts — not the cake place on Türkenstraße.',
            createdAt: today.subtract(const Duration(days: 200)),
            pinned: true,
          ),
          PersonNote(
            id: 'mira-note-2',
            body: 'Started the ceramics course, three evenings a week.',
            createdAt: today.subtract(const Duration(days: 21)),
          ),
        ],
        gifts: const [
          GiftIdea(id: 'mira-gift-1', idea: 'Kiln time at the studio'),
          GiftIdea(id: 'mira-gift-2', idea: 'Rilke letters, the good edition'),
        ],
      ),
      Person(
        id: 'jonas',
        name: 'Jonas Brehm',
        colorValue: 0xFF2563EB,
        emoji: null,
        defaultPercent: 30,
        order: 1,
        archived: false,
        nickname: 'Jo',
        birthday: const Birthday(month: 2, day: 29, year: 1996),
        // Five months against a two-month rhythm: the overdue case.
        cadenceDays: 61,
        closeness: Closeness.close,
        connections: const [
          PersonConnection(personId: 'piet', closeness: Closeness.familiar),
        ],
        lastSeenAt: today.subtract(const Duration(days: 152)),
        places: const [
          PersonPlace(
            id: 'jonas-home',
            label: 'Home',
            city: 'Berlin',
            country: 'DE',
            latitude: 52.52,
            longitude: 13.405,
            isPrimary: true,
          ),
          PersonPlace(
            id: 'jonas-parents',
            label: 'Parents',
            city: 'Hamburg',
            country: 'DE',
          ),
        ],
      ),
      Person(
        id: 'tessa',
        name: 'Tessa Lund',
        colorValue: 0xFF0F766E,
        emoji: null,
        defaultPercent: null,
        order: 2,
        archived: false,
        // No birth year, which is most of a real contact book.
        birthday: const Birthday(month: 11, day: 12),
        cadenceDays: 182,
        closeness: Closeness.inMyLife,
        lastSeenAt: today.subtract(const Duration(days: 341)),
        places: const [
          PersonPlace(
            id: 'tessa-home',
            label: 'Home',
            city: 'Hamburg',
            country: 'DE',
            latitude: 53.5511,
            longitude: 9.9937,
            isPrimary: true,
          ),
        ],
      ),
      Person(
        id: 'piet',
        name: 'Piet Sanders',
        colorValue: 0xFF15803D,
        emoji: null,
        defaultPercent: null,
        order: 3,
        archived: false,
        // A cadence being kept: present in the roster, absent from "been a
        // while", which is the case that proves the list is not just everyone.
        cadenceDays: 91,
        closeness: Closeness.close,
        lastSeenAt: today.subtract(const Duration(days: 12)),
        places: const [
          PersonPlace(
            id: 'piet-home',
            label: 'Home',
            city: 'Hamburg',
            country: 'DE',
            latitude: 53.5511,
            longitude: 9.9937,
            isPrimary: true,
          ),
        ],
      ),
      const Person(
        id: 'alina',
        name: 'Alina Hoeck',
        colorValue: 0xFFB45309,
        emoji: null,
        defaultPercent: null,
        order: 4,
        archived: false,
        closeness: Closeness.familiar,
        // Nothing on record beyond a name: a complete person, and the state
        // most of a freshly synced contact book will be in.
      ),
      const Person(
        id: 'ex-flatmate',
        name: 'Nils Aigner',
        colorValue: 0xFFC2410C,
        emoji: null,
        defaultPercent: null,
        order: 5,
        archived: true,
      ),
    ],
  );
}

/// The same roster with no city ever geocoded — a contact book on its first
/// run, or one whose geocoder has never been reachable.
InMemoryPeopleRepository unpinnedPeopleRepository({DateTime? now}) {
  final seeded = fakePeopleRepository(now: now);
  return InMemoryPeopleRepository(
    seed: [
      for (final person in seeded.seedPeople)
        person.copyWith(
          places: [
            for (final place in person.places)
              PersonPlace(
                id: place.id,
                label: place.label,
                city: place.city,
                country: place.country,
                isPrimary: place.isPrimary,
              ),
          ],
        ),
    ],
  );
}

/// The roster with one city deliberately unresolved.
///
/// The realistic middle state: a geocoder is rate-limited and resolves a few
/// cities per call, so a contact book spends its first runs with some cities
/// pinned and some not.
InMemoryPeopleRepository partlyPinnedPeopleRepository({
  DateTime? now,
  String unpinnedCity = 'Berlin',
}) {
  final seeded = fakePeopleRepository(now: now);
  return InMemoryPeopleRepository(
    seed: [
      for (final person in seeded.seedPeople)
        person.copyWith(
          places: [
            for (final place in person.places)
              if (place.city == unpinnedCity)
                PersonPlace(
                  id: place.id,
                  label: place.label,
                  city: place.city,
                  country: place.country,
                  isPrimary: place.isPrimary,
                )
              else
                place,
          ],
        ),
    ],
  );
}
