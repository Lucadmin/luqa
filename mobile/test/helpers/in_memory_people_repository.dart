import 'package:luqa/core/id/local_id.dart';
import 'package:luqa/features/people/data/people_repository.dart';
import 'package:luqa/features/people/domain/city_candidate.dart';
import 'package:luqa/features/people/domain/person.dart';

/// People held in memory, for tests.
///
/// The whole write surface rather than a stub that throws, so a widget test
/// exercises the same behaviour the real repository has — a note it writes is
/// a note it can read back — without a database or a network anywhere near it.
///
/// The production path is `LocalFirstPeopleRepository`: sqlite plus the queue
/// it shares with money.
class InMemoryPeopleRepository implements PeopleRepository {
  InMemoryPeopleRepository({List<Person> seed = const []})
    : _people = {for (final person in seed) person.id: person};

  final Map<String, Person> _people;

  /// The seeded rows, for a test that wants to build a variant of them.
  List<Person> get seedPeople => _people.values.toList();

  @override
  Future<List<Person>> loadPeople() async => _people.values.toList();

  @override
  Future<Person> loadPerson(String id) async => _require(id);

  @override
  Future<Person> createPerson({String? id, required PersonWrite write}) async {
    final personId = id ?? newLocalId();
    final person = Person(
      id: personId,
      name: write.name,
      colorValue: write.colorValue,
      emoji: write.emoji,
      defaultPercent: write.defaultPercent,
      // New people go to the end of the arranged order rather than the top:
      // the list the owner built is not reshuffled by an addition.
      order: _people.values.fold(
        0,
        (top, p) => p.order >= top ? p.order + 1 : top,
      ),
      archived: false,
      nickname: write.nickname,
      birthday: write.birthday,
      cadenceDays: write.cadenceDays,
    );
    _people[personId] = person;
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
    int? order,
    String? nickname,
    bool clearNickname = false,
    Birthday? birthday,
    bool clearBirthday = false,
    int? cadenceDays,
    bool clearCadence = false,
    Closeness? closeness,
    bool clearCloseness = false,
    List<PersonConnection>? connections,
    bool? archived,
  }) async => _save(
    _require(id).copyWith(
      name: name,
      colorValue: colorValue,
      emoji: emoji,
      clearEmoji: clearEmoji,
      defaultPercent: defaultPercent,
      clearDefaultPercent: clearDefaultPercent,
      order: order,
      nickname: nickname,
      clearNickname: clearNickname,
      birthday: birthday,
      clearBirthday: clearBirthday,
      cadenceDays: cadenceDays,
      clearCadence: clearCadence,
      closeness: closeness,
      clearCloseness: clearCloseness,
      connections: connections,
      archived: archived,
    ),
  );

  @override
  Future<void> deletePerson(String id) async => _people.remove(id);

  @override
  Future<Person> markSeen(String id, DateTime when) async =>
      _save(_require(id).copyWith(lastSeenAt: when));

  @override
  Future<Person> addNote(
    String personId, {
    String? id,
    required String body,
    bool pinned = false,
    String? happenedOn,
  }) async {
    final person = _require(personId);
    return _save(
      person.copyWith(
        notes: [
          ...person.notes,
          PersonNote(
            id: id ?? newLocalId(),
            body: body,
            createdAt: DateTime.now(),
            pinned: pinned,
            happenedOn: happenedOn,
          ),
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
  }) async {
    final person = _require(personId);
    return _save(
      person.copyWith(
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
  }

  @override
  Future<Person> removeNote(String personId, String noteId) async {
    final person = _require(personId);
    return _save(
      person.copyWith(
        notes: [
          for (final note in person.notes)
            if (note.id != noteId) note,
        ],
      ),
    );
  }

  @override
  Future<Person> addGift(
    String personId, {
    String? id,
    required String idea,
    String? url,
  }) async {
    final person = _require(personId);
    return _save(
      person.copyWith(
        gifts: [
          ...person.gifts,
          GiftIdea(id: id ?? newLocalId(), idea: idea, url: url),
        ],
      ),
    );
  }

  @override
  Future<Person> setGiftGiven(
    String personId, {
    required String giftId,
    DateTime? givenAt,
  }) async {
    final person = _require(personId);
    return _save(
      person.copyWith(
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
  }

  @override
  Future<Person> removeGift(String personId, String giftId) async {
    final person = _require(personId);
    return _save(
      person.copyWith(
        gifts: [
          for (final gift in person.gifts)
            if (gift.id != giftId) gift,
        ],
      ),
    );
  }

  /// What a city search will answer with. Empty by default, because most
  /// tests never open the picker; set it to make one that does.
  List<CityCandidate> cities = const [];

  /// Set to make every search fail the way no connection does, which is the
  /// state the picker offers the typed name from.
  bool searchFails = false;

  /// What was asked for, in order, so a test can prove the debounce collapsed
  /// a burst of keystrokes into one lookup.
  final List<String> searches = [];

  @override
  Future<List<CityCandidate>> searchCities(String query) async {
    searches.add(query);
    if (searchFails) throw StateError('offline');
    return [
      for (final city in cities)
        if (city.name.toLowerCase().startsWith(query.toLowerCase())) city,
    ];
  }

  @override
  Future<Person> addPlace(
    String personId, {
    String? id,
    required String label,
    required String city,
    String? country,
    int? cityId,
    double? latitude,
    double? longitude,
    bool isPrimary = false,
  }) async {
    final person = _require(personId);
    final added = PersonPlace(
      id: id ?? newLocalId(),
      label: label,
      city: city,
      country: country,
      cityId: cityId,
      latitude: latitude,
      longitude: longitude,
      isPrimary: isPrimary || person.places.isEmpty,
    );
    return _save(
      person.copyWith(
        places: [
          // Exactly one primary. A second one marked primary demotes the first
          // rather than leaving the row with two answers to "where are they".
          for (final place in person.places)
            added.isPrimary && place.isPrimary
                ? PersonPlace(
                    id: place.id,
                    label: place.label,
                    city: place.city,
                    region: place.region,
                    country: place.country,
                    address: place.address,
                    cityId: place.cityId,
                    timezone: place.timezone,
                    latitude: place.latitude,
                    longitude: place.longitude,
                    source: place.source,
                  )
                : place,
          added,
        ],
      ),
    );
  }

  @override
  Future<Person> removePlace(String personId, String placeId) async {
    final person = _require(personId);
    return _save(
      person.copyWith(
        places: [
          for (final place in person.places)
            if (place.id != placeId) place,
        ],
      ),
    );
  }

  @override
  Future<bool> geocodePendingPlaces() async {
    // Nothing to resolve: the seeded places already carry the coordinates the
    // map needs, and a test has no business reaching a geocoder.
    return false;
  }

  Person _require(String id) {
    final person = _people[id];
    if (person == null) throw StateError('No person $id');
    return person;
  }

  Person _save(Person person) {
    _people[person.id] = person;
    return person;
  }
}
