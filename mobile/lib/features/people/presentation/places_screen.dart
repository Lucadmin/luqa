import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/people/application/people_controller.dart';
import 'package:luqa/features/people/domain/people_math.dart';
import 'package:luqa/features/people/domain/person.dart';
import 'package:luqa/features/people/presentation/widgets/people_map.dart';
import 'package:luqa/features/people/presentation/widgets/person_row.dart';

/// Who is where.
///
/// Two views of one answer. The list works in a basement and is the better
/// surface for "who is in Hamburg on Thursday"; the map is the better one for
/// "I have never been to Porto, does anyone live near it". The list is the
/// default because it is the one that always works.
class PlacesScreen extends ConsumerStatefulWidget {
  const PlacesScreen({super.key});

  @override
  ConsumerState<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends ConsumerState<PlacesScreen> {
  bool _mapView = false;

  @override
  void initState() {
    super.initState();
    // Cities are geocoded lazily and this is the screen that needs the points,
    // so it is the screen that asks for them. Failure is silent: an unresolved
    // city still lists, which is most of the value.
    Future.microtask(() async {
      try {
        await ref.read(peopleControllerProvider.notifier).geocodePlaces();
      } on Object {
        // Nothing to tell the user: the list is unaffected.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = ref.watch(peopleNowProvider);
    final cities = ref.watch(peopleByCityProvider);
    final withoutPlace = [
      for (final person in ref.watch(peopleControllerProvider).listed)
        if (person.places.isEmpty) person,
    ];
    final mappable = [
      for (final city in cities)
        if (city.isMappable) city,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Where everyone is'),
        actions: [
          IconButton(
            key: const ValueKey('places-view-toggle'),
            tooltip: _mapView ? 'Show the list' : 'Show the map',
            onPressed: () => setState(() => _mapView = !_mapView),
            icon: Icon(
              _mapView ? Icons.format_list_bulleted_rounded : Icons.map_outlined,
            ),
          ),
        ],
      ),
      body: _mapView
          ? _MapView(cities: mappable, unpinned: cities.length - mappable.length)
          : _CityList(
              cities: cities,
              withoutPlace: withoutPlace,
              now: now,
              theme: theme,
            ),
    );
  }
}

class _MapView extends StatelessWidget {
  const _MapView({required this.cities, required this.unpinned});

  final List<PeopleInCity> cities;

  /// Cities on file that have no point yet. Said out loud rather than left as
  /// a silently short map.
  final int unpinned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (cities.isEmpty) {
      return _Message(
        // Distinguishes "nothing to draw" from "the map is broken". Tiles need
        // a connection and points need a geocoder; neither is the user's
        // fault, and the list beside this works regardless.
        title: 'Nothing to pin yet',
        body: unpinned > 0
            ? 'The cities on file have not been placed on the map yet. This '
                  'needs a connection, and the list works without one.'
            : 'Add a city to somebody and they will show up here.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              LuqaSpacing.lg,
              LuqaSpacing.sm,
              LuqaSpacing.lg,
              LuqaSpacing.sm,
            ),
            child: PeopleMap(
              cities: cities,
              onSelect: (city) => _showCity(context, city),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            LuqaSpacing.lg,
            0,
            LuqaSpacing.lg,
            LuqaSpacing.lg + MediaQuery.paddingOf(context).bottom,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  unpinned == 0
                      ? 'Tap a city to see who is there.'
                      : '$unpinned more ${unpinned == 1 ? 'city' : 'cities'} '
                            'not placed yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCity(BuildContext context, PeopleInCity city) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            LuqaSpacing.lg,
            LuqaSpacing.lg,
            LuqaSpacing.lg,
            LuqaSpacing.lg,
          ),
          children: [
            Text(city.label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: LuqaSpacing.sm),
            for (final person in city.people)
              PersonRow(
                key: ValueKey('map-${city.key}-${person.id}'),
                person: person,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/people/${person.id}');
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CityList extends StatelessWidget {
  const _CityList({
    required this.cities,
    required this.withoutPlace,
    required this.now,
    required this.theme,
  });

  final List<PeopleInCity> cities;
  final List<Person> withoutPlace;
  final DateTime now;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        LuqaSpacing.lg,
        LuqaSpacing.sm,
        LuqaSpacing.lg,
        LuqaSpacing.section + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (cities.isEmpty)
          Text(
            'No cities on file yet. Add one to a person and they will turn '
            'up here when you are in town.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        for (final city in cities) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: LuqaSpacing.lg,
              bottom: LuqaSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(city.label, style: theme.textTheme.titleMedium),
                ),
                Text(
                  '${city.people.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (final person in city.people)
            PersonRow(
              key: ValueKey('city-${city.key}-${person.id}'),
              person: person,
              detail: _reasonToVisit(person, now),
              onTap: () => context.push('/people/${person.id}'),
            ),
        ],
        if (withoutPlace.isNotEmpty) ...[
          const SizedBox(height: LuqaSpacing.section),
          Text('No city yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: LuqaSpacing.sm),
          for (final person in withoutPlace)
            PersonRow(
              key: ValueKey('placeless-${person.id}'),
              person: person,
              onTap: () => context.push('/people/${person.id}'),
            ),
        ],
      ],
    );
  }

  /// What makes them worth calling while you are in town: how long it has
  /// been. Somebody you saw last week is not who this screen is for.
  String? _reasonToVisit(Person person, DateTime now) {
    final seen = person.lastSeenAt;
    if (seen == null) return null;
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(seen.year, seen.month, seen.day))
        .inDays;
    return '${describeElapsed(days)} since you saw them';
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LuqaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: LuqaSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
