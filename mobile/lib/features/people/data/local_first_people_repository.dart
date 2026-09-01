import 'dart:async';

import 'package:luqa/core/id/local_id.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/money/data/money_local_store.dart';
import 'package:luqa/features/money/data/money_outbox.dart';
import 'package:luqa/features/people/data/people_repository.dart';
import 'package:luqa/features/people/data/people_sync_service.dart';
import 'package:luqa/features/people/domain/person.dart';

/// The People tab, answered from this device.
///
/// Every read comes out of the local tables and every write lands there first,
/// so a note typed on a train is on screen instantly and reaches the server
/// whenever signal does.
///
/// Two things here are shared with Money rather than owned:
///
///  * **The store.** There is one `person` row. Money reads its identity
///    columns for balances; this reads the whole thing.
///  * **The queue.** A bill references a person by an id this device may have
///    invented, so a person create and an expense create have to replay in the
///    order they happened. Two queues have no order between them. See
///    [MoneyMutation] for the full argument.
class LocalFirstPeopleRepository implements PeopleRepository {
  LocalFirstPeopleRepository({
    required this.store,
    required this.sync,
    required this.remote,
    required this.queue,
    String Function()? mintId,
    DateTime Function()? now,
  }) : _mintId = mintId ?? newLocalId,
       _now = now ?? DateTime.now;

  final MoneyLocalStore store;
  final PeopleSyncService sync;

  /// For the one operation that has no offline meaning: asking a third-party
  /// geocoder where a city is.
  final PeopleRepository remote;

  final MutationQueue<MoneyMutation> queue;

  final String Function() _mintId;
  final DateTime Function() _now;

  /// Mirrors the server's default so someone added offline usually keeps the
  /// colour they were given once it syncs.
  static const fallbackColor = 0xFF6366F1;

  // ----------------------------------------------------------------- reads

  @override
  Future<List<Person>> loadPeople() async {
    await queue.ready;
    unawaited(_refresh());
    return store.people();
  }

  @override
  Future<Person> loadPerson(String id) async {
    await queue.ready;
    return _require(id);
  }

  /// Pulls what changed, quietly. A failure is not surfaced: the cached people
  /// are still the best answer available, and the screen already has them.
  Future<void> _refresh() async {
    try {
      await sync.pull();
    } on Object {
      // Deliberately swallowed. The queue reports its own trouble.
    }
  }

  // ---------------------------------------------------------------- writes

  /// Records the change locally and queues it, in that order, so the screen
  /// never waits on a network.
  Future<void> _write(
    MoneyMutation mutation,
    Future<void> Function() apply,
  ) async {
    await queue.enqueue(mutation, sendNow: false);
    await apply();
    unawaited(queue.sync());
  }

  /// Applies a change to the local person and queues the write that will make
  /// it real. Returns the person as the screen should now see them.
  ///
  /// The row is written `pending`, which is what stops an in-flight delta from
  /// overwriting it with the server's older copy.
  Future<Person> _edit(
    String id,
    MoneyMutation Function(Person person) mutation,
    Person Function(Person person) apply,
  ) async {
    await queue.ready;
    final person = await _require(id);
    final updated = apply(person);
    await _write(mutation(person), () => store.putPerson(updated));
    return updated;
  }

  Future<Person> _require(String id) async {
    for (final person in await store.people()) {
      if (person.id == id) return person;
    }
    throw StateError('No person $id');
  }

  @override
  Future<Person> createPerson({
    String? id,
    required PersonWrite write,
  }) async {
    await queue.ready;
    // Adding someone this device already knows by name is the same person, not
    // a second row for the server to merge — the same rule the API applies.
    for (final person in await store.people()) {
      if (person.name.toLowerCase() == write.name.toLowerCase()) return person;
    }

    final person = Person(
      id: id ?? _mintId(),
      name: write.name,
      colorValue: write.colorValue == 0 ? fallbackColor : write.colorValue,
      emoji: write.emoji,
      defaultPercent: write.defaultPercent,
      order: (await store.people()).length,
      archived: false,
      nickname: write.nickname,
      birthday: write.birthday,
      cadenceDays: write.cadenceDays,
    );
    await _write(
      CreatePerson(person: person, queuedAt: _now()),
      () => store.putPerson(person),
    );
    return person;
  }

