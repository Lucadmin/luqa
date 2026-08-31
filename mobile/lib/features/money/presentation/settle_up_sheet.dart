import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/money/application/money_controller.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/presentation/money_formatters.dart';
import 'package:luqa/features/money/presentation/widgets/person_avatar.dart';

/// Clearing a debt.
///
/// Opens with the whole balance filled in and the direction already decided,
/// because settling up in full is what almost every payback is. Typing a
/// smaller number is the exception, and it is one keystroke away.
Future<void> showSettleUpSheet(
  BuildContext context,
  WidgetRef ref, {
  required Person person,
  required int balanceCents,
  required String currency,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _SettleUpSheet(
        person: person,
        balanceCents: balanceCents,
        currency: currency,
      ),
    ),
  );
}

class _SettleUpSheet extends ConsumerStatefulWidget {
  const _SettleUpSheet({
    required this.person,
    required this.balanceCents,
    required this.currency,
  });

  final Person person;
  final int balanceCents;
  final String currency;

  @override
  ConsumerState<_SettleUpSheet> createState() => _SettleUpSheetState();
}

class _SettleUpSheetState extends ConsumerState<_SettleUpSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: (widget.balanceCents.abs() / 100).toStringAsFixed(2),
  );
  late final TextEditingController _notes = TextEditingController();

  /// Positive balance means they owe the user, so the money comes to them.
  late SettlementDirection _direction = widget.balanceCents > 0
      ? SettlementDirection.toMe
      : SettlementDirection.fromMe;

  late String _dateKey = moneyDateKey(ref.read(moneyNowProvider));
  bool _saving = false;

  int get _amountCents => parseAmountToCents(_amount.text) ?? 0;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_amountCents <= 0 || _saving) return;
    setState(() => _saving = true);
    final ok = await ref
        .read(moneyControllerProvider.notifier)
        .settleUp(
          SettlementWrite(
            personId: widget.person.id,
            amountCents: _amountCents,
            direction: _direction,
            dateKey: _dateKey,
            notes: _notes.text.trim(),
          ),
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.person.name;
    final outstanding = widget.balanceCents.abs();
    final now = ref.watch(moneyNowProvider);
    final remaining = outstanding - _amountCents;

    return SafeArea(
      top: false,
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
                  name: name,
                  colorValue: widget.person.colorValue,
                  emoji: widget.person.emoji,
                ),
                const SizedBox(width: LuqaSpacing.md),
                Expanded(
                  child: Text(
                    'Settle up with $name',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LuqaSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  currencySymbol(widget.currency).trim(),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: LuqaSpacing.sm),
                Expanded(
                  child: TextField(
                    key: const ValueKey('settle-amount'),
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                    ],
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    decoration: const InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      hintText: '0',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: LuqaSpacing.sm),
            Text(
              _amountCents <= 0
                  ? '${formatMoney(outstanding, widget.currency)} outstanding'
                  : remaining > 0
                  ? 'Leaves ${formatMoney(remaining, widget.currency)} outstanding'
                  : remaining == 0
                  ? 'Clears the balance'
                  : 'Overshoots by ${formatMoney(-remaining, widget.currency)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: LuqaSpacing.xl),
            SegmentedButton<SettlementDirection>(
              segments: [
                ButtonSegment(
                  value: SettlementDirection.toMe,
                  label: Text('$name paid me'),
                ),
                const ButtonSegment(
                  value: SettlementDirection.fromMe,
                  label: Text('I paid them'),
                ),
              ],
              selected: {_direction},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _direction = selection.first),
            ),
            const SizedBox(height: LuqaSpacing.lg),
            TextField(
              controller: _notes,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Cash, bank transfer…',
              ),
            ),
            const SizedBox(height: LuqaSpacing.md),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(moneyDayLabel(context, _dateKey, now)),
            ),
            const SizedBox(height: LuqaSpacing.xl),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _amountCents > 0 && !_saving ? _save : null,
                child: const Text('Record payback'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
