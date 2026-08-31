import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/money/application/money_controller.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/presentation/expense_sheet.dart';
import 'package:luqa/features/money/presentation/money_formatters.dart';
import 'package:luqa/features/money/presentation/widgets/balance_row.dart';
import 'package:luqa/features/money/presentation/widgets/expense_row.dart';
import 'package:luqa/features/money/presentation/widgets/person_avatar.dart';
import 'package:luqa/features/money/presentation/widgets/position_bar.dart';

/// The money tab.
///
/// One focal object: the net position, at display size. Everything under it —
/// the two directions, the people, the bills — is support, and is deliberately
/// quieter than it would be if it were competing.
class MoneyScreen extends ConsumerWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moneyControllerProvider);
    final controller = ref.read(moneyControllerProvider.notifier);
    final overview = state.overview;
    final now = ref.watch(moneyNowProvider);

    if (state.isLoading && overview == null) {
      return const SafeArea(child: _MoneySkeleton());
    }
    if (overview == null) {
      return SafeArea(
        child: _MoneyLoadError(
          message: state.error ?? 'Could not load your money.',
          onRetry: controller.load,
        ),
      );
    }

    Future<void> compose({
      Expense? expense,
      List<String> personIds = const [],
      String? groupId,
    }) => showExpenseSheet(
      context,
      ref,
      overview: overview,
      expense: expense,
      presetPersonIds: personIds,
      presetGroupId: groupId,
    );

    final listed = overview.listed;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LuqaSpacing.lg,
                LuqaSpacing.xl,
                LuqaSpacing.lg,
                0,
              ),
              sliver: SliverList.list(
                children: [
                  _Header(
                    pendingWrites: state.pendingWrites,
                    onRetry: controller.refresh,
                  ),
                  const SizedBox(height: LuqaSpacing.xl),
                  _Headline(overview: overview),
                  if (state.error != null) ...[
                    const SizedBox(height: LuqaSpacing.md),
                    _InlineError(
                      message: state.error!,
                      onRetry: controller.refresh,
                    ),
                  ],
                  const SizedBox(height: LuqaSpacing.xl),
                  _AddExpenseButton(onTap: compose),
                  if (listed.isNotEmpty || overview.groups.isNotEmpty) ...[
                    const SizedBox(height: LuqaSpacing.md),
                    _QuickStart(
                      overview: overview,
                      onPickGroup: (group) => compose(
                        personIds: group.memberIds,
                        groupId: group.id,
                      ),
                      onPickPerson: (person) => compose(personIds: [person.id]),
                    ),
                  ],
                  const SizedBox(height: LuqaSpacing.section),
                  _SectionHeading(
                    title: 'Balances',
                    action: 'People',
                    onAction: () => context.push('/money/people'),
                  ),
                ],
              ),
            ),
            if (listed.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  LuqaSpacing.lg,
                  LuqaSpacing.lg,
                  LuqaSpacing.lg,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Log the next bill you pick up — people get added as you go.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LuqaSpacing.lg,
                ),
                sliver: SliverList.separated(
                  itemCount: listed.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) => BalanceRow(
                    key: ValueKey('balance-${listed[index].id}'),
                    balance: listed[index],
                    currency: overview.currency,
                    now: now,
                    onTap: () =>
                        context.push('/money/people/${listed[index].id}'),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LuqaSpacing.lg,
                LuqaSpacing.section,
                LuqaSpacing.lg,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _SectionHeading(
                  title: 'Bills',
                  action: overview.groups.isEmpty ? null : 'Groups',
                  onAction: () => context.push('/money/groups'),
                ),
              ),
            ),
            _ExpenseFeed(
              state: state,
              overview: overview,
              now: now,
              onOpen: (expense) => compose(expense: expense),
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
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.pendingWrites, required this.onRetry});

  final int pendingWrites;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Money',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
        // What is waiting to go out matters more than what is coming in: it is
        // the user's own record of who owes what.
        if (pendingWrites > 0)
          _PendingChip(count: pendingWrites, onRetry: onRetry),
      ],
    );
  }
}

