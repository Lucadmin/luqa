import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/network/network_failure.dart';
import 'package:luqa/features/people/application/shared_time_provider.dart';
import 'package:luqa/features/people/data/people_providers.dart';
import 'package:luqa/features/people/data/people_repository.dart';
import 'package:luqa/features/people/domain/people_math.dart';
import 'package:luqa/features/people/domain/person.dart';

/// "Now" as the People tab sees it, so a test can pin the day a birthday is
/// counted down from.
final peopleNowProvider = Provider<DateTime>((ref) => DateTime.now());

final peopleControllerProvider =
    NotifierProvider<PeopleController, PeopleState>(PeopleController.new);

class PeopleState {
  const PeopleState({
    this.people = const [],
    this.isLoading = true,
    this.isRefreshing = false,
    this.loaded = false,
    this.error,
  });

  final List<Person> people;
  final bool isLoading;
  final bool isRefreshing;

  /// True once a load has actually returned. Distinguishes "nobody yet" from
  /// "not asked yet", which are the same empty list and very different screens.
  final bool loaded;

  final String? error;

  /// Everyone worth listing: active people, ordered the way the owner arranged
  /// them and then by name, which is how a list of names is looked through.
  List<Person> get listed {
    final active = [
      for (final person in people)
        if (!person.archived) person,
    ];
    active.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0
          ? byOrder
          : a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return active;
  }

  List<Person> get archived => [
    for (final person in people)
      if (person.archived) person,
  ];

  Person? byId(String id) {
    for (final person in people) {
      if (person.id == id) return person;
    }
    return null;
  }

  PeopleState copyWith({
    List<Person>? people,
    bool? isLoading,
    bool? isRefreshing,
    bool? loaded,
    String? error,
    bool clearError = false,
  }) => PeopleState(
    people: people ?? this.people,
    isLoading: isLoading ?? this.isLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    loaded: loaded ?? this.loaded,
    error: clearError ? null : error ?? this.error,
  );
}

class PeopleController extends Notifier<PeopleState> {
  @override
  PeopleState build() {
    Future.microtask(load);
    return const PeopleState();
  }

  PeopleRepository get _repository => ref.read(peopleRepositoryProvider);

  Future<void> load() => _fetch(refreshing: false);

  Future<void> refresh() => _fetch(refreshing: true);

