import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/money/application/money_controller.dart';
import 'package:luqa/features/money/application/person_ledger_provider.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/presentation/expense_sheet.dart';
import 'package:luqa/features/money/presentation/money_formatters.dart';
import 'package:luqa/features/money/presentation/person_editor_sheet.dart';
import 'package:luqa/features/money/presentation/settle_up_sheet.dart';
import 'package:luqa/features/money/presentation/widgets/person_avatar.dart';

/// One person, and everything between them and the user.
///
/// The focal object is the balance; the history under it is the evidence for
/// it. Settling up is the one filled action, and it opens pre-filled with the
/// exact amount outstanding — the number the user came here to clear.
class PersonLedgerScreen extends ConsumerWidget {
  const PersonLedgerScreen({required this.personId, super.key});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(personLedgerProvider(personId));
    final overview = ref.watch(moneyControllerProvider).overview;
    final now = ref.watch(moneyNowProvider);
    // Before the ledger arrives, the overview already knows the name — enough
    // for a title bar that does not flash "…" on the way in.
    final known = overview?.personById(personId);

    return Scaffold(
      appBar: AppBar(
        title: Text(ledger.value?.person.name ?? known?.name ?? 'Person'),
        actions: [
          if (ledger.value?.person ?? known case final person?)
            IconButton(
              tooltip: 'Edit person',
              onPressed: () => showPersonEditorSheet(context, ref, person: person),
              icon: const Icon(Icons.tune_rounded),
            ),
        ],
      ),
      body: ledger.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LedgerError(
          onRetry: () => ref.invalidate(personLedgerProvider(personId)),
        ),
        data: (data) => _Ledger(
          ledger: data,
          overview: overview,
          now: now,
          onRefresh: () async {
            await ref.read(moneyControllerProvider.notifier).refresh();
            ref.invalidate(personLedgerProvider(personId));
          },
        ),
      ),
    );
  }
}

class _Ledger extends ConsumerWidget {
  const _Ledger({
    required this.ledger,
    required this.overview,
    required this.now,
    required this.onRefresh,
  });

  final PersonLedger ledger;
  final MoneyOverview? overview;
  final DateTime now;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final person = ledger.person;
    final balance = ledger.balanceCents;
    final settled = balance == 0;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              LuqaSpacing.lg,
              LuqaSpacing.sm,
              LuqaSpacing.lg,
              0,
            ),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    PersonAvatar(
                      name: person.name,
                      colorValue: person.colorValue,
                      emoji: person.emoji,
                      size: 56,
                    ),
                    const SizedBox(width: LuqaSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settled
                                ? 'Settled up'
                                : balanceLabel(balance, person.name),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: LuqaSpacing.xs),
                          Text(
                            formatMoney(balance.abs(), ledger.currency),
                            key: const ValueKey('ledger-balance'),
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: settled
                                  ? theme.colorScheme.onSurfaceVariant
                                  : balance > 0
                                  ? palette.credit
                                  : palette.debit,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (ledger.coveredCents > 0) ...[
                  const SizedBox(height: LuqaSpacing.lg),
                  Row(
                    children: [
                      Icon(
                        Icons.card_giftcard_rounded,
                        size: 15,
                        color: palette.pink,
                      ),
                      const SizedBox(width: LuqaSpacing.sm),
                      Expanded(
                        child: Text(
                          '${formatMoney(ledger.coveredCents, ledger.currency, compact: true)} '
                          'covered for ${person.name}'
                          '${ledger.coveredThisYearCents > 0 ? ' · ${formatMoney(ledger.coveredThisYearCents, ledger.currency, compact: true)} this year' : ''}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: LuqaSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: settled
                              ? null
                              : () => showSettleUpSheet(
                                  context,
                                  ref,
                                  person: person,
                                  balanceCents: balance,
                                  currency: ledger.currency,
                                ),
                          child: Text(settled ? 'Nothing to settle' : 'Settle up'),
                        ),
                      ),
                    ),
                    const SizedBox(width: LuqaSpacing.sm),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: overview == null
                            ? null
                            : () => showExpenseSheet(
                                context,
                                ref,
                                overview: overview!,
                                presetPersonIds: [person.id],
                              ),
                        child: const Text('Add expense'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: LuqaSpacing.section),
                Text('History', style: theme.textTheme.titleLarge),
              ],
            ),
          ),
          if (ledger.items.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(LuqaSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Nothing between you two yet.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: LuqaSpacing.lg),
              sliver: SliverList.separated(
                itemCount: ledger.items.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) => _LedgerRow(
                  item: ledger.items[index],
                  currency: ledger.currency,
                  now: now,
                  onTap: () {
                    final expense = ledger.items[index].expense;
                    final current = overview;
                    if (expense == null || current == null) return;
                    showExpenseSheet(
                      context,
                      ref,
                      overview: current,
                      expense: expense,
                    );
                  },
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
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.item,
    required this.currency,
    required this.now,
    required this.onTap,
  });

  final LedgerItem item;
  final String currency;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);

    final detail = <String>[
      if (item.gifted)
        'Treat · ${formatMoney(item.shareCents, currency, compact: true)}'
      else if (item.isSettlement)
        item.direction == SettlementDirection.toMe
            ? 'They paid you'
            : 'You paid them'
      else if (item.amountCents != null)
        'Their share of ${formatMoney(item.amountCents!, currency, compact: true)}',
    ];

    return InkWell(
      onTap: item.expense == null ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 76,
              child: Text(
                moneyDayLabel(context, item.dateKey, now),
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
                      if (item.isSettlement) ...[
                        Icon(
                          Icons.handshake_outlined,
                          size: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: LuqaSpacing.xs),
                      ] else if (item.gifted) ...[
                        Icon(
                          Icons.card_giftcard_rounded,
                          size: 15,
                          color: palette.pink,
                        ),
                        const SizedBox(width: LuqaSpacing.xs),
                      ],
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (detail.isNotEmpty)
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
              item.deltaCents == 0
                  ? '—'
                  : formatMoney(
                      item.deltaCents,
                      currency,
                      signed: true,
                      compact: true,
                    ),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: item.deltaCents == 0
                    ? theme.colorScheme.onSurfaceVariant
                    : item.deltaCents > 0
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

class _LedgerError extends StatelessWidget {
  const _LedgerError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(LuqaSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 32),
          const SizedBox(height: LuqaSpacing.lg),
          const Text(
            'This history needs the network. The balance on the money tab is '
            'already up to date.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuqaSpacing.lg),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
