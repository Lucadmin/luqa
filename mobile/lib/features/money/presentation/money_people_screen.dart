import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/money/application/money_controller.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/presentation/money_formatters.dart';
import 'package:luqa/features/money/presentation/person_editor_sheet.dart';
import 'package:luqa/features/money/presentation/widgets/person_avatar.dart';

/// Everyone the user splits with, as money sees them.
///
/// Narrower than the People tab on purpose: this is the split-defaults view,
/// so it shows the usual cut and the balance and nothing about the person.
/// Archived people keep a section of their own rather than disappearing,
/// because the reason to come here is usually to bring one of them back.
class MoneyPeopleScreen extends ConsumerWidget {
  const MoneyPeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moneyControllerProvider);
    final overview = state.overview;

    final active = <PersonBalance>[];
    final archived = <PersonBalance>[];
    for (final balance in overview?.people ?? const <PersonBalance>[]) {
      (balance.person.archived ? archived : active).add(balance);
    }
    // The management view is ordered the way the user arranged it, not by who
    // happens to owe the most today.
    int byOrder(PersonBalance a, PersonBalance b) =>
        a.person.order.compareTo(b.person.order);
    active.sort(byOrder);
    archived.sort(byOrder);

    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        actions: [
          IconButton(
            tooltip: 'Groups',
            onPressed: () => context.push('/money/groups'),
            icon: const Icon(Icons.group_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showPersonEditorSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add person'),
      ),
      body: overview == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(
                LuqaSpacing.lg,
                LuqaSpacing.sm,
                LuqaSpacing.lg,
                LuqaSpacing.section * 2,
              ),
              children: [
                if (active.isEmpty && archived.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: LuqaSpacing.xl),
                    child: Text(
                      'Nobody yet. People get added as you split bills with '
                      'them, or you can add one here.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                for (var index = 0; index < active.length; index += 1) ...[
                  if (index > 0) const Divider(),
                  _PersonRow(
                    balance: active[index],
                    currency: overview.currency,
                  ),
                ],
                if (archived.isNotEmpty) ...[
                  const SizedBox(height: LuqaSpacing.section),
                  Text(
                    'Archived',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: LuqaSpacing.sm),
                  for (var index = 0; index < archived.length; index += 1) ...[
                    if (index > 0) const Divider(),
                    _PersonRow(
                      balance: archived[index],
                      currency: overview.currency,
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}

class _PersonRow extends ConsumerWidget {
  const _PersonRow({required this.balance, required this.currency});

  final PersonBalance balance;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final person = balance.person;
    final controller = ref.read(moneyControllerProvider.notifier);

    final detail = <String>[
      if (person.defaultPercent != null)
        'Usually ${person.defaultPercent}%'
      else
        'Shares equally',
      if (balance.balanceCents != 0)
        formatMoney(balance.balanceCents, currency, signed: true, compact: true),
    ];

    return InkWell(
      onTap: () => context.push('/money/people/${person.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.sm),
        child: Row(
          children: [
            PersonAvatar(
              name: person.name,
              colorValue: person.colorValue,
              emoji: person.emoji,
              dimmed: person.archived,
            ),
            const SizedBox(width: LuqaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    detail.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<_PersonAction>(
              tooltip: 'Manage ${person.name}',
              onSelected: (action) async {
                switch (action) {
                  case _PersonAction.edit:
                    await showPersonEditorSheet(context, ref, person: person);
                  case _PersonAction.archive:
                    await controller.updatePerson(
                      id: person.id,
                      archived: !person.archived,
                    );
                  case _PersonAction.remove:
                    await _confirmRemove(context, ref, person);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _PersonAction.edit,
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: _PersonAction.archive,
                  child: Text(person.archived ? 'Restore' : 'Archive'),
                ),
                PopupMenuItem(
                  value: _PersonAction.remove,
                  child: Text(
                    'Remove',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    Person person,
  ) async {
    final hasHistory = balance.balanceCents != 0 || balance.coveredCents != 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${person.name}?'),
        // Honest about what will actually happen: somebody who has been on a
        // bill is archived, because deleting them would delete the history
        // that produced everyone else's numbers.
        content: Text(
          hasHistory
              ? 'They have history with you, so they will be archived instead. '
                    'Their bills and balance stay.'
              : 'They are not on any bill, so they will be removed outright.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(moneyControllerProvider.notifier).deletePerson(person.id);
  }
}

enum _PersonAction { edit, archive, remove }
