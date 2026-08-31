import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/people/application/people_controller.dart';
import 'package:luqa/features/people/domain/people_math.dart';
import 'package:luqa/features/people/presentation/widgets/person_row.dart';

/// The birthday year, from here forward.
///
/// Ordered by how soon rather than by calendar month, because the question is
/// always "what is next", never "who was born in March". The month headings
/// are there to break the list up, not to sort it.
class BirthdaysScreen extends ConsumerWidget {
  const BirthdaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(peopleNowProvider);
    final people = ref.watch(peopleControllerProvider).listed;
    // A full year ahead: every birthday there is, each one exactly once.
    final birthdays = upcomingBirthdays(people, now, within: 366);
    final withoutBirthday = [
      for (final person in people)
        if (person.birthday == null) person,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Birthdays')),
      body: birthdays.isEmpty && withoutBirthday.isEmpty
          ? const _Empty()
          : ListView(
              padding: EdgeInsets.fromLTRB(
                LuqaSpacing.lg,
                LuqaSpacing.sm,
                LuqaSpacing.lg,
                LuqaSpacing.section + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                if (birthdays.isEmpty)
                  Text(
                    'No birthdays recorded yet.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                for (var index = 0; index < birthdays.length; index += 1) ...[
                  if (index == 0 ||
                      birthdays[index].date.month !=
                          birthdays[index - 1].date.month)
                    _MonthHeading(month: birthdays[index].date.month),
                  PersonRow(
                    key: ValueKey('birthday-${birthdays[index].person.id}'),
                    person: birthdays[index].person,
                    detail: _detail(birthdays[index]),
                    trailing: _DayMark(date: birthdays[index].date),
                    onTap: () =>
                        context.push('/people/${birthdays[index].person.id}'),
                  ),
                ],
                if (withoutBirthday.isNotEmpty) ...[
                  const SizedBox(height: LuqaSpacing.section),
                  Text(
                    'No birthday on file',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: LuqaSpacing.sm),
                  for (final person in withoutBirthday)
                    PersonRow(
                      key: ValueKey('no-birthday-${person.id}'),
                      person: person,
                      onTap: () => context.push('/people/${person.id}'),
                    ),
                ],
              ],
            ),
    );
  }

  String _detail(UpcomingBirthday birthday) {
    final age = birthday.turningAge;
    return [
      describeCountdown(birthday.daysAway),
      if (age != null) 'turns $age',
    ].join(' · ');
  }
}

class _MonthHeading extends StatelessWidget {
  const _MonthHeading({required this.month});

  final int month;

  static const _names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: LuqaSpacing.xl,
        bottom: LuqaSpacing.xs,
      ),
      child: Text(
        _names[month - 1],
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// The day of the month, in tabular figures so a column of them lines up.
class _DayMark extends StatelessWidget {
  const _DayMark({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      date.day.toString().padLeft(2, '0'),
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LuqaSpacing.xl),
        child: Text(
          'Nobody on your list yet.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