  @override
  Future<Person> updatePerson({
    required String id,
    String? name,
    int? colorValue,
    String? emoji,
    bool clearEmoji = false,
    int? defaultPercent,
    bool clearDefaultPercent = false,
    String? nickname,
    bool clearNickname = false,
    Birthday? birthday,
    bool clearBirthday = false,
    int? cadenceDays,
    bool clearCadence = false,
    bool? archived,
  }) => _edit(
    id,
    (person) => UpdatePerson(
      personId: id,
      name: name,
      colorValue: colorValue,
      emoji: emoji,
      clearEmoji: clearEmoji,
      defaultPercent: defaultPercent,
      clearDefaultPercent: clearDefaultPercent,
      nickname: nickname,
      clearNickname: clearNickname,
      birthday: birthday,
      clearBirthday: clearBirthday,
      cadenceDays: cadenceDays,
      clearCadence: clearCadence,
      archived: archived,
      queuedAt: _now(),
    ),
    (person) => person.copyWith(
      name: name,
      colorValue: colorValue,
      emoji: emoji,
      clearEmoji: clearEmoji,
      defaultPercent: defaultPercent,
      clearDefaultPercent: clearDefaultPercent,
      nickname: nickname,
      clearNickname: clearNickname,
      birthday: birthday,
      clearBirthday: clearBirthday,
      cadenceDays: cadenceDays,
      clearCadence: clearCadence,
      archived: archived,
    ),
  );

  @override
  Future<void> deletePerson(String id) async {
    await queue.ready;
    await _write(
      DeletePerson(personId: id, queuedAt: _now()),
      // Marked removed rather than dropped: the row has to stay out of every
      // read while the delete is still in the queue, and be forgotten for real
      // only once the server has confirmed it.
      () => store.remove('person', id),
    );
  }

  @override
  Future<Person> markSeen(String id, DateTime when) => _edit(
    id,
    (person) => MarkPersonSeen(
      personId: id,
      personName: person.displayName,
      seenAt: when,
      queuedAt: _now(),
    ),
    (person) => person.copyWith(lastSeenAt: when),
  );

  @override
  Future<Person> addNote(
    String personId, {
    String? id,
    required String body,
    bool pinned = false,
    String? happenedOn,
  }) {
    final noteId = id ?? _mintId();
    return _edit(
      personId,
      (person) => AddPersonNote(
        personId: personId,
        personName: person.displayName,
        noteId: noteId,
        body: body,
        pinned: pinned,
        happenedOn: happenedOn,
        queuedAt: _now(),
      ),
      (person) => person.copyWith(
        // Newest first, matching the order the server sends them back in, so
        // the list does not reorder itself under the user when the write lands.
        notes: [
          PersonNote(
            id: noteId,
            body: body,
            createdAt: _now(),
            pinned: pinned,
            happenedOn: happenedOn,
          ),
          ...person.notes,
        ],
      ),
    );
  }

  @override
  Future<Person> updateNote(
    String personId, {
    required String noteId,
    String? body,
    bool? pinned,
  }) => _edit(
    personId,
    (person) => UpdatePersonNote(
      personId: personId,
      personName: person.displayName,
      noteId: noteId,
      body: body,
      pinned: pinned,
      queuedAt: _now(),
    ),
    (person) => person.copyWith(
      notes: [
        for (final note in person.notes)
          if (note.id == noteId)
            PersonNote(
              id: note.id,
              body: body ?? note.body,
              createdAt: note.createdAt,
              pinned: pinned ?? note.pinned,
              happenedOn: note.happenedOn,
            )
          else
            note,
      ],
    ),
  );

  @override
  Future<Person> removeNote(String personId, String noteId) => _edit(
    personId,
    (person) => RemovePersonNote(
      personId: personId,
      personName: person.displayName,
      noteId: noteId,
      queuedAt: _now(),
    ),
    (person) => person.copyWith(
      notes: [
        for (final note in person.notes)
          if (note.id != noteId) note,
      ],
    ),
  );

