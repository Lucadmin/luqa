import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/money/application/money_controller.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/presentation/widgets/identity_picker.dart';
import 'package:luqa/features/money/presentation/widgets/person_avatar.dart';

/// Naming a set of people: the flat, the friend group, a trip.
///
/// A group only ever pre-selects people on a bill — balances stay strictly per
/// person, so nothing here can change what anybody owes. That is why removing
/// somebody from a group is not a destructive action and is not confirmed.
Future<void> showGroupEditorSheet(
  BuildContext context,
  WidgetRef ref, {
  required MoneyOverview overview,
  PersonGroup? group,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _GroupEditorSheet(overview: overview, group: group),
    ),
  );
}

class _GroupEditorSheet extends ConsumerStatefulWidget {
  const _GroupEditorSheet({required this.overview, required this.group});

  final MoneyOverview overview;
  final PersonGroup? group;

  @override
  ConsumerState<_GroupEditorSheet> createState() => _GroupEditorSheetState();
}

class _GroupEditorSheetState extends ConsumerState<_GroupEditorSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.group?.name ?? '',
  );
  late int _colorValue = widget.group?.colorValue ?? identitySpectrum.first;
  late String? _emoji = widget.group?.emoji ?? '👥';
  late Set<String> _memberIds = {...?widget.group?.memberIds};
  bool _saving = false;

  bool get _isEdit => widget.group != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);

    final controller = ref.read(moneyControllerProvider.notifier);
    final existing = widget.group;
    final ok = existing == null
        ? await controller.addGroup(
                GroupWrite(
                  name: name,
                  colorValue: _colorValue,
                  emoji: _emoji,
                  memberIds: _memberIds.toList(),
                ),
              ) !=
              null
        : await controller.updateGroup(
            id: existing.id,
            name: name,
            colorValue: _colorValue,
            emoji: _emoji,
            clearEmoji: _emoji == null,
            memberIds: _memberIds.toList(),
          );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _name.text.trim();
    final people = [
      for (final balance in widget.overview.people)
        if (!balance.person.archived || _memberIds.contains(balance.id))
          balance.person,
    ];

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            LuqaSpacing.lg,
            0,
            LuqaSpacing.lg,
            LuqaSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PersonAvatar(
                    name: name.isEmpty ? '?' : name,
                    colorValue: _colorValue,
                    emoji: _emoji,
                    size: 44,
                  ),
                  const SizedBox(width: LuqaSpacing.md),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit group' : 'New group',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LuqaSpacing.lg),
              TextField(
                controller: _name,
                autofocus: !_isEdit,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'The flat, Lisbon trip…',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: LuqaSpacing.xl),
              Text(
                'Colour',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: LuqaSpacing.sm),
              IdentityColorPicker(
                selected: _colorValue,
                onChanged: (value) => setState(() => _colorValue = value),
              ),
              const SizedBox(height: LuqaSpacing.lg),
              Text(
                'Glyph',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: LuqaSpacing.sm),
              IdentityEmojiPicker(
                selected: _emoji,
                onChanged: (value) => setState(() => _emoji = value),
              ),
              const SizedBox(height: LuqaSpacing.xl),
              Text(
                'Members',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: LuqaSpacing.sm),
              if (people.isEmpty)
                Text(
                  'Add people first, then group them.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                for (final person in people)
                  CheckboxListTile(
                    value: _memberIds.contains(person.id),
                    onChanged: (checked) => setState(() {
                      if (checked ?? false) {
                        _memberIds = {..._memberIds, person.id};
                      } else {
                        _memberIds = {..._memberIds}..remove(person.id);
                      }
                    }),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(person.name),
                    secondary: PersonAvatar(
                      name: person.name,
                      colorValue: person.colorValue,
                      emoji: person.emoji,
                      size: 32,
                    ),
                  ),
              const SizedBox(height: LuqaSpacing.xl),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: name.isEmpty || _saving ? null : _save,
                  child: Text(_isEdit ? 'Save changes' : 'Create group'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
