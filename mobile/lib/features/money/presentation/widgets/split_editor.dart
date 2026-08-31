import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/domain/money_split.dart';
import 'package:luqa/features/money/presentation/money_formatters.dart';
import 'package:luqa/features/money/presentation/widgets/person_avatar.dart';

/// Who carries what, previewed in exact cents while it is being decided.
///
/// The preview is not an estimate: it runs the same allocation the server will
/// re-run on save, down to which person absorbs the odd cent. That is the
/// whole point — the number somebody reads off the screen at the table is the
/// number that ends up owed.
class SplitEditor extends StatelessWidget {
  const SplitEditor({
    required this.overview,
    required this.mode,
    required this.includeMe,
    required this.participants,
    required this.split,
    required this.amountCents,
    required this.allowGifts,
    required this.onModeChanged,
    required this.onIncludeMeChanged,
    required this.onParticipantChanged,
    super.key,
  });

  final MoneyOverview overview;
  final SplitMode mode;
  final bool includeMe;
  final List<SplitParticipant> participants;
  final SplitResult split;
  final int amountCents;

  /// A treat only means something when the user is the one who paid.
  final bool allowGifts;

  final ValueChanged<SplitMode> onModeChanged;
  final ValueChanged<bool> onIncludeMeChanged;
  final ValueChanged<SplitParticipant> onParticipantChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModeSelector(mode: mode, onChanged: onModeChanged),
        if (mode == SplitMode.equal) ...[
          const SizedBox(height: LuqaSpacing.sm),
          _IncludeMeToggle(value: includeMe, onChanged: onIncludeMeChanged),
        ],
        const SizedBox(height: LuqaSpacing.md),
        const Divider(),
        _MyShareRow(
          amountCents: split.myShareCents,
          currency: overview.currency,
          totalCents: amountCents,
        ),
        for (final participant in participants) ...[
          const Divider(),
          _ParticipantRow(
            key: ValueKey('share-${participant.personId}'),
            person: overview.personById(participant.personId),
            participant: participant,
            amountCents: split.amountFor(participant.personId),
            currency: overview.currency,
            mode: mode,
            allowGifts: allowGifts,
            onChanged: onParticipantChanged,
          ),
        ],
        const Divider(),
        if (split.overAssigned) ...[
          const SizedBox(height: LuqaSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: LuqaSpacing.sm),
              Expanded(
                child: Text(
                  mode == SplitMode.percent
                      ? 'The shares add up to more than 100%.'
                      : 'The shares add up to more than the total.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final SplitMode mode;
  final ValueChanged<SplitMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SplitMode>(
      segments: const [
        ButtonSegment(value: SplitMode.equal, label: Text('Equal')),
        ButtonSegment(value: SplitMode.percent, label: Text('Percent')),
        ButtonSegment(value: SplitMode.amount, label: Text('Amounts')),
      ],
      selected: {mode},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _IncludeMeToggle extends StatelessWidget {
  const _IncludeMeToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(LuqaRadii.compact),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.xs),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (next) => onChanged(next ?? false),
            ),
            const SizedBox(width: LuqaSpacing.xs),
            Expanded(
              child: Text(
                'Count me in the split',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The user's own slice. Always shown, never editable: it is whatever the
/// bill has left after everyone else, which is what makes the total exact.
class _MyShareRow extends StatelessWidget {
  const _MyShareRow({
    required this.amountCents,
    required this.currency,
    required this.totalCents,
  });

  final int amountCents;
  final String currency;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = totalCents <= 0
        ? null
        : (amountCents * 100 / totalCents).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LuqaPalette.of(context).raised,
              borderRadius: BorderRadius.circular(LuqaRadii.compact),
              border: Border.all(color: LuqaPalette.of(context).border),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: LuqaSpacing.md),
          Expanded(
            child: Text(
              'You',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (percent != null)
            Padding(
              padding: const EdgeInsets.only(right: LuqaSpacing.md),
              child: Text(
                '$percent%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          Text(
            formatMoney(amountCents, currency),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatefulWidget {
  const _ParticipantRow({
    required this.person,
    required this.participant,
    required this.amountCents,
    required this.currency,
    required this.mode,
    required this.allowGifts,
    required this.onChanged,
    super.key,
  });

  final Person? person;
  final SplitParticipant participant;
  final int amountCents;
  final String currency;
  final SplitMode mode;
  final bool allowGifts;
  final ValueChanged<SplitParticipant> onChanged;

  @override
  State<_ParticipantRow> createState() => _ParticipantRowState();
}

class _ParticipantRowState extends State<_ParticipantRow> {
  late final TextEditingController _input = TextEditingController(
    text: _textFor(widget.mode),
  );
  final FocusNode _focus = FocusNode();

  @override
  void didUpdateWidget(_ParticipantRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The field is the user's to type in while they are in it; it only
    // re-syncs when the mode changed underneath them or somebody else's edit
    // moved this share.
    if (oldWidget.mode != widget.mode ||
        (!_focus.hasFocus && oldWidget.amountCents != widget.amountCents)) {
      _input.text = _textFor(widget.mode);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _textFor(SplitMode mode) => switch (mode) {
    SplitMode.percent => widget.participant.percentBp == null
        ? ''
        : (widget.participant.percentBp! / 100)
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'\.?0+$'), ''),
    SplitMode.amount => widget.amountCents == 0
        ? ''
        : (widget.amountCents / 100).toStringAsFixed(2),
    SplitMode.equal => '',
  };

  void _commit(String value) {
    switch (widget.mode) {
      case SplitMode.percent:
        final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
        widget.onChanged(
          widget.participant.copyWith(
            percentBp: parsed == null ? 0 : clampBp((parsed * 100).round()),
          ),
        );
      case SplitMode.amount:
        widget.onChanged(
          widget.participant.copyWith(
            amountCents: parseAmountToCents(value) ?? 0,
          ),
        );
      case SplitMode.equal:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final person = widget.person;
    final gifted = widget.participant.gifted;
    final name = person?.name ?? 'Someone';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.sm),
      child: Row(
        children: [
          PersonAvatar(
            name: name,
            colorValue: person?.colorValue ?? 0xFF6366F1,
            emoji: person?.emoji,
          ),
          const SizedBox(width: LuqaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (gifted)
                  Text(
                    'Covered as a treat',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.pink,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.allowGifts)
            IconButton(
              tooltip: gifted
                  ? 'Stop covering $name'
                  : 'Cover $name as a treat',
              visualDensity: VisualDensity.compact,
              onPressed: () => widget.onChanged(
                widget.participant.copyWith(gifted: !gifted),
              ),
              icon: Icon(
                gifted
                    ? Icons.card_giftcard_rounded
                    : Icons.card_giftcard_outlined,
                size: 20,
                color: gifted
                    ? palette.pink
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (widget.mode == SplitMode.equal)
            Text(
              formatMoney(widget.amountCents, widget.currency),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                decoration: gifted ? TextDecoration.lineThrough : null,
                color: gifted ? theme.colorScheme.onSurfaceVariant : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            )
          else
            _ShareField(
              controller: _input,
              focusNode: _focus,
              suffix: widget.mode == SplitMode.percent
                  ? '%'
                  : currencySymbol(widget.currency).trim(),
              // In percent mode the resolved cents are the answer the user
              // actually wants; the percentage is only how they said it.
              helper: widget.mode == SplitMode.percent
                  ? formatMoney(
                      widget.amountCents,
                      widget.currency,
                      compact: true,
                    )
                  : null,
              onChanged: _commit,
            ),
        ],
      ),
    );
  }
}

class _ShareField extends StatelessWidget {
  const _ShareField({
    required this.controller,
    required this.focusNode,
    required this.suffix,
    required this.helper,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String suffix;
  final String? helper;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 104,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.end,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            decoration: InputDecoration(
              isDense: true,
              hintText: '0',
              suffixText: suffix,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: LuqaSpacing.sm,
                vertical: LuqaSpacing.md,
              ),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            onChanged: onChanged,
          ),
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(top: LuqaSpacing.xs),
              child: Text(
                helper!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