  @override
  Future<Person> addGift(
    String personId, {
    String? id,
    required String idea,
    String? url,
  }) {
    final giftId = id ?? _mintId();
    return _edit(
      personId,
      (person) => AddPersonGift(
        personId: personId,
        personName: person.displayName,
        giftId: giftId,
        idea: idea,
        url: url,
        queuedAt: _now(),
      ),
      (person) => person.copyWith(
        gifts: [...person.gifts, GiftIdea(id: giftId, idea: idea, url: url)],
      ),
    );
  }

  @override
  Future<Person> setGiftGiven(
    String personId, {
    required String giftId,
    DateTime? givenAt,
  }) => _edit(
    personId,
    (person) => SetGiftGiven(
      personId: personId,
      personName: person.displayName,
      giftId: giftId,
      givenAt: givenAt,
      queuedAt: _now(),
    ),
    (person) => person.copyWith(
      gifts: [
        for (final gift in person.gifts)
          if (gift.id == giftId)
            GiftIdea(
              id: gift.id,
              idea: gift.idea,
              url: gift.url,
              givenAt: givenAt,
            )
          else
            gift,
      ],
    ),
  );

  @override
  Future<Person> removeGift(String personId, String giftId) => _edit(
    personId,
    (person) => RemovePersonGift(
      personId: personId,
      personName: person.displayName,
      giftId: giftId,
      queuedAt: _now(),
    ),
    (person) => person.copyWith(
      gifts: [
        for (final gift in person.gifts)
          if (gift.id != giftId) gift,
      ],
    ),
  );

  @override
  Future<Person> addPlace(
    String personId, {
    String? id,
    required String label,
    required String city,
    String? country,
    bool isPrimary = false,
  }) {
    final placeId = id ?? _mintId();
    return _edit(personId, (person) {
      // The first place is primary whether or not anyone asked, matching the
      // server: a person with one city and no primary has no answer to "where
      // are they".
      final primary = isPrimary || person.places.isEmpty;
      return AddPersonPlace(
        personId: personId,
        personName: person.displayName,
        placeId: placeId,
        label: label,
        city: city,
        country: country,
        isPrimary: primary,
        queuedAt: _now(),
      );
    }, (person) => _withPlace(person, placeId, label, city, country, isPrimary));
  }

  Person _withPlace(
    Person person,
    String placeId,
    String label,
    String city,
    String? country,
    bool isPrimary,
  ) {
    final primary = isPrimary || person.places.isEmpty;
    return person.copyWith(
      places: [
        // Exactly one primary: a second one marked primary demotes the first,
        // rather than leaving the row with two answers.
        for (final place in person.places)
          primary && place.isPrimary ? _demoted(place) : place,
        PersonPlace(
          id: placeId,
          label: label,
          city: city,
          country: country,
          isPrimary: primary,
        ),
      ],
    );
  }

  PersonPlace _demoted(PersonPlace place) => PersonPlace(
    id: place.id,
    label: place.label,
    city: place.city,
    region: place.region,
    country: place.country,
    address: place.address,
    latitude: place.latitude,
    longitude: place.longitude,
    source: place.source,
  );

  @override
  Future<bool> geocodePendingPlaces() async {
    // Online-only, and deliberately so: there is nothing to queue. A city with
    // no point is not a failed write, it is a place that lists but does not
    // pin — a state the map already shows honestly.
    final more = await remote.geocodePendingPlaces();
    // The points landed on the server's copy of the people, so the pins only
    // appear here once the delta carrying them has been pulled.
    await sync.pull();
    return more;
  }

  @override
  Future<Person> removePlace(String personId, String placeId) => _edit(
    personId,
    (person) => RemovePersonPlace(
      personId: personId,
      personName: person.displayName,
      placeId: placeId,
      queuedAt: _now(),
    ),
    (person) {
      final kept = [
        for (final place in person.places)
          if (place.id != placeId) place,
      ];
      // Removing the primary promotes the next one, so "where are they" does
      // not go blank while cities are still on file.
      if (kept.isNotEmpty && !kept.any((place) => place.isPrimary)) {
        kept[0] = PersonPlace(
          id: kept[0].id,
          label: kept[0].label,
          city: kept[0].city,
          region: kept[0].region,
          country: kept[0].country,
          address: kept[0].address,
          latitude: kept[0].latitude,
          longitude: kept[0].longitude,
          isPrimary: true,
          source: kept[0].source,
        );
      }
      return person.copyWith(places: kept);
    },
  );
}