class _PendingChip extends StatelessWidget {
  const _PendingChip({required this.count, required this.onRetry});

  final int count;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      liveRegion: true,
      child: IconButton(
        key: const ValueKey('money-pending-writes'),
        tooltip: count == 1
            ? '1 change waiting to sync. Tap to retry'
            : '$count changes waiting to sync. Tap to retry',
        onPressed: onRetry,
        visualDensity: VisualDensity.compact,
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 16, color: muted),
            const SizedBox(width: 3),
            Text(
              '$count',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// The focal object: one number, at display size, that answers the question
/// the tab exists for.
class _Headline extends StatelessWidget {
  const _Headline({required this.overview});

  final MoneyOverview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final net = overview.netCents;
    final settled = overview.isSettled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          settled
              ? 'All settled up'
              : net > 0
              ? "You're owed"
              : net < 0
              ? 'You owe'
              : 'Evens out',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: LuqaSpacing.sm),
        Text(
          formatMoney(net.abs(), overview.currency),
          key: const ValueKey('money-net'),
          style: theme.textTheme.displaySmall?.copyWith(
            color: settled || net == 0
                ? theme.colorScheme.onSurfaceVariant
                : net > 0
                ? palette.credit
                : palette.debit,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: LuqaSpacing.lg),
        PositionBar(
          owedToYouCents: overview.owedToYouCents,
          youOweCents: overview.youOweCents,
        ),
        const SizedBox(height: LuqaSpacing.md),
        Row(
          children: [
            Expanded(
              child: PositionLegend(
                label: 'Owed to you',
                amount: formatMoney(
                  overview.owedToYouCents,
                  overview.currency,
                  compact: true,
                ),
                color: palette.credit,
              ),
            ),
            Expanded(
              child: PositionLegend(
                label: 'You owe',
                amount: formatMoney(
                  overview.youOweCents,
                  overview.currency,
                  compact: true,
                ),
                color: palette.debit,
                alignEnd: true,
              ),
            ),
          ],
        ),
        if (overview.coveredCents > 0) ...[
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
                  '${formatMoney(overview.coveredCents, overview.currency, compact: true)} '
                  'covered as treats — tracked, never charged.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class _AddExpenseButton extends StatelessWidget {
  const _AddExpenseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // No busy state: the bill exists on the phone the moment it is saved.
    return SizedBox(
      height: 64,
      child: FilledButton(
        onPressed: onTap,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('Add expense'), Icon(Icons.arrow_forward_rounded)],
        ),
      ),
    );
  }
}

/// One tap to a bill with the usual suspects already on it.
class _QuickStart extends StatelessWidget {
  const _QuickStart({
    required this.overview,
    required this.onPickGroup,
    required this.onPickPerson,
  });

  final MoneyOverview overview;
  final void Function(PersonGroup group) onPickGroup;
  final void Function(Person person) onPickPerson;

