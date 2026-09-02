import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/people/domain/city_candidate.dart';
import 'package:luqa/features/people/presentation/widgets/people_map.dart';
import 'package:luqa/features/today/presentation/widgets/timeline_view.dart';

import '../../helpers/fake_people_repository.dart';
import '../../helpers/pump_luqa.dart';

Future<void> openPeople(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.group_outlined));
  await tester.pumpAndSettle();
}

/// The roster is longer than the screen, so reaching somebody means scrolling
/// to them first — the same thing a hand does.
Future<void> openPerson(WidgetTester tester, String id) async {
  final row = find.byKey(ValueKey('person-$id'));
  await tester.scrollUntilVisible(row, 120);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

/// Brings a control inside an open sheet into reach.
Future<void> scrollSheetTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    120,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('leads with the nearest birthday', (tester) async {
    await pumpLuqa(tester);
    await openPeople(tester);

    final focus = find.byKey(const ValueKey('people-focus-birthday'));
    expect(focus, findsOneWidget);
    expect(
      find.descendant(of: focus, matching: find.text('Mira Hensel')),
      findsOneWidget,
    );
    // Eight days out from the pinned 27 August, turning 29.
    expect(
      find.descendant(of: focus, matching: find.text('in 8 days · turns 29')),
      findsOneWidget,
    );
  });

  testWidgets('names only the people actually past their cadence', (
    tester,
  ) async {
    await pumpLuqa(tester);
    await openPeople(tester);

    expect(find.byKey(const ValueKey('overdue-tessa')), findsOneWidget);
    // Piet has a rhythm and is keeping it, so he is in the roster and not
    // in the overdue list. Somebody with no cadence is never here at all.
    expect(find.byKey(const ValueKey('overdue-piet')), findsNothing);
    expect(find.byKey(const ValueKey('overdue-alina')), findsNothing);
  });

  testWidgets('a shared bill counts as having seen them', (tester) async {
    // Jonas's contact card says five months, but he was on a bill yesterday.
    // Money already knew they had dinner; asking the owner to also tick a box
    // on his card would be asking twice for one fact — so he is not overdue,
    // whatever the typed date says.
    await pumpLuqa(tester);
    await openPeople(tester);

    expect(find.byKey(const ValueKey('overdue-jonas')), findsNothing);
    expect(find.byKey(const ValueKey('person-jonas')), findsOneWidget);
  });

  testWidgets('tagging a block of time is how you record seeing someone', (
    tester,
  ) async {
    // The other half of the same rule, end to end: putting Tessa on a block
    // of time is the record that today is when you last saw her, so her
    // contact card needs no second answer to the same question.
    await pumpLuqa(tester);
    await openPeople(tester);
    expect(find.byKey(const ValueKey('overdue-tessa')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(TimelineView),
        matching: find.text('Gym'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('editor-people')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('person-option-tessa')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('person-picker-done')));
    await tester.pumpAndSettle();

    // The editor names her rather than counting her.
    expect(find.text('Tessa Lund'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('editor-save-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.group_outlined));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('overdue-tessa')), findsNothing);
  });

  testWidgets('shows the nickname, keeping the real name underneath', (
    tester,
  ) async {
    await pumpLuqa(tester);
    await openPeople(tester);
    await openPerson(tester, 'jonas');

    expect(find.text('Jo'), findsWidgets);
    expect(find.text('Jonas Brehm'), findsOneWidget);
  });

  testWidgets('leaves archived people out of the roster', (tester) async {
    await pumpLuqa(tester);
    await openPeople(tester);

    expect(find.text('Nils Aigner'), findsNothing);
  });

  testWidgets('search matches a city as well as a name', (tester) async {
    await pumpLuqa(tester);
    await openPeople(tester);
    await tester.tap(find.byKey(const ValueKey('people-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('people-search-field')),
      'hamburg',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('person-tessa')), findsOneWidget);
    expect(find.byKey(const ValueKey('person-piet')), findsOneWidget);
    expect(find.byKey(const ValueKey('person-mira')), findsNothing);
  });

  /// The two Cambridges, as the search would offer them.
  const cambridges = [
    CityCandidate(
      id: 2653941,
      name: 'Cambridge',
      admin1: 'England',
      country: 'United Kingdom',
      countryCode: 'GB',
      latitude: 52.2,
      longitude: 0.11,
      timezone: 'Europe/London',
      population: 145700,
    ),
    CityCandidate(
      id: 4931972,
      name: 'Cambridge',
      admin1: 'Massachusetts',
      country: 'United States',
      countryCode: 'US',
      latitude: 42.3751,
      longitude: -71.1056,
      timezone: 'America/New_York',
      population: 118403,
    ),
  ];

  /// Opens the city picker on somebody and types [query] into it, waiting out
  /// the debounce so the search has actually run.
  Future<void> openCityPicker(
    WidgetTester tester, {
    required String personId,
    required String query,
  }) async {
    await openPeople(tester);
    await openPerson(tester, personId);
    await scrollSheetTo(tester, find.byKey(const ValueKey('person-add-place')));
    await tester.tap(find.byKey(const ValueKey('person-add-place')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('place-city')), query);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('the owner picks which Cambridge, and it pins on the spot', (
    tester,
  ) async {
    // The whole point of the feature. Typed and handed to a geocoder, this
    // name resolves to whichever Cambridge came back first; here it is asked.
    final repository = fakePeopleRepository(now: fixedNow)..cities = cambridges;
    await pumpLuqa(tester, peopleRepository: repository);
    await openCityPicker(tester, personId: 'alina', query: 'Cambridge');

    // Two rows that would read identically without their region.
    expect(find.text('England, United Kingdom · 146k'), findsOneWidget);
    expect(find.text('Massachusetts, United States · 118k'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('city-candidate-4931972')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('place-add')));
    await tester.pumpAndSettle();

    final place = (await repository.loadPerson('alina')).places.single;
    expect(place.cityId, 4931972);
    expect(place.city, 'Cambridge');
    // Pinned on the way in, rather than waiting for the geocoding batch.
    expect(place.isMappable, isTrue);
    expect(place.latitude, 42.3751);
  });

  testWidgets('with no connection the typed name is offered as it stands', (
    tester,
  ) async {
    // Local-first is the rule the People tab is built on, so a city added on a
    // train still has to land. It lists without a pin and the server's batch
    // resolves it later — which the sheet says out loud rather than failing.
    final repository = fakePeopleRepository(now: fixedNow)..searchFails = true;
    await pumpLuqa(tester, peopleRepository: repository);
    await openCityPicker(tester, personId: 'alina', query: 'Cambridge');

    expect(
      find.text('No connection, so the city list is not available.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('place-as-typed')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('place-add')));
    await tester.pumpAndSettle();

    final place = (await repository.loadPerson('alina')).places.single;
    expect(place.city, 'Cambridge');
    expect(place.cityId, isNull);
    expect(place.isMappable, isFalse);
  });

  testWidgets('a name that matches nothing is a different sentence', (
    tester,
  ) async {
    // "Could not ask" and "there is no such place" send a person to two
    // different fixes, so they must not share a message.
    final repository = fakePeopleRepository(now: fixedNow)..cities = cambridges;
    await pumpLuqa(tester, peopleRepository: repository);
    await openCityPicker(tester, personId: 'alina', query: 'Cambrdige');

    expect(find.text('No city called “Cambrdige”.'), findsOneWidget);
  });

  testWidgets('typing a city name is one lookup, not one per keystroke', (
    tester,
  ) async {
    // Every keystroke reaching the server would be nine requests to walk to
    // "Cambridge", eight of them already stale by the time they answered.
    final repository = fakePeopleRepository(now: fixedNow)..cities = cambridges;
    await pumpLuqa(tester, peopleRepository: repository);
    await openPeople(tester);
    await openPerson(tester, 'alina');
    await scrollSheetTo(tester, find.byKey(const ValueKey('person-add-place')));
    await tester.tap(find.byKey(const ValueKey('person-add-place')));
    await tester.pumpAndSettle();

    for (final prefix in const ['Cam', 'Camb', 'Cambr', 'Cambridge']) {
      await tester.enterText(find.byKey(const ValueKey('place-city')), prefix);
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(repository.searches, ['Cambridge']);
  });

  testWidgets('a note is written and stays on the person', (tester) async {
    final repository = fakePeopleRepository(now: fixedNow);
    await pumpLuqa(tester, peopleRepository: repository);
    await openPeople(tester);
    await openPerson(tester, 'alina');

    await tester.enterText(
      find.byKey(const ValueKey('person-note-field')),
      'Moving to Lisbon in spring.',
    );
    await tester.tap(find.byKey(const ValueKey('person-note-add')));
    await tester.pumpAndSettle();

    expect(find.text('Moving to Lisbon in spring.'), findsOneWidget);
    final saved = await repository.loadPerson('alina');
    expect(saved.notes.single.body, 'Moving to Lisbon in spring.');
  });

  testWidgets('pinned notes sort above the rest', (tester) async {
    await pumpLuqa(tester);
    await openPeople(tester);
    await openPerson(tester, 'mira');

    final pinned = tester.getTopLeft(
      find.byKey(const ValueKey('note-mira-note-1')),
    );
    final recent = tester.getTopLeft(
      find.byKey(const ValueKey('note-mira-note-2')),
    );
    // Pinned first even though it is by far the older note.
    expect(pinned.dy, lessThan(recent.dy));
  });

  testWidgets('marking someone seen clears them from the overdue list', (
    tester,
  ) async {
    await pumpLuqa(tester);
    await openPeople(tester);
    expect(find.byKey(const ValueKey('overdue-tessa')), findsOneWidget);

    await openPerson(tester, 'tessa');
    await tester.tap(find.byKey(const ValueKey('person-mark-seen')));
    await tester.pumpAndSettle();

    expect(find.text('Seen today'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('overdue-tessa')), findsNothing);
  });

  testWidgets('a gift idea marked given stays on the list', (tester) async {
    await pumpLuqa(tester);
    await openPeople(tester);
    await openPerson(tester, 'mira');

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('gift-mira-gift-1')),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pumpAndSettle();

    // Still there — the list's second job is not giving the same thing twice.
    expect(find.text('Kiln time at the studio'), findsOneWidget);
  });

  testWidgets('groups people by city, biggest first', (tester) async {
    await pumpLuqa(tester);
    await openPeople(tester);
    await tester.tap(find.byKey(const ValueKey('people-places')));
    await tester.pumpAndSettle();

    expect(find.text('Hamburg, DE'), findsOneWidget);
    expect(find.text('Munich, DE'), findsOneWidget);
    // Jonas's parents put him in Hamburg as well as Berlin: being findable in
    // a city you sometimes are in is the whole point of the screen.
    expect(
      find.byKey(const ValueKey('city-name:hamburg-jonas')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('city-name:berlin-jonas')),
      findsOneWidget,
    );
  });

  testWidgets('the birthday list shows a contact with no birth year', (
    tester,
  ) async {
    await pumpLuqa(tester);
    await openPeople(tester);
    await tester.tap(find.textContaining('All birthdays'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('birthday-tessa')), findsOneWidget);
    // No year on file, so no age is claimed for her.
    final row = find.descendant(
      of: find.byKey(const ValueKey('birthday-tessa')),
      matching: find.textContaining('turns'),
    );
    expect(row, findsNothing);
    // Somebody with no birthday at all is listed rather than dropped.
    expect(find.byKey(const ValueKey('no-birthday-alina')), findsOneWidget);
  });

  testWidgets('adding a person puts them straight in the roster', (
    tester,
  ) async {
    await pumpLuqa(tester);
    await openPeople(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('people-add')),
      200,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('people-add')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('person-name')),
      'Ida Weber',
    );
    await tester.pumpAndSettle();
    await scrollSheetTo(tester, find.byKey(const ValueKey('person-save')));
    await tester.tap(find.byKey(const ValueKey('person-save')));
    await tester.pumpAndSettle();

    expect(find.text('Ida Weber'), findsWidgets);
  });

  testWidgets('the map pins cities, not people', (tester) async {
    await pumpLuqa(tester);
    await openPeople(tester);
    await tester.tap(find.byKey(const ValueKey('people-places')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('places-view-toggle')));
    await tester.pumpAndSettle();

    // Two friends in Hamburg are one pin carrying a count, not two pins on top
    // of each other — which is also why the map needs no clustering.
    expect(find.byType(PeopleMap), findsOneWidget);
    expect(find.text('Hamburg'), findsOneWidget);
    expect(find.text('Munich'), findsOneWidget);
  });

  testWidgets('a city pin opens the people in it', (tester) async {
    await pumpLuqa(tester);
    await openPeople(tester);
    await tester.tap(find.byKey(const ValueKey('people-places')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('places-view-toggle')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hamburg'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('map-name:hamburg-tessa')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('map-name:hamburg-piet')), findsOneWidget);
  });

  testWidgets('a city with no point is counted rather than silently dropped', (
    tester,
  ) async {
    // A geocoder resolves a few cities per call, so a roster spends its early
    // runs part-pinned. A short map has to say why it is short.
    await pumpLuqa(tester, peopleRepository: partlyPinnedPeopleRepository());
    await openPeople(tester);
    await tester.tap(find.byKey(const ValueKey('people-places')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('places-view-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('1 more city not placed yet.'), findsOneWidget);
    // And it is still on the list, where it is just as useful.
    await tester.tap(find.byKey(const ValueKey('places-view-toggle')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('city-name:berlin-jonas')),
      findsOneWidget,
    );
  });

  testWidgets('a fully pinned map invites the tap instead', (tester) async {
    await pumpLuqa(tester);
    await openPeople(tester);
    await tester.tap(find.byKey(const ValueKey('people-places')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('places-view-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('Tap a city to see who is there.'), findsOneWidget);
  });

  testWidgets('the list still works when nothing has been geocoded', (
    tester,
  ) async {
    // The state that matters: tiles need a connection and points need a
    // geocoder, and neither is required to answer "who is in Hamburg".
    await pumpLuqa(tester, peopleRepository: unpinnedPeopleRepository());
    await openPeople(tester);
    await tester.tap(find.byKey(const ValueKey('people-places')));
    await tester.pumpAndSettle();

    expect(find.text('Hamburg, DE'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('city-name:hamburg-tessa')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('places-view-toggle')));
    await tester.pumpAndSettle();

    // The map says why it is empty instead of showing a blank rectangle.
    expect(find.text('Nothing to pin yet'), findsOneWidget);
    expect(find.byType(PeopleMap), findsNothing);
  });
}
