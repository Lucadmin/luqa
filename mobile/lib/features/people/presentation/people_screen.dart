import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/app/top_level_header.dart';
import 'package:luqa/design_system/luqa_sync_status.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/people/application/people_controller.dart';
import 'package:luqa/features/people/domain/people_math.dart';
import 'package:luqa/features/people/domain/person.dart';
import 'package:luqa/features/people/presentation/person_editor_sheet.dart';
import 'package:luqa/features/people/presentation/widgets/person_row.dart';

/// The People tab.
///
/// The reason to open this tab is almost always a name, so the roster is the
/// working surface and search is the real verb. There is deliberately no
/// filled primary action: once contacts are connected, adding a person by hand
/// is rare, and promoting it to a button would make the tab look like a CRM.
///
/// The focal object is one line — the next birthday, or the person gone
/// longest without being seen. One of them, never both.
class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(peopleControllerProvider);
    final controller = ref.read(peopleControllerProvider.notifier);
    final now = ref.watch(peopleNowProvider);

    if (state.isLoading && !state.loaded) {
      return const SafeArea(child: _PeopleSkeleton());
    }

    final listed = state.listed;
    final matches = _matching(listed, _query);
    final overdue = ref.watch(overdueContactsProvider);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: LuqaTopLevelHeader(
                primary: Text(
                  'People',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                contextualActions: [
                  IconButton(
                    key: const ValueKey('people-places'),
                    tooltip: 'Where everyone is',
                    onPressed: () => context.push('/people/places'),
                    icon: const Icon(Icons.map_outlined),
                  ),
                  IconButton(
                    key: const ValueKey('people-search'),
                    tooltip: _searching ? 'Close search' : 'Search people',
                    onPressed: _toggleSearch,
                    icon: Icon(
                      _searching ? Icons.close_rounded : Icons.search_rounded,
                    ),
                  ),
                ],
                status: state.isRefreshing
                    ? LuqaSyncStatus(
                        pendingWrites: 0,
                        isRefreshing: true,
                        onRetry: controller.refresh,
                        controlKey: const ValueKey('people-refreshing'),
                      )
                    : null,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: LuqaSpacing.lg),
              sliver: SliverList.list(
                children: [
                  if (_searching) ...[
                    const SizedBox(height: LuqaSpacing.lg),
                    _SearchField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ] else ...[
                    const SizedBox(height: LuqaSpacing.xl),
                    _Headline(
                      focus: ref.watch(peopleFocusProvider),
                      onOpen: (id) => context.push('/people/$id'),
                      onSeeBirthdays: () => context.push('/people/birthdays'),
                    ),
                  ],
                  if (state.error != null) ...[
                    const SizedBox(height: LuqaSpacing.md),
                    _InlineError(
                      message: state.error!,
                      onRetry: controller.refresh,
                    ),
                  ],
                  if (!_searching && overdue.isNotEmpty) ...[
                    const SizedBox(height: LuqaSpacing.section),
                    const _SectionHeading(title: 'Been a while'),
                    for (final contact in overdue.take(3))
                      PersonRow(
                        key: ValueKey('overdue-${contact.person.id}'),
                        person: contact.person,
                        detail:
                            '${describeElapsed(contact.daysSince)} · '
                            'aiming for every '
                            '${describeCadence(contact.cadenceDays)}',
                        onTap: () => context.push('/people/${contact.person.id}'),
                      ),
                  ],
                  const SizedBox(height: LuqaSpacing.section),
                  _SectionHeading(
                    title: _searching ? 'Matches' : 'Everyone',
                    trailing: '${matches.length}',
                  ),
                ],
              ),
            ),
            if (matches.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  LuqaSpacing.lg,
                  LuqaSpacing.lg,
                  LuqaSpacing.lg,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    _query.isNotEmpty
                        ? 'Nobody by that name.'
                        : 'Nobody yet. People arrive as you split bills with '
                              'them, and the rest of the record fills in when '
                              'it is worth writing down.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: LuqaSpacing.lg),
                sliver: SliverList.separated(
                  itemCount: matches.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) => PersonRow(
                    key: ValueKey('person-${matches[index].id}'),
                    person: matches[index],
                    detail: _supportingLine(matches[index], now),
                    onTap: () => context.push('/people/${matches[index].id}'),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LuqaSpacing.lg,
                LuqaSpacing.section,
                LuqaSpacing.lg,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: OutlinedButton.icon(
                  key: const ValueKey('people-add'),
                  onPressed: () => showPersonEditorSheet(context, ref),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add someone'),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.only(
                bottom:
                    LuqaSpacing.section + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
          ],
        ),
      ),
    );
  }
}