  @override
  Widget build(BuildContext context) {
    final groups = [
      for (final group in overview.groups)
        if (!group.archived) group,
    ];
    final people = [
      for (final balance in overview.listed)
        if (!balance.person.archived) balance.person,
    ].take(6);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.xs),
      child: Row(
        children: [
          for (final group in groups) ...[
            _QuickChip(
              key: ValueKey('quick-group-${group.id}'),
              label: group.name,
              emoji: group.emoji ?? '👥',
              colorValue: group.colorValue,
              onTap: () => onPickGroup(group),
            ),
            const SizedBox(width: LuqaSpacing.sm),
          ],
          for (final person in people) ...[
            _QuickChip(
              key: ValueKey('quick-person-${person.id}'),
              label: person.name,
              emoji: person.emoji,
              colorValue: person.colorValue,
              onTap: () => onPickPerson(person),
            ),
            const SizedBox(width: LuqaSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.emoji,
    required this.colorValue,
    required this.onTap,
    super.key,
  });

  final String label;
  final String? emoji;
  final int colorValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LuqaRadii.compact),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(
            horizontal: LuqaSpacing.sm,
            vertical: LuqaSpacing.xs,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: LuqaPalette.of(context).border),
            borderRadius: BorderRadius.circular(LuqaRadii.compact),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PersonAvatar(
                name: label,
                colorValue: colorValue,
                emoji: emoji,
                size: 24,
              ),
              const SizedBox(width: LuqaSpacing.sm),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

/// The bill feed, grouped by month and paged as the user reaches the end.
class _ExpenseFeed extends ConsumerWidget {
  const _ExpenseFeed({
    required this.state,
    required this.overview,
    required this.now,
    required this.onOpen,
  });

  final MoneyState state;
  final MoneyOverview overview;
  final DateTime now;
  final void Function(Expense expense) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(moneyControllerProvider.notifier);
    final theme = Theme.of(context);

    if (state.expenses.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          LuqaSpacing.lg,
          LuqaSpacing.lg,
          LuqaSpacing.lg,
          0,
        ),
        sliver: SliverToBoxAdapter(
          child: state.feedError != null
              ? _InlineError(
                  message: state.feedError!,
                  onRetry: () => controller.load(refresh: true),
                )
              : Text(
                  'Nothing logged yet.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
      );
    }

    // A month heading appears above the first bill that belongs to it, so the
    // feed reads as a continuous record rather than a series of blocks.
    String? monthAbove(int index) {
      final label = moneyMonthLabel(context, state.expenses[index].dateKey, now);
      if (index == 0) return label;
      final previous = moneyMonthLabel(
        context,
        state.expenses[index - 1].dateKey,
        now,
      );
      return label == previous ? null : label;
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: LuqaSpacing.lg),
      sliver: SliverList.builder(
        itemCount: state.expenses.length + 1,
        itemBuilder: (context, index) {
          if (index == state.expenses.length) {
            return _FeedFooter(state: state, onLoadMore: controller.loadMore);
          }
          final month = monthAbove(index);
          final row = ExpenseRow(
            expense: state.expenses[index],
            currency: overview.currency,
            nameOf: overview.nameOf,
            now: now,
            onTap: () => onOpen(state.expenses[index]),
          );
          if (month == null) {
            return Column(children: [const Divider(), row]);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? LuqaSpacing.md : LuqaSpacing.xl,
                  bottom: LuqaSpacing.xs,
                ),
                child: Text(
                  month,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              row,
            ],
          );
        },
      ),
    );
  }
}

class _FeedFooter extends StatelessWidget {
  const _FeedFooter({required this.state, required this.onLoadMore});

  final MoneyState state;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state.feedError != null) {
      return Padding(
        padding: const EdgeInsets.only(top: LuqaSpacing.lg),
        child: _InlineError(message: state.feedError!, onRetry: onLoadMore),
      );
    }
    if (!state.hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: LuqaSpacing.md),
      child: state.isLoadingMore
          ? const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Center(
              child: TextButton(
                onPressed: onLoadMore,
                child: const Text('Load more'),
              ),
            ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.cloud_off_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: LuqaSpacing.sm),
        Expanded(child: Text(message)),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _MoneySkeleton extends StatelessWidget {
  const _MoneySkeleton();

  @override
  Widget build(BuildContext context) {
    final color = LuqaPalette.of(context).raised;
    Widget block(double height, {double? width}) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(LuqaRadii.compact),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(LuqaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(32, width: 120),
          const SizedBox(height: LuqaSpacing.xl),
          block(14, width: 80),
          const SizedBox(height: LuqaSpacing.sm),
          block(44, width: 210),
          const SizedBox(height: LuqaSpacing.lg),
          block(6),
          const SizedBox(height: LuqaSpacing.xl),
          block(64),
          const SizedBox(height: LuqaSpacing.section),
          block(64),
          const SizedBox(height: LuqaSpacing.sm),
          block(64),
        ],
      ),
    );
  }
}

class _MoneyLoadError extends StatelessWidget {
  const _MoneyLoadError({required this.message, required this.onRetry});

  final String message;
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
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: LuqaSpacing.lg),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
