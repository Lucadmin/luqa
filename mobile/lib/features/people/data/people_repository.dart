import 'package:luqa/features/people/domain/city_candidate.dart';
import 'package:luqa/features/people/domain/person.dart';

/// The fields a person can be created or edited with in one go.
///
/// Identity and profile together: the People tab and Money's person editor are
/// two views of one write, so there is one shape for both and one place where
/// a rename happens.
class PersonWrite {
  const PersonWrite({
    required this.name,
    required this.colorValue,
    this.emoji,
    this.defaultPercent,
    this.nickname,
    this.birthday,
    this.cadenceDays,
  });

  final String name;
  final int colorValue;
  final String? emoji;
  final int? defaultPercent;
  final String? nickname;
  final Birthday? birthday;
  final int? cadenceDays;
}

/// Everything the People tab reads and writes.
///
/// The child rows are edited through the person rather than on their own: a
/// note belongs to somebody, and returning the whole updated `Person` keeps
/// the caller from having to reassemble one.
abstract interface class PeopleRepository {
  Future<List<Person>> loadPeople();

  Future<Person> loadPerson(String id);

  /// [id] is the identity the device already gave the person, which makes the
  /// create idempotent: a retry after a lost response cannot leave two of the
  /// same friend in the list.
  Future<Person> createPerson({String? id, required PersonWrite write});

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
  });

  Future<void> deletePerson(String id);

  /// Records that they were actually seen. The one write the person screen
  /// makes most often.
  Future<Person> markSeen(String id, DateTime when);

  Future<Person> addNote(
    String personId, {
    String? id,
    required String body,
    bool pinned = false,
    String? happenedOn,
  });

  Future<Person> updateNote(
    String personId, {
    required String noteId,
    String? body,
    bool? pinned,
  });

  Future<Person> removeNote(String personId, String noteId);

  Future<Person> addGift(
    String personId, {
    String? id,
    required String idea,
    String? url,
  });

  /// Marks a gift given, or puts it back on the list when [givenAt] is null.
  Future<Person> setGiftGiven(
    String personId, {
    required String giftId,
    DateTime? givenAt,
  });

  Future<Person> removeGift(String personId, String giftId);

  /// The cities [query] might mean, best match first.
  ///
  /// Online only, and it says so by throwing rather than by answering with an
  /// empty list: "no connection" and "no such city" lead somewhere different
  /// in the picker, and a caller that cannot tell them apart shows the wrong
  /// one.
  Future<List<CityCandidate>> searchCities(String query);

  /// [cityId] is the city that was chosen, from [searchCities]. With one, the
  /// server resolves the point itself and the place pins immediately; without
  /// one — offline, most likely — the name is taken as typed and the geocoding
  /// batch guesses at it later.
  ///
  /// [latitude] and [longitude] are the chosen city's, used only to draw this
  /// device's own copy before the server has answered. The server never reads
  /// them; its answer replaces them.
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
  });

  Future<Person> removePlace(String personId, String placeId);

  /// Asks the server to put points on the cities that have none.
  ///
  /// Only cities that were typed rather than chosen end up needing this: one
  /// added through the picker arrives with its point already on it. Still its
  /// own call rather than part of a read — it is bounded, it talks to a third
  /// party, and the map is perfectly usable as a list before it has run.
  ///
  /// Returns true while cities are still waiting, so a caller can ask again.
  Future<bool> geocodePendingPlaces();
}