/// The one line under the title, and the only thing on the screen at display
/// size.
class _Headline extends StatelessWidget {
  const _Headline({
    required this.focus,
    required this.onOpen,
    required this.onSeeBirthdays,
  });

  final PeopleFocus focus;
  final void Function(String personId) onOpen;
  final VoidCallback onSeeBirthdays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return switch (focus) {
      BirthdayFocus(:final birthday) => _FocusBlock(
        label: birthday.isToday ? 'Birthday today' : 'Next birthday',
        title: birthday.person.displayName,
        // Colour never carries this on its own; the words say what it is.
        supporting: [
          describeCountdown(birthday.daysAway),
          if (birthday.turningAge != null) 'turns ${birthday.turningAge}',
        ].join(' · '),
        action: 'All birthdays',
        onAction: onSeeBirthdays,
        onTap: () => onOpen(birthday.person.id),
        valueKey: const ValueKey('people-focus-birthday'),
      ),
      ReconnectFocus(:final contact) => _FocusBlock(
        label: 'Been longest',
        title: contact.person.displayName,
        supporting:
            '${describeElapsed(contact.daysSince)} since you saw them',
        onTap: () => onOpen(contact.person.id),
        valueKey: const ValueKey('people-focus-reconnect'),
      ),
      // Nothing is due and nobody is overdue, which is a perfectly good state
      // for a contact book. It says so plainly rather than inventing a metric.
      QuietFocus(:final peopleCount) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        key: const ValueKey('people-focus-quiet'),
        children: [
          Text(
            peopleCount == 0
                ? 'Nobody yet'
                : 'Nothing coming up',
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: LuqaSpacing.sm),
          Text(
            peopleCount == 0
                ? 'Add the people you actually keep up with.'
                : 'No birthdays in the next month, nobody overdue.',
            style: theme.textTheme.bodyLarge?.copyWith(color: muted),
          ),
        ],
      ),
    };
  }
}

class _FocusBlock extends StatelessWidget {
  const _FocusBlock({
    required this.label,
    required this.title,
    required this.supporting,
    required this.onTap,
    required this.valueKey,
    this.action,
    this.onAction,
  });

  final String label;
  final String title;
  final String supporting;
  final VoidCallback onTap;
  final Key valueKey;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      key: valueKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: muted),
              ),
            ),
            if (action != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LuqaSpacing.sm,
                  ),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(action!),
              ),
          ],
        ),
        const SizedBox(height: LuqaSpacing.sm),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LuqaRadii.compact),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.displaySmall),
              const SizedBox(height: LuqaSpacing.sm),
              Text(
                supporting,
                style: theme.textTheme.bodyLarge?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('people-search-field'),
      controller: controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      decoration: const InputDecoration(
        hintText: 'Search people',
        prefixIcon: Icon(Icons.search_rounded),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: LuqaSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          if (trailing != null)
            Text(
              trailing!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _PeopleSkeleton extends StatelessWidget {
  const _PeopleSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Name, nickname, and city all match, because all three are things somebody
/// might type when they are looking for a person.
List<Person> _matching(List<Person> people, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return people;
  return [
    for (final person in people)
      if (person.name.toLowerCase().contains(needle) ||
          (person.nickname ?? '').toLowerCase().contains(needle) ||
          (person.primaryPlace?.city ?? '').toLowerCase().contains(needle))
        person,
  ];
}

/// The quiet line under a name in the roster: where they are, and a birthday
/// only when it is close enough to matter.
String? _supportingLine(Person person, DateTime now) {
  final parts = <String>[];
  final city = person.primaryPlace?.city;
  if (city != null && city.isNotEmpty) parts.add(city);

  final birthday = person.birthday;
  if (birthday != null) {
    final days = birthday.daysUntil(now);
    if (days <= 30) parts.add('birthday ${describeCountdown(days)}');
  }
  return parts.isEmpty ? null : parts.join(' · ');
}

/// A cadence in the words somebody would use for it.
String describeCadence(int days) {
  if (days <= 10) return '$days days';
  if (days <= 25) return '${(days / 7).round()} weeks';
  if (days < 330) {
    final months = (days / 30.44).round();
    return months <= 1 ? 'month' : '$months months';
  }
  final years = (days / 365.25).round();
  return years <= 1 ? 'year' : '$years years';
}
