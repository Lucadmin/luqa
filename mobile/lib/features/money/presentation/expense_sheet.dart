import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/money/application/money_controller.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/domain/money_split.dart';
import 'package:luqa/features/money/presentation/money_formatters.dart';
import 'package:luqa/features/money/presentation/widgets/person_avatar.dart';
import 'package:luqa/features/money/presentation/widgets/split_editor.dart';

/// The bill composer.
///
/// Amount first, at display size, focused on open: every bill starts with a
/// number, and everything else on the sheet is a qualification of it. The
/// split is previewed live in exact cents, because the question people
/// actually have at the table is "so what do I owe" — and the preview runs the
/// same rules the server will re-run on save, so the answer cannot change
/// between showing it and storing it.
Future<void> showExpenseSheet(
  BuildContext context,
  WidgetRef ref, {
  required MoneyOverview overview,
  Expense? expense,
  List<String> presetPersonIds = const [],
  String? presetGroupId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _ExpenseSheet(
        overview: overview,
        expense: expense,
        presetPersonIds: presetPersonIds,
        presetGroupId: presetGroupId,
      ),
    ),
  );
}

class _ExpenseSheet extends ConsumerStatefulWidget {
  const _ExpenseSheet({
    required this.overview,
    required this.expense,
    required this.presetPersonIds,
    required this.presetGroupId,
  });

  final MoneyOverview overview;
  final Expense? expense;
  final List<String> presetPersonIds;
  final String? presetGroupId;

  @override
  ConsumerState<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends ConsumerState<_ExpenseSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _description;
  final FocusNode _amountFocus = FocusNode();

  late String _dateKey;
  late String? _paidByPersonId;
  late String? _groupId;
  late SplitMode _mode;
  late bool _includeMe;
  late List<SplitParticipant> _participants;

  bool _saving = false;

  bool get _isEdit => widget.expense != null;

  int get _amountCents => parseAmountToCents(_amount.text) ?? 0;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _amount = TextEditingController(
      text: expense == null
          ? ''
          : formatMoney(
              expense.amountCents,
              widget.overview.currency,
            ).replaceAll(RegExp(r'[^\d.,]'), ''),
    );
    _description = TextEditingController(text: expense?.description ?? '');

    if (expense != null) {
      _dateKey = expense.dateKey;
      _paidByPersonId = expense.paidByPersonId;
      _groupId = expense.groupId;
      _mode = expense.splitMode;
      // Reopening a bill has to show the editor state it was saved with, and
      // "was I one of the equal parts" is only recorded as whether a slice was
      // kept for the user.
      _includeMe = expense.myShareCents > 0 || expense.shares.isEmpty;
      _participants = [
        for (final share in expense.shares)
          SplitParticipant(
            personId: share.personId,
            percentBp: share.percentBp,
            amountCents: share.amountCents,
            gifted: share.gifted,
          ),
      ];
    } else {
      _dateKey = moneyDateKey(ref.read(moneyNowProvider));
      _paidByPersonId = null;
      _groupId = widget.presetGroupId;
      final preset = [
        for (final id in widget.presetPersonIds)
          ?widget.overview.personById(id),
      ];
      final defaults = defaultSplitFor(preset);
      _mode = defaults.mode;
      _includeMe = defaults.includeMe;
      _participants = defaults.participants;
      // A bill always starts with a number, so the keyboard is already up and
      // pointed at the one field that must be filled.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _amountFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  SplitResult get _split => computeSplit(
    amountCents: _amountCents,
    mode: _mode,
    participants: _paidByPersonId == null
        ? _participants
        : [for (final p in _participants) p.copyWith(gifted: false)],
    includeMe: _includeMe,
  );

  void _togglePerson(Person person) {
    setState(() {
      final without = [
        for (final participant in _participants)
          if (participant.personId != person.id) participant,
      ];
      if (without.length != _participants.length) {
        _participants = without;
        // The last person leaving takes the bill back to "all mine", which is
        // an equal split of one.
        if (_participants.isEmpty) {
          _mode = SplitMode.equal;
          _includeMe = true;
        }
        return;
      }
      _participants = [
        ..._participants,
        SplitParticipant(
          personId: person.id,
          // Their usual cut, if they have one, carries into a percent split.
          percentBp: _mode == SplitMode.percent
              ? clampBp((person.defaultPercent ?? 0) * 100)
              : null,
        ),
      ];
    });
  }

