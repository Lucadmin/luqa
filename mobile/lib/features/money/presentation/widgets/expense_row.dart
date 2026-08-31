import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/presentation/money_formatters.dart';

/// One bill in the feed.
///
/// The right-hand number is what the bill did to the user's balances, not the
/// total — the total is context and lives on the quiet line. "I paid ninety
/// and I am owed sixty" is two different facts, and the one worth aligning
/// down the edge of the list is the second.
class ExpenseRow extends StatelessWidget {
  const ExpenseRow({
    required this.expense,
    required this.currency,
    required this.nameOf,
    required this.now,
    required this.onTap,
    super.key,
  });

  final Expense expense;
  final String currency;
  final String Function(String personId) nameOf;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final delta = expense.deltaCents;
    final names = [
      for (final share in expense.shares) nameOf(share.personId),
    ].join(', ');

    final detail = <String>[
      formatMoney(expense.amountCents, currency, compact: true),
      if (names.isNotEmpty) 'with $names',
      if (expense.paidByPersonId != null)
        '${nameOf(expense.paidByPersonId!)} paid',
    ];

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 76,
              child: Text(
                moneyDayLabel(context, expense.dateKey, now),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: LuqaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (expense.hasGift) ...[
                        Icon(
                          Icons.card_giftcard_rounded,
                          size: 15,
                          color: palette.pink,
                        ),
                        const SizedBox(width: LuqaSpacing.xs),
                      ],
                      Flexible(
                        child: Text(
                          expense.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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
            const SizedBox(width: LuqaSpacing.sm),
            Text(
              delta == 0
                  ? '—'
                  : formatMoney(delta, currency, signed: true, compact: true),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: delta == 0
                    ? theme.colorScheme.onSurfaceVariant
                    : delta > 0
                    ? palette.credit
                    : palette.debit,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
