import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/presentation/money_formatters.dart';
import 'package:luqa/features/money/presentation/widgets/person_avatar.dart';

/// One person's standing, as a row on a continuous surface.
///
/// Not a card: a list of cards turns fifteen people into fifteen competing
/// objects. Space, a divider and the amount's alignment do the separating.
class BalanceRow extends StatelessWidget {
  const BalanceRow({
    required this.balance,
    required this.currency,
    required this.onTap,
    this.now,
    super.key,
  });

  final PersonBalance balance;
  final String currency;
  final VoidCallback onTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final person = balance.person;
    final settled = balance.settled;
    final amountColor = settled
        ? theme.colorScheme.onSurfaceVariant
        : balance.balanceCents > 0
        ? palette.credit
        : palette.debit;

    final detail = <String>[
      if (settled)
        balance.lastActivity == null
            ? 'Nothing yet'
            : 'Settled up · ${moneyDayLabel(context, balance.lastActivity!, now ?? DateTime.now())}'
      else
        balanceLabel(balance.balanceCents, person.name),
      if (balance.coveredCents > 0)
        '${formatMoney(balance.coveredCents, currency, compact: true)} covered',
      if (person.archived) 'Archived',
    ];

    return InkWell(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: settled
            ? '${person.name}, settled up'
            : '${balanceLabel(balance.balanceCents, person.name)} '
                  '${formatMoney(balance.balanceCents.abs(), currency)}',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.md),
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
              const SizedBox(width: LuqaSpacing.md),
              Text(
                settled
                    ? '—'
                    : formatMoney(
                        balance.balanceCents.abs(),
                        currency,
                        compact: true,
                      ),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: amountColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
