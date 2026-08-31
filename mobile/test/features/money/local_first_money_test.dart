import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/money/data/local_first_money_repository.dart';
import 'package:luqa/features/money/data/money_cache.dart';
import 'package:luqa/features/money/data/money_outbox.dart';
import 'package:luqa/features/money/data/money_overlay.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/domain/money_split.dart';

import '../../helpers/fake_money_repository.dart';

/// A queue that folds and keeps, without the engine's timers or network.
class _TestQueue implements MutationQueue<MoneyMutation> {
  final List<MoneyMutation> _queue = [];

  @override
  Future<void> get ready async {}

  @override
  List<MoneyMutation> get pending => _queue;

  @override
  Future<void> enqueue(MoneyMutation mutation) async {
    final folded = foldMoney(_queue, mutation);
    _queue
      ..clear()
      ..addAll(folded);
  }
}

class _MemoryCache implements MoneyCache {
  MoneyOverview? overview;
  List<Expense>? expenses;

  @override
  Future<MoneyOverview?> readOverview() async => overview;

  @override
  Future<void> writeOverview(MoneyOverview value) async => overview = value;

  @override
  Future<List<Expense>?> readExpenses() async => expenses;

  @override
  Future<void> writeExpenses(List<Expense> value) async => expenses = value;
}

({
  LocalFirstMoneyRepository repository,
  FakeMoneyRepository remote,
  _MemoryCache cache,
  _TestQueue queue,
})
_build() {
  final remote = FakeMoneyRepository.sample();
  final cache = _MemoryCache();
  final queue = _TestQueue();
  var minted = 0;
  return (
    repository: LocalFirstMoneyRepository(
      remote: remote,
      cache: cache,
      queue: queue,
      mintId: () => 'local-${++minted}',
      now: () => DateTime(2026, 8, 27, 12),
    ),
    remote: remote,
    cache: cache,
    queue: queue,
  );
}

ExpenseWrite _dinner({int amountCents = 3000}) => ExpenseWrite(
  description: 'Dinner',
  amountCents: amountCents,
  dateKey: '2026-08-27',
  paidByPersonId: null,
  groupId: null,
  splitMode: SplitMode.equal,
  includeMe: true,
  participants: const [SplitParticipant(personId: 'mira')],
  notes: '',
);

