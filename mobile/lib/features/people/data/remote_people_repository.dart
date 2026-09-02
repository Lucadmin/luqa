import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/money/data/remote_money_repository.dart'
    show hexColor, personFromApi;
import 'package:luqa/features/people/data/people_repository.dart';
import 'package:luqa/features/people/domain/city_candidate.dart';
import 'package:luqa/features/people/domain/person.dart';
import 'package:luqa_api/api.dart' as api;

/// The People contract, over the network.
///
/// Every write answers with the whole person, which is why none of these
/// methods have to reassemble one: one row is one profile, and the server's
/// copy of it is authoritative the moment it replies.
class RemotePeopleRepository implements PeopleRepository {
  RemotePeopleRepository(this.client);

  final LuqaApi client;

  @override
  Future<List<Person>> loadPeople() async =>
      (await client.listPeople()).map(personFromApi).toList(growable: false);

  @override
  Future<Person> loadPerson(String id) async {
    final people = await loadPeople();
    return people.firstWhere(
      (person) => person.id == id,
      orElse: () => throw StateError('No person $id'),
    );
  }

  @override
  Future<Person> createPerson({
    String? id,
    required PersonWrite write,
  }) async => personFromApi(
    await client.createPerson(
      api.CreatePersonRequest(
        id: _present(id),
        name: write.name,
        color: api.Optional.present(hexColor(write.colorValue)),
        emoji: api.Optional.present(write.emoji),
        defaultPercent: api.Optional.present(write.defaultPercent),
        nickname: api.Optional.present(write.nickname),
        // The birthday travels as three parts or as three nulls. Sending a
        // month without a day would be half a birthday, which the server
        // refuses and no screen can count down to.
        birthdayYear: api.Optional.present(write.birthday?.year),
        birthdayMonth: api.Optional.present(write.birthday?.month),
        birthdayDay: api.Optional.present(write.birthday?.day),
        cadenceDays: api.Optional.present(write.cadenceDays),
      ),
    ),
  );

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
  }) async => personFromApi(
    await client.updatePerson(
      id,
      api.UpdatePersonRequest(
        name: _present(name),
        color: colorValue == null
            ? const api.Optional.absent()
            : api.Optional.present(hexColor(colorValue)),
        emoji: clearEmoji || emoji != null
            ? api.Optional.present(emoji)
            : const api.Optional.absent(),
        defaultPercent: clearDefaultPercent || defaultPercent != null
            ? api.Optional.present(defaultPercent)
            : const api.Optional.absent(),
        nickname: clearNickname || nickname != null
            ? api.Optional.present(nickname)
            : const api.Optional.absent(),
        birthdayYear: clearBirthday || birthday != null
            ? api.Optional.present(birthday?.year)
            : const api.Optional.absent(),
        birthdayMonth: clearBirthday || birthday != null
            ? api.Optional.present(birthday?.month)
            : const api.Optional.absent(),
        birthdayDay: clearBirthday || birthday != null
            ? api.Optional.present(birthday?.day)
            : const api.Optional.absent(),
        cadenceDays: clearCadence || cadenceDays != null
            ? api.Optional.present(cadenceDays)
            : const api.Optional.absent(),
        archived: _present(archived),
      ),
    ),
  );

  @override
  Future<void> deletePerson(String id) => client.deletePerson(id);

  @override
  Future<Person> markSeen(String id, DateTime when) async => personFromApi(
    await client.markPersonSeen(
      id,
      api.MarkSeenRequest(seenAt: api.Optional.present(when.toUtc())),
    ),
  );

  @override
  Future<Person> addNote(
    String personId, {
    String? id,
    required String body,
    bool pinned = false,
    String? happenedOn,
  }) async => personFromApi(
    await client.addPersonNote(
      personId,
      api.CreatePersonNoteRequest(
        id: _present(id),
        body: body,
        pinned: api.Optional.present(pinned),
        happenedOn: api.Optional.present(happenedOn),
      ),
    ),
  );

  @override
  Future<Person> updateNote(
    String personId, {
    required String noteId,
    String? body,
    bool? pinned,
  }) async => personFromApi(
    await client.updatePersonNote(
      personId,
      noteId,
      api.UpdatePersonNoteRequest(
        body: _present(body),
        pinned: _present(pinned),
      ),
    ),
  );

  @override
  Future<Person> removeNote(String personId, String noteId) async =>
      personFromApi(await client.deletePersonNote(personId, noteId));

  @override
  Future<Person> addGift(
    String personId, {
    String? id,
    required String idea,
    String? url,
  }) async => personFromApi(
    await client.addPersonGift(
      personId,
      api.CreatePersonGiftRequest(
        id: _present(id),
        idea: idea,
        url: api.Optional.present(url),
      ),
    ),
  );

  @override
  Future<Person> setGiftGiven(
    String personId, {
    required String giftId,
    DateTime? givenAt,
  }) async => personFromApi(
    await client.updatePersonGift(
      personId,
      giftId,
      // Always present, never absent: null is the instruction that puts the
      // idea back on the list, and an absent field would mean "leave it".
      api.UpdatePersonGiftRequest(
        givenAt: api.Optional.present(givenAt?.toUtc()),
      ),
    ),
  );

  @override
  Future<Person> removeGift(String personId, String giftId) async =>
      personFromApi(await client.deletePersonGift(personId, giftId));

  @override
  Future<List<CityCandidate>> searchCities(String query) async => [
    for (final result in await client.searchCities(query))
      CityCandidate(
        id: result.id,
        name: result.name,
        admin1: result.admin1,
        country: result.country,
        countryCode: result.countryCode,
        latitude: result.latitude.toDouble(),
        longitude: result.longitude.toDouble(),
        timezone: result.timezone,
        population: result.population,
      ),
  ];

  @override
  Future<Person> addPlace(
    String personId, {
    String? id,
    required String label,
    required String city,
    String? country,
    int? cityId,
    // The server resolves the point from `cityId` and ignores anything this
    // device thinks it knows about where the city is, so neither is sent.
    double? latitude,
    double? longitude,
    bool isPrimary = false,
  }) async => personFromApi(
    await client.addPersonPlace(
      personId,
      api.CreatePersonPlaceRequest(
        id: _present(id),
        label: label,
        city: city,
        country: api.Optional.present(country),
        cityId: api.Optional.present(cityId),
        isPrimary: api.Optional.present(isPrimary),
      ),
    ),
  );

  @override
  Future<Person> removePlace(String personId, String placeId) async =>
      personFromApi(await client.deletePersonPlace(personId, placeId));

  @override
  Future<bool> geocodePendingPlaces() async =>
      (await client.geocodePendingPlaces()).remaining > 0;
}

/// A value that is being set, or a field the request should not mention.
api.Optional<T> _present<T>(T? value) =>
    value == null ? api.Optional.absent() : api.Optional.present(value);
