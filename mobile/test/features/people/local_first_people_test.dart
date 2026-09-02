import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/core/storage/luqa_store.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/money/data/money_fold.dart';
import 'package:luqa/features/money/data/money_local_store.dart';
import 'package:luqa/features/money/data/money_outbox.dart';
import 'package:luqa/features/people/data/local_first_people_repository.dart';
import 'package:luqa/features/people/data/people_repository.dart';
import 'package:luqa/features/people/data/people_sync_service.dart';
import 'package:luqa/features/people/data/remote_people_repository.dart';
import 'package:luqa/features/people/domain/person.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_store.dart';

/// Stands in for the sync engine's queue: folds like the real one, keeps what
/// it is given, and never sends anything.
class _TestQueue implements MutationQueue<MoneyMutation> {
  List<MoneyMutation> _queue = const [];

  @override
  Future<void> get ready async {}

  @override
  List<MoneyMutation> get pending => _queue;

  @override
  Future<void> sync() async {}

  @override
  Future<void> enqueue(MoneyMutation mutation, {bool sendNow = true}) async {
    _queue = foldMoney(_queue, mutation);
  }
}

/// A network that is never reached. Every read here is answered from the
/// device, which is the whole claim being tested.
class _UnreachableApi implements LuqaApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final _now = DateTime(2026, 8, 27, 12);