  Future<void> _save() async {
    final amountCents = _amountCents;
    if (amountCents <= 0 || _saving) return;
    setState(() => _saving = true);

    final ok = await ref
        .read(moneyControllerProvider.notifier)
        .saveExpense(
          id: widget.expense?.id,
          write: ExpenseWrite(
            description: _description.text.trim(),
            amountCents: amountCents,
            dateKey: _dateKey,
            paidByPersonId: _paidByPersonId,
            groupId: _groupId,
            splitMode: _mode,
            includeMe: _includeMe,
            participants: _participants,
            notes: '',
          ),
        );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final expense = widget.expense;
    if (expense == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this expense?'),
        content: const Text(
          'The bill and every share on it go. Balances move back.',
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
    if (confirmed != true || !mounted) return;
    await ref.read(moneyControllerProvider.notifier).deleteExpense(expense.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final now = ref.read(moneyNowProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: moneyDateFromKey(_dateKey),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null && mounted) {
      setState(() => _dateKey = moneyDateKey(picked));
    }
  }

  Future<void> _pickPayer() async {
    final selected = await showModalBottomSheet<_PayerChoice>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _PayerPicker(
        overview: widget.overview,
        // Only people actually on the bill can have fronted it.
        candidates: [
          for (final participant in _participants)
            ?widget.overview.personById(participant.personId),
        ],
        selectedId: _paidByPersonId,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _paidByPersonId = selected.personId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overview = widget.overview;
    final split = _split;
    final now = ref.watch(moneyNowProvider);

    final selectable = [
      for (final balance in overview.people)
        if (!balance.person.archived ||
            _participants.any((p) => p.personId == balance.id))
          balance.person,
    ];

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
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
                  Expanded(
                    child: Text(
                      _isEdit ? 'Expense' : 'New expense',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (_isEdit)
                    IconButton(
                      tooltip: 'Delete expense',
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                ],
              ),
              const SizedBox(height: LuqaSpacing.lg),
              _AmountField(
                controller: _amount,
                focusNode: _amountFocus,
                currency: overview.currency,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: LuqaSpacing.lg),
              TextField(
                controller: _description,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'What was it?',
                  hintText: 'Dinner, taxi, groceries…',
                ),
              ),
              const SizedBox(height: LuqaSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MetaButton(
                      label: 'Date',
                      value: moneyDayLabel(context, _dateKey, now),
                      icon: Icons.calendar_today_rounded,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: LuqaSpacing.sm),
                  Expanded(
                    child: _MetaButton(
                      label: 'Paid by',
                      value: _paidByPersonId == null
                          ? 'You'
                          : overview.nameOf(_paidByPersonId),
                      icon: Icons.account_balance_wallet_outlined,
                      onTap: _participants.isEmpty ? null : _pickPayer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LuqaSpacing.xl),
              Text(
                'Split with',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: LuqaSpacing.sm),
              _PeoplePicker(
                people: selectable,
                selectedIds: {
                  for (final participant in _participants) participant.personId,
                },
                onToggle: _togglePerson,
                onAdd: _addPerson,
              ),
              if (_participants.isNotEmpty) ...[
                const SizedBox(height: LuqaSpacing.xl),
                SplitEditor(
                  overview: overview,
                  mode: _mode,
                  includeMe: _includeMe,
                  participants: _participants,
                  split: split,
                  amountCents: _amountCents,
                  // A treat is the user covering somebody's slice; when
                  // somebody else paid there is nothing of theirs to cover.
                  allowGifts: _paidByPersonId == null,
                  onModeChanged: (mode) => setState(() {
                    _mode = mode;
                    _participants = _seedFor(mode, split);
                  }),
                  onIncludeMeChanged: (value) =>
                      setState(() => _includeMe = value),
                  onParticipantChanged: (updated) => setState(() {
                    _participants = [
                      for (final participant in _participants)
                        participant.personId == updated.personId
                            ? updated
                            : participant,
                    ];
                  }),
                ),
              ],
              const SizedBox(height: LuqaSpacing.xl),
              SizedBox(
                height: 52,
                child: FilledButton(
                  key: const ValueKey('expense-save'),
                  onPressed: _amountCents > 0 && !split.overAssigned && !_saving
                      ? _save
                      : null,
                  child: Text(_isEdit ? 'Save changes' : 'Add expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Switching modes carries the numbers across rather than resetting them:
  /// an even split becomes the percentages or amounts it already was, so the
  /// user edits from where they are instead of starting again.
  List<SplitParticipant> _seedFor(SplitMode mode, SplitResult previous) {
    return [
      for (final participant in _participants)
        switch (mode) {
          SplitMode.percent => participant.copyWith(
            percentBp:
                previous.shares
                    .where((s) => s.personId == participant.personId)
                    .firstOrNull
                    ?.percentBp ??
                participant.percentBp ??
                0,
          ),
          SplitMode.amount => participant.copyWith(
            amountCents: previous.amountFor(participant.personId),
          ),
          SplitMode.equal => participant,
        },
    ];
  }

  Future<void> _addPerson() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _AddPersonDialog(),
    );
    if (name == null || !mounted) return;
    final person = await ref
        .read(moneyControllerProvider.notifier)
        .addPerson(
          PersonWrite(
            name: name,
            colorValue: _nextColorValue(),
            emoji: null,
            defaultPercent: null,
          ),
        );
    if (person == null || !mounted) return;
    // Someone added mid-bill is on that bill; that is why they were added.
    setState(() {
      if (!_participants.any((p) => p.personId == person.id)) {
        _participants = [
          ..._participants,
          SplitParticipant(personId: person.id),
        ];
      }
    });
  }

  /// Walks the identity spectrum so consecutive people are told apart at a
  /// glance rather than all arriving indigo.
  int _nextColorValue() {
    const spectrum = [
      0xFF2563EB,
      0xFF0F766E,
      0xFF15803D,
      0xFFB45309,
      0xFFC2410C,
      0xFFBE185D,
    ];
    return spectrum[widget.overview.people.length % spectrum.length];
  }
}

/// The focal control of the sheet: the number, big, with the currency symbol
/// deliberately quieter than the digits.
class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.focusNode,
    required this.currency,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String currency;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displaySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          currencySymbol(currency).trim(),
          style: theme.textTheme.headlineLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: LuqaSpacing.sm),
        Expanded(
          child: TextField(
            key: const ValueKey('expense-amount'),
            controller: controller,
            focusNode: focusNode,
            autofocus: false,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            style: style,
            decoration: InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              hintText: '0',
              hintStyle: style?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
              ),
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
      ],
    );
  }
}

/// A labelled value that opens a picker. Persistent label, because "Today"
/// alone does not say whether it is a date or a due date.
class _MetaButton extends StatelessWidget {
  const _MetaButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final enabled = onTap != null;
    return Material(
      color: palette.raised,
      borderRadius: BorderRadius.circular(LuqaRadii.compact),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LuqaRadii.compact),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(
            horizontal: LuqaSpacing.md,
            vertical: LuqaSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: LuqaSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        // Disabled state keeps readable text rather than
                        // fading the whole control out.
                        color: enabled
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeoplePicker extends StatelessWidget {
  const _PeoplePicker({
    required this.people,
    required this.selectedIds,
    required this.onToggle,
    required this.onAdd,
  });

  final List<Person> people;
  final Set<String> selectedIds;
  final void Function(Person person) onToggle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: LuqaSpacing.sm,
      runSpacing: LuqaSpacing.sm,
      children: [
        for (final person in people)
          _PersonToggle(
            key: ValueKey('split-person-${person.id}'),
            person: person,
            selected: selectedIds.contains(person.id),
            onTap: () => onToggle(person),
          ),
        _AddPersonChip(onTap: onAdd),
      ],
    );
  }
}

class _PersonToggle extends StatelessWidget {
  const _PersonToggle({
    required this.person,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Person person;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? palette.raised : Colors.transparent,
        borderRadius: BorderRadius.circular(LuqaRadii.compact),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LuqaRadii.compact),
          child: AnimatedContainer(
            duration: LuqaMotion.state,
            curve: LuqaMotion.curve,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: LuqaSpacing.md,
              vertical: LuqaSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LuqaRadii.compact),
              border: Border.all(
                // Selection is a tone change plus a check, never colour alone.
                color: selected ? theme.colorScheme.onSurface : palette.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PersonAvatar(
                  name: person.name,
                  colorValue: person.colorValue,
                  emoji: person.emoji,
                  size: 24,
                ),
                const SizedBox(width: LuqaSpacing.sm),
                Text(person.name, style: theme.textTheme.labelLarge),
                if (selected) ...[
                  const SizedBox(width: LuqaSpacing.sm),
                  Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPersonChip extends StatelessWidget {
  const _AddPersonChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(LuqaRadii.compact),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LuqaRadii.compact),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: LuqaSpacing.md,
            vertical: LuqaSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LuqaRadii.compact),
            border: Border.all(color: LuqaPalette.of(context).border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: LuqaSpacing.sm),
              Text(
                'Someone new',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPersonDialog extends StatefulWidget {
  const _AddPersonDialog();

  @override
  State<_AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends State<_AddPersonDialog> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Who are you splitting with?'),
      content: TextField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Name'),
        onSubmitted: (_) => _submit(),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _name.text.trim().isEmpty ? null : _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _PayerChoice {
  const _PayerChoice(this.personId);

  final String? personId;
}

class _PayerPicker extends StatelessWidget {
  const _PayerPicker({
    required this.overview,
    required this.candidates,
    required this.selectedId,
  });

  final MoneyOverview overview;
  final List<Person> candidates;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              LuqaSpacing.lg,
              0,
              LuqaSpacing.lg,
              LuqaSpacing.sm,
            ),
            child: Text(
              'Who paid?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('You'),
            trailing: selectedId == null
                ? const Icon(Icons.check_rounded)
                : null,
            onTap: () => Navigator.of(context).pop(const _PayerChoice(null)),
          ),
          for (final person in candidates)
            ListTile(
              leading: PersonAvatar(
                name: person.name,
                colorValue: person.colorValue,
                emoji: person.emoji,
                size: 32,
              ),
              title: Text(person.name),
              trailing: selectedId == person.id
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.of(context).pop(_PayerChoice(person.id)),
            ),
          const SizedBox(height: LuqaSpacing.sm),
        ],
      ),
    );
  }
}
