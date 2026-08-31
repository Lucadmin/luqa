import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/people/application/people_controller.dart';
import 'package:luqa/features/people/domain/people_math.dart';
import 'package:luqa/features/people/domain/person.dart';
import 'package:luqa/features/people/presentation/widgets/person_row.dart';

/// Who is where.
///
/// This is the map's answer without the map, and it is the half that works in
/// a basement: the tiles need a network and this does not. When the map layer
/// lands it becomes the second view on this same route, not a replacement —
/// for "who is in Hamburg on Thursday" a list of names beats a pin.
class PlacesScreen extends ConsumerWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = ref.watch(peopleNowProvider);
    final cities = ref.watch(peopleByCityProvider);
    final withoutPlace = [
      for (final person in ref.watch(peopleControllerProvider).listed)
        if (person.places.isEmpty) person,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Where everyone is')),
      body: ListView(
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
                    child: Text(
                      city.label,
                      style: theme.textTheme.titleMedium,
                    ),
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
                key: ValueKey('city-${city.city}-${person.id}'),
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
      ),
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