void main() {
  test('a bill is answered from the device, not the network', () async {
    final (:repository, :remote, :cache, :queue) = _build();
    remote.failure = StateError('no signal');

    final expense = await repository.createExpense(write: _dinner());

    expect(expense.id, 'local-1');
    expect(expense.myShareCents, 1500);
    expect(expense.shares.single.amountCents, 1500);
    expect(queue.pending, hasLength(1));
    // Nothing was attempted over the wire; the queue owns the sending.
    expect(remote.savedExpenses, isEmpty);
  });

  test('the overview reads through to the cache when the network is gone',
      () async {
    final (:repository, :remote, :cache, :queue) = _build();
    await repository.loadOverview();
    expect(cache.overview, isNotNull);

    remote.failure = StateError('no signal');
    final offline = await repository.loadOverview();
    expect(offline.people, hasLength(3));
    expect(offline.owedToYouCents, 4800);
  });

  test('a bill entered offline is in the balances on the next read', () async {
    final (:repository, :remote, :cache, :queue) = _build();
    await repository.loadOverview();

    remote.failure = StateError('no signal');
    await repository.createExpense(write: _dinner());

    final overview = await repository.loadOverview();
    final mira = overview.people.firstWhere((p) => p.id == 'mira');
    // 30.00 owed 15.00, on top of the 30.00 the server already knew about.
    expect(mira.balanceCents, 4500);
    expect(overview.owedToYouCents, 6300);
  });

  test('a fresh install with only queued work still has a screen to paint',
      () async {
    final (:repository, :remote, :cache, :queue) = _build();
    expect(await repository.queuedOverview(), isNull);

    await repository.createPerson(
      write: const PersonWrite(
        name: 'Ines',
        colorValue: 0xFF2563EB,
        emoji: null,
        defaultPercent: null,
      ),
    );

    final queued = await repository.queuedOverview();
    expect(queued, isNotNull);
    expect(queued!.people.single.person.name, 'Ines');
  });

  test('re-deriving after a write never drops the people the server knows',
      () async {
    final (:repository, :remote, :cache, :queue) = _build();
    await repository.loadOverview();
    // The disk is unreadable from here on — a rare failure, but one that must
    // not blank a screen that is already correct.
    cache.overview = null;

    await repository.createExpense(write: _dinner());

    // Nothing to re-derive from is answered with nothing, so the caller keeps
    // what it already has rather than adopting an overview built from a queue.
    expect(await repository.cachedOverview(), isNull);
  });

  test('adding somebody the device already knows returns them, not a twin',
      () async {
    final (:repository, :remote, :cache, :queue) = _build();
    await repository.loadOverview();

    final person = await repository.createPerson(
      write: const PersonWrite(
        name: 'mira',
        colorValue: 0xFF2563EB,
        emoji: null,
        defaultPercent: null,
      ),
    );

    expect(person.id, 'mira');
    expect(queue.pending, isEmpty);
  });

  test('editing an unsent bill leaves exactly one request to send', () async {
    final (:repository, :remote, :cache, :queue) = _build();
    final created = await repository.createExpense(write: _dinner());
    await repository.updateExpense(
      created.id,
      _dinner(amountCents: 9000),
    );

    expect(queue.pending, hasLength(1));
    final pending = queue.pending.single as CreateExpense;
    expect(pending.write.amountCents, 9000);
    expect(pending.expense.myShareCents, 4500);
  });

  test('deleting a bill that never synced empties the queue', () async {
    final (:repository, :remote, :cache, :queue) = _build();
    final created = await repository.createExpense(write: _dinner());
    await repository.deleteExpense(created.id);

    expect(queue.pending, isEmpty);
    expect(remote.deletedExpenses, isEmpty);
  });

  test('deleting a bill the server holds queues the delete', () async {
    final (:repository, :remote, :cache, :queue) = _build();
    final page = await repository.loadExpenses();
    expect(page.expenses, isNotEmpty);

    await repository.deleteExpense('dinner');

    expect(queue.pending.single, isA<DeleteExpense>());
    // The balance it produced comes back out straight away.
    final overview = await repository.loadOverview();
    final mira = overview.people.firstWhere((p) => p.id == 'mira');
    expect(mira.balanceCents, 0);
  });

  test('a payback clears the balance before it is sent', () async {
    final (:repository, :remote, :cache, :queue) = _build();
    await repository.loadOverview();
    remote.failure = StateError('no signal');

    await repository.createSettlement(
      write: const SettlementWrite(
        personId: 'mira',
        amountCents: 3000,
        direction: SettlementDirection.toMe,
        dateKey: '2026-08-27',
        notes: '',
      ),
    );

    final overview = await repository.loadOverview();
    expect(overview.balanceOf('mira')!.balanceCents, 0);
  });

  test('the bill feed keeps its cursor and does not overlay deeper pages',
      () async {
    final (:repository, :remote, :cache, :queue) = _build();
    await repository.createExpense(write: _dinner());

    final first = await repository.loadExpenses();
    expect(first.expenses.first.id, 'local-1');

    final deeper = await repository.loadExpenses(cursor: 'page-2');
    expect(deeper.expenses.any((e) => e.id == 'local-1'), isFalse);
  });

  test('a person ledger carries unsent work', () async {
    final (:repository, :remote, :cache, :queue) = _build();
    await repository.createExpense(write: _dinner());

    final ledger = await repository.loadLedger('mira');
    expect(ledger.items.first.id, 'local-1');
    // 30.00 on the server plus 15.00 not yet sent.
    expect(ledger.balanceCents, 4500);
  });
}