  Future<void> _fetch({required bool refreshing}) async {
    if (!ref.mounted) return;
    state = state.copyWith(
      isLoading: !refreshing && !state.loaded,
      isRefreshing: refreshing,
      clearError: true,
    );
    try {
      final people = await _repository.loadPeople();
      if (!ref.mounted) return;
      state = state.copyWith(
        people: people,
        isLoading: false,
        isRefreshing: false,
        loaded: true,
      );
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        // A refresh that fails over a list already on screen is a line, not a
        // wipe: the cached people are still the best answer available.
        error: describeNetworkFailure(error, whileDoing: 'loading your people'),
      );
    }
  }

  Future<Person?> addPerson(PersonWrite write) async {
    Person? created;
    final ok = await _write('adding the person', () async {
      created = await _repository.createPerson(write: write);
      _apply(created!);
    });
    return ok ? created : null;
  }

  Future<bool> updatePerson({
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
  }) => _write('saving the person', () async {
    _apply(
      await _repository.updatePerson(
        id: id,
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
  });

  Future<bool> deletePerson(String id) =>
      _write('removing the person', () async {
        await _repository.deletePerson(id);
        if (!ref.mounted) return;
        state = state.copyWith(
          people: [
            for (final person in state.people)
              if (person.id != id) person,
          ],
        );
      });

  Future<bool> markSeen(String id, DateTime when) =>
      _write('recording the catch-up', () async {
        _apply(await _repository.markSeen(id, when));
      });

  Future<bool> addNote(
    String personId, {
    required String body,
    bool pinned = false,
    String? happenedOn,
  }) => _write('saving the note', () async {
    _apply(
      await _repository.addNote(
        personId,
        body: body,
        pinned: pinned,
        happenedOn: happenedOn,
      ),
    );
  });

  Future<bool> setNotePinned(
    String personId, {
    required String noteId,
    required bool pinned,
  }) => _write('pinning the note', () async {
    _apply(
      await _repository.updateNote(personId, noteId: noteId, pinned: pinned),
    );
  });

  Future<bool> removeNote(String personId, String noteId) =>
      _write('removing the note', () async {
        _apply(await _repository.removeNote(personId, noteId));
      });

  Future<bool> addGift(String personId, {required String idea, String? url}) =>
      _write('saving the gift idea', () async {
        _apply(await _repository.addGift(personId, idea: idea, url: url));
      });

  Future<bool> setGiftGiven(
    String personId, {
    required String giftId,
    DateTime? givenAt,
  }) => _write('updating the gift idea', () async {
    _apply(
      await _repository.setGiftGiven(
        personId,
        giftId: giftId,
        givenAt: givenAt,
      ),
    );
  });

  Future<bool> removeGift(String personId, String giftId) =>
      _write('removing the gift idea', () async {
        _apply(await _repository.removeGift(personId, giftId));
      });

  Future<bool> addPlace(
    String personId, {
    required String label,
    required String city,
    String? country,
    bool isPrimary = false,
  }) => _write('saving the place', () async {
    _apply(
      await _repository.addPlace(
        personId,
        label: label,
        city: city,
        country: country,
        isPrimary: isPrimary,
      ),
    );
  });

  Future<bool> removePlace(String personId, String placeId) =>
      _write('removing the place', () async {
        _apply(await _repository.removePlace(personId, placeId));
      });

  /// Asks for points on the cities that have none, then re-reads.
  ///
  /// Bounded per call, so it loops while there are more — a first sync of a
  /// contact book with twenty cities in it needs a few passes, and each one
  /// costs a second per city against a rate-limited geocoder.
  Future<void> geocodePlaces({int maxRounds = 4}) async {
    for (var round = 0; round < maxRounds; round++) {
      final more = await _repository.geocodePendingPlaces();
      if (!ref.mounted) return;
      await _fetch(refreshing: true);
      if (!more) return;
    }
  }

  /// Slots an updated person back into the list in place, so a screen never
  /// flickers through an empty state to show a changed name.
  void _apply(Person person) {
    if (!ref.mounted) return;
    final existing = state.people.any((other) => other.id == person.id);
    state = state.copyWith(
      people: existing
          ? [
              for (final other in state.people)
                if (other.id == person.id) person else other,
            ]
          : [...state.people, person],
    );
  }

  Future<bool> _write(String action, Future<void> Function() body) async {
    try {
      await body();
      if (ref.mounted) state = state.copyWith(clearError: true);
      return true;
    } on Object catch (error) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        error: describeNetworkFailure(error, whileDoing: action),
      );
      return false;
    }
  }
}

/// The screen's derived view of the roster, recomputed only when the people or
/// the day actually change.
final peopleFocusProvider = Provider<PeopleFocus>((ref) {
  final people = ref.watch(peopleControllerProvider).listed;
  return peopleFocus(
    people,
    ref.watch(peopleNowProvider),
    lastSeen: ref.watch(lastSeenProvider),
  );
});

final overdueContactsProvider = Provider<List<OverdueContact>>((ref) {
  final people = ref.watch(peopleControllerProvider).listed;
  return overdueContacts(
    people,
    ref.watch(peopleNowProvider),
    // A dinner logged on the timeline counts as having seen them, which is the
    // whole point of tagging it.
    lastSeen: ref.watch(lastSeenProvider),
  );
});

final upcomingBirthdaysProvider = Provider<List<UpcomingBirthday>>((ref) {
  final people = ref.watch(peopleControllerProvider).listed;
  return upcomingBirthdays(people, ref.watch(peopleNowProvider));
});

final peopleByCityProvider = Provider<List<PeopleInCity>>(
  (ref) => peopleByCity(ref.watch(peopleControllerProvider).listed),
);