void main() {
  sqfliteFfiInit();

  late LuqaStore store;
  late MoneyLocalStore local;
  late _TestQueue queue;
  late LocalFirstPeopleRepository repository;

  setUp(() {
    store = openTestStore();
    addTearDown(store.close);
    local = MoneyLocalStore(namespace: 'user-a', store: store);
    queue = _TestQueue();
    repository = LocalFirstPeopleRepository(
      store: local,
      sync: PeopleSyncService(client: _UnreachableApi(), store: local),
      remote: RemotePeopleRepository(_UnreachableApi()),
      queue: queue,
      now: () => _now,
    );
  });

  Future<Person> givenPerson(String name, {Birthday? birthday}) =>
      repository.createPerson(
        write: PersonWrite(
          name: name,
          colorValue: 0xFF112233,
          birthday: birthday,
        ),
      );

  group('the record survives the round trip through sqlite', () {
    test('a person keeps their birthday, nickname and rhythm', () async {
      final created = await repository.createPerson(
        write: const PersonWrite(
          name: 'Jonas Brehm',
          colorValue: 0xFF2563EB,
          nickname: 'Jo',
          birthday: Birthday(month: 2, day: 29, year: 1996),
          cadenceDays: 61,
        ),
      );

      final read = await repository.loadPerson(created.id);
      expect(read.nickname, 'Jo');
      expect(read.birthday, const Birthday(month: 2, day: 29, year: 1996));
      expect(read.cadenceDays, 61);
    });

    test('a birthday with no year comes back with no year', () async {
      // The case that matters: a stored zero or a defaulted year would show a
      // confidently wrong age next to their name.
      final person = await givenPerson(
        'Tessa',
        birthday: const Birthday(month: 11, day: 12),
      );

      final read = await repository.loadPerson(person.id);
      expect(read.birthday!.hasYear, isFalse);
      expect(read.birthday!.year, isNull);
    });

    test('notes, gifts and places all come back', () async {
      final person = await givenPerson('Mira');
      await repository.addNote(person.id, body: 'Allergic to hazelnuts');
      await repository.addGift(person.id, idea: 'Kiln time');
      await repository.addPlace(person.id, label: 'Home', city: 'Munich');

      final read = await repository.loadPerson(person.id);
      expect(read.notes.single.body, 'Allergic to hazelnuts');
      expect(read.gifts.single.idea, 'Kiln time');
      expect(read.places.single.city, 'Munich');
    });

    test('one person\'s record does not leak onto another', () async {
      final mira = await givenPerson('Mira');
      final jonas = await givenPerson('Jonas');
      await repository.addNote(mira.id, body: 'Ceramics course');

      expect((await repository.loadPerson(jonas.id)).notes, isEmpty);
      expect((await repository.loadPerson(mira.id)).notes, hasLength(1));
    });

    test('renaming somebody does not drop their notes', () async {
      // `putPerson` replaces the children wholesale, so an edit that forgot to
      // carry them would silently erase everything written about the person.
      final person = await givenPerson('Mira');
      await repository.addNote(person.id, body: 'Ceramics course');

      await repository.updatePerson(id: person.id, name: 'Mira Hensel');

      final read = await repository.loadPerson(person.id);
      expect(read.name, 'Mira Hensel');
      expect(read.notes.single.body, 'Ceramics course');
    });

    test('manual closeness and connections survive sqlite', () async {
      final mira = await givenPerson('Mira');
      final jonas = await givenPerson('Jonas');

      await repository.updatePerson(
        id: mira.id,
        closeness: Closeness.innerCircle,
        connections: [
          PersonConnection(personId: jonas.id, closeness: Closeness.close),
        ],
      );

      final read = await repository.loadPerson(mira.id);
      expect(read.closeness, Closeness.innerCircle);
      expect(read.connections.single.personId, jonas.id);
      expect(read.connections.single.closeness, Closeness.close);
    });
  });

  group('writing offline', () {
    test('a note is on the device and in the queue', () async {
      final person = await givenPerson('Mira');
      await repository.addNote(person.id, body: 'Moving to Lisbon');

      expect((await repository.loadPerson(person.id)).notes, hasLength(1));
      expect(queue.pending.whereType<AddPersonNote>(), hasLength(1));
    });

    test('an abandoned note names the person, not an id', () async {
      // The only time this string is ever shown is when the write is lost and
      // the user has to be told what to type again.
      final person = await givenPerson('Mira');
      await repository.addNote(person.id, body: 'Moving to Lisbon in spring');

      final queued = queue.pending.whereType<AddPersonNote>().single;
      expect(queued.describe(), contains('Mira'));
      expect(queued.describe(), contains('Moving to Lisbon'));
    });

    test('a note written and removed before syncing never leaves', () async {
      final person = await givenPerson('Mira');
      final withNote = await repository.addNote(person.id, body: 'Typo');
      await repository.removeNote(person.id, withNote.notes.first.id);

      // Neither write is left: the removal would 404 on a note the server has
      // never seen, and being told that a change the user already undid was
      // lost is worse than useless.
      expect(queue.pending.whereType<AddPersonNote>(), isEmpty);
      expect(queue.pending.whereType<RemovePersonNote>(), isEmpty);
    });

    test('seeing somebody twice before a sync is one write', () async {
      final person = await givenPerson('Mira');
      await repository.markSeen(person.id, _now);
      await repository.markSeen(person.id, _now.add(const Duration(hours: 2)));

      expect(queue.pending.whereType<MarkPersonSeen>(), hasLength(1));
    });

    test('a relationship choice stays behind a pending create', () async {
      final person = await givenPerson('Mira');
      await repository.updatePerson(id: person.id, closeness: Closeness.close);

      // The create must land before a PATCH that may eventually point to a
      // second locally-created person. It is deliberately not folded into the
      // create payload.
      expect(queue.pending, hasLength(2));
      expect(queue.pending.first, isA<CreatePerson>());
      expect(queue.pending.last, isA<UpdatePerson>());
    });

    test('removing a person drops the record still queued for them', () async {
      final person = await givenPerson('Mira');
      await repository.addNote(person.id, body: 'Ceramics');
      await repository.addGift(person.id, idea: 'Kiln time');

      await repository.deletePerson(person.id);

      // Nothing left pointing at somebody who is going away: those writes have
      // nowhere to land.
      expect(queue.pending.whereType<AddPersonNote>(), isEmpty);
      expect(queue.pending.whereType<AddPersonGift>(), isEmpty);
    });

    test('a removed person is gone from the roster immediately', () async {
      final person = await givenPerson('Mira');
      await repository.deletePerson(person.id);

      expect(await repository.loadPeople(), isEmpty);
    });
  });

  group('places', () {
    test('the first city is primary whether or not it was asked for', () async {
      // A person with one city and no primary has no answer to "where are
      // they", which is the only question the map screen asks.
      final person = await givenPerson('Mira');
      final withPlace = await repository.addPlace(
        person.id,
        label: 'Home',
        city: 'Munich',
      );

      expect(withPlace.places.single.isPrimary, isTrue);
      expect(withPlace.primaryPlace!.city, 'Munich');
    });

    test('a second primary demotes the first', () async {
      final person = await givenPerson('Jonas');
      await repository.addPlace(person.id, label: 'Home', city: 'Berlin');
      final moved = await repository.addPlace(
        person.id,
        label: 'Home',
        city: 'Hamburg',
        isPrimary: true,
      );

      expect(moved.places.where((place) => place.isPrimary), hasLength(1));
      expect(moved.primaryPlace!.city, 'Hamburg');
    });

    test('removing the primary promotes the next one', () async {
      final person = await givenPerson('Jonas');
      final first = await repository.addPlace(
        person.id,
        label: 'Home',
        city: 'Berlin',
      );
      await repository.addPlace(person.id, label: 'Parents', city: 'Hamburg');

      final left = await repository.removePlace(
        person.id,
        first.places.single.id,
      );

      // "Where are they" must not go blank while cities are still on file.
      expect(left.places, hasLength(1));
      expect(left.primaryPlace!.city, 'Hamburg');
    });

    test('a chosen city pins before the server has heard of it', () async {
      // The point comes from the candidate that was tapped, so the map is
      // right on this device immediately. The server resolves the same point
      // from the id and its answer replaces this one on the next pull.
      final person = await givenPerson('Mira');
      final withPlace = await repository.addPlace(
        person.id,
        label: 'Home',
        city: 'Munich',
        cityId: 2867714,
        latitude: 48.13743,
        longitude: 11.57549,
      );

      final place = withPlace.places.single;
      expect(place.cityId, 2867714);
      expect(place.isMappable, isTrue);
      expect(
        (await repository.loadPerson(person.id)).places.single.cityId,
        2867714,
      );
    });

    test('the chosen city travels with the queued write', () async {
      // Without the id on the mutation, a city picked offline would reach the
      // server as a bare name and be guessed at — which is exactly what the
      // picker exists to stop.
      final person = await givenPerson('Mira');
      await repository.addPlace(
        person.id,
        label: 'Home',
        city: 'Munich',
        cityId: 2867714,
        latitude: 48.13743,
        longitude: 11.57549,
      );

      final queued = queue.pending.whereType<AddPersonPlace>().single;
      expect(queued.cityId, 2867714);
    });

    test('a city typed with no connection queues without one', () async {
      // The offline path, unchanged: the place lists straight away, unpinned,
      // and the server's geocoding batch puts a point on it later.
      final person = await givenPerson('Jonas');
      final withPlace = await repository.addPlace(
        person.id,
        label: 'Home',
        city: 'Hamburg',
      );

      expect(withPlace.places.single.cityId, isNull);
      expect(withPlace.places.single.isMappable, isFalse);
      expect(queue.pending.whereType<AddPersonPlace>().single.cityId, isNull);
    });
  });

  group('gifts', () {
    test('a given idea stays on the list', () async {
      final person = await givenPerson('Mira');
      final withGift = await repository.addGift(person.id, idea: 'Kiln time');

      final given = await repository.setGiftGiven(
        person.id,
        giftId: withGift.gifts.single.id,
        givenAt: _now,
      );

      // The list's second job is not giving the same thing twice.
      expect(given.gifts, hasLength(1));
      expect(given.gifts.single.isGiven, isTrue);
      expect(given.openGifts, isEmpty);
    });

    test('unmarking a gift puts it back on the list', () async {
      final person = await givenPerson('Mira');
      final withGift = await repository.addGift(person.id, idea: 'Kiln time');
      final giftId = withGift.gifts.single.id;
      await repository.setGiftGiven(person.id, giftId: giftId, givenAt: _now);

      final back = await repository.setGiftGiven(person.id, giftId: giftId);
      expect(back.openGifts, hasLength(1));
    });
  });

  test('adding somebody already known by name is the same person', () async {
    // The rule the server applies, applied here too, so the same "Mira" added
    // twice offline does not become two rows for the server to merge.
    final first = await givenPerson('Mira');
    final second = await givenPerson('mira');

    expect(second.id, first.id);
    expect(await repository.loadPeople(), hasLength(1));
  });
}
