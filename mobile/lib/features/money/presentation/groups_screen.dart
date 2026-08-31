import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/money/application/money_controller.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/presentation/expense_sheet.dart';
import 'package:luqa/features/money/presentation/group_editor_sheet.dart';
import 'package:luqa/features/money/presentation/widgets/person_avatar.dart';

/// Groups: named sets of people, and nothing more.
///
/// Tapping one starts a bill with its members already on it, which is the only
/// thing a group does. Editing it is behind the overflow, because "split with
/// the flat again" is the action, not "manage the flat".
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(moneyControllerProvider).overview;
    final groups = [
      for (final group in overview?.groups ?? const <PersonGroup>[])
        if (!group.archived) group,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      floatingActionButton: overview == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  showGroupEditorSheet(context, ref, overview: overview),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New group'),
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
                if (groups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: LuqaSpacing.xl),
                    child: Text(
                      'A group is a shortcut: name the people you keep '
                      'splitting with, and every bill with them starts one tap '
                      'away.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                for (var index = 0; index < groups.length; index += 1) ...[
                  if (index > 0) const Divider(),
                  _GroupRow(group: groups[index], overview: overview),
                ],
              ],
            ),
    );
  }
}

class _GroupRow extends ConsumerWidget {
  const _GroupRow({required this.group, required this.overview});

  final PersonGroup group;
  final MoneyOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final names = [
      for (final id in group.memberIds)
        if (overview.personById(id) case final person?) person.name,
    ];

    return InkWell(
      onTap: () => showExpenseSheet(
        context,
        ref,
        overview: overview,
        presetPersonIds: group.memberIds,
        presetGroupId: group.id,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.sm),
        child: Row(
          children: [
            PersonAvatar(
              name: group.name,
              colorValue: group.colorValue,
              emoji: group.emoji ?? '👥',
            ),
            const SizedBox(width: LuqaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    names.isEmpty ? 'No members yet' : names.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<_GroupAction>(
              tooltip: 'Manage ${group.name}',
              onSelected: (action) async {
                switch (action) {
                  case _GroupAction.edit:
                    await showGroupEditorSheet(
                      context,
                      ref,
                      overview: overview,
                      group: group,
                    );
                  case _GroupAction.delete:
                    await _confirmDelete(context, ref);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _GroupAction.edit,
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: _GroupAction.delete,
                  child: Text(
                    'Delete',
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${group.name}?'),
        content: const Text(
          'Past bills keep their people and amounts — they just lose the label. '
          'No balance changes.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(moneyControllerProvider.notifier).deleteGroup(group.id);
  }
}

enum _GroupAction { edit, delete }
