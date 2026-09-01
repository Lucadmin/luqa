import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/money/presentation/widgets/person_avatar.dart';
import 'package:luqa/features/people/application/people_controller.dart';
import 'package:luqa/features/people/domain/person.dart';

/// Who was there.
///
/// Multi-select, and it hands back the complete set rather than a diff — the
/// write replaces the tags wholesale, so there is nothing to merge and no
/// separate "remove" to get wrong.
///
/// Returns null when dismissed, which leaves the entry's tags alone.
Future<List<String>?> showPersonPickerSheet(
  BuildContext context, {
  required List<String> selectedIds,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.76,
      child: _PersonPickerSheet(selectedIds: selectedIds),
    ),
  );
}

class _PersonPickerSheet extends ConsumerStatefulWidget {
  const _PersonPickerSheet({required this.selectedIds});

  final List<String> selectedIds;

  @override
  ConsumerState<_PersonPickerSheet> createState() => _PersonPickerSheetState();
}

class _PersonPickerSheetState extends ConsumerState<_PersonPickerSheet> {
  final _searchController = TextEditingController();
  late final Set<String> _selected = {...widget.selectedIds};
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final needle = _query.trim().toLowerCase();
    final people = [
      for (final person in ref.watch(peopleControllerProvider).listed)
        if (needle.isEmpty ||
            person.displayName.toLowerCase().contains(needle) ||
            person.name.toLowerCase().contains(needle))
          person,
    ];

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              LuqaSpacing.lg,
              LuqaSpacing.lg,
              LuqaSpacing.lg,
              LuqaSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('Who was there', style: theme.textTheme.titleLarge),
                ),
                TextButton(
                  key: const ValueKey('person-picker-done'),
                  onPressed: () =>
                      Navigator.of(context).pop(_selected.toList(growable: false)),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: LuqaSpacing.lg),
            child: TextField(
              key: const ValueKey('person-picker-search'),
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search people',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: LuqaSpacing.sm),
          Expanded(
            child: people.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(LuqaSpacing.lg),
                    child: Text(
                      needle.isEmpty
                          ? 'Nobody on your list yet. People get added in the '
                                'People tab, or as you split bills with them.'
                          : 'Nobody by that name.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: LuqaSpacing.lg),
                    itemCount: people.length,
                    itemBuilder: (context, index) => _PersonOption(
                      person: people[index],
                      selected: _selected.contains(people[index].id),
                      onToggle: () => setState(() {
                        final id = people[index].id;
                        if (!_selected.remove(id)) _selected.add(id);
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PersonOption extends StatelessWidget {
  const _PersonOption({
    required this.person,
    required this.selected,
    required this.onToggle,
  });

  final Person person;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      key: ValueKey('person-option-${person.id}'),
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LuqaSpacing.lg,
          vertical: LuqaSpacing.sm,
        ),
        child: Row(
          children: [
            PersonAvatar(
              name: person.name,
              colorValue: person.colorValue,
              emoji: person.emoji,
              size: 36,
            ),
            const SizedBox(width: LuqaSpacing.md),
            Expanded(
              child: Text(
                person.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            // A checkbox rather than a tint: selection has to be readable to
            // somebody who cannot tell the identity colours apart.
            Checkbox(value: selected, onChanged: (_) => onToggle()),
          ],
        ),
      ),
    );
  }
}
