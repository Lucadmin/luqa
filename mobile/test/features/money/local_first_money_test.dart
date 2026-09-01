import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/core/storage/luqa_store.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/money/data/local_first_money_repository.dart';
import 'package:luqa/features/money/data/money_fold.dart';
import 'package:luqa/features/money/data/money_local_store.dart';
import 'package:luqa/features/money/data/money_outbox.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/data/money_sync_service.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/domain/money_split.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_store.dart';

/// Stands in for the sync engine's queue: folds like the real one, keeps what
/// it is given, and never sends anything.
class _TestQueue implements MutationQueue<MoneyMutation> {
  List<MoneyMutation> _queue = const [];

  @override
  Future<void> get ready async {}

  @override
  List<MoneyMutation> get pending => _queue;

  /// Nothing is ever sent in these tests; the queue is only here so a write
  /// has somewhere to go.
  @override
  Future<void> sync() async {}

  @override
  Future<void> enqueue(MoneyMutation mutation, {bool sendNow = true}) async {
    _queue = foldMoney(_queue, mutation);
  }
}

/// A network that is never reached. Every read in these tests is answered from
/// the device, which is the whole claim being tested.
class _UnreachableApi implements LuqaApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final _now = DateTime(2026, 8, 27, 12);

ExpenseWrite _bill({
  required int amountCents,
  String description = 'Dinner',
  String? paidByPersonId,
  List<SplitParticipant> participants = const [],
  bool includeMe = true,
  SplitMode splitMode = SplitMode.equal,
}) => ExpenseWrite(
  description: description,
  amountCents: amountCents,
  dateKey: '2026-08-27',
  paidByPersonId: paidByPersonId,
  groupId: null,
  splitMode: splitMode,
  includeMe: includeMe,
  participants: participants,
  notes: '',
);

void main() {
  sqfliteFfiInit();

  late LuqaStore store;
  late MoneyLocalStore local;
  late _TestQueue queue;
  late LocalFirstMoneyRepository repository;

  setUp(() {
    store = openTestStore();
    addTearDown(store.close);
    local = MoneyLocalStore(namespace: 'user-a', store: store);
    queue = _TestQueue();
    repository = LocalFirstMoneyRepository(
      store: local,
      sync: MoneySyncService(client: _UnreachableApi(), store: local),
      queue: queue,
      now: () => _now,
    );
  });

  /// Someone to split bills with, already on the device.
  Future<Person> givenPerson(String name) => repository.createPerson(
    write: PersonWrite(
      name: name,
      colorValue: 0xFF112233,
      emoji: null,
      defaultPercent: null,
    ),
  );

  group('writing', () {
    test('a bill split with no network is on the screen and in the queue',
        () async {
      final mira = await givenPerson('Mira');

      final saved = await repository.createExpense(
        write: _bill(
          amountCents: 3000,
          participants: [SplitParticipant(personId: mira.id)],
        ),
      );

      final page = await repository.loadExpenses();
      expect(page.expenses.single.id, saved.id);
      expect(page.expenses.single.description, 'Dinner');
      // Queued as well as stored: the server still has to hear about it.
      expect(queue.pending.whereType<CreateExpense>(), hasLength(1));
    });

    test('the balance moves the moment the bill is entered', () async {
      final mira = await givenPerson('Mira');

      await repository.createExpense(
        write: _bill(
          amountCents: 3000,
          participants: [SplitParticipant(personId: mira.id)],
        ),
      );

      final overview = await repository.loadOverview();
      // Split two ways: half the bill is hers, and the user fronted it.
      expect(overview.balanceOf(mira.id)!.balanceCents, 1500);
      expect(overview.owedToYouCents, 1500);
      expect(overview.youOweCents, 0);
    });

    test('editing a bill down does not leave the old amount behind', () async {
      // The failure the overlay needed a `previous` snapshot to avoid. Summing
      // the rows cannot get this wrong: there is only ever one row.
      final mira = await givenPerson('Mira');
      final saved = await repository.createExpense(
        write: _bill(
          amountCents: 5000,
          participants: [SplitParticipant(personId: mira.id)],
        ),
      );
      expect((await repository.loadOverview()).owedToYouCents, 2500);

      await repository.updateExpense(
        saved.id,
        _bill(
          amountCents: 3000,
          participants: [SplitParticipant(personId: mira.id)],
        ),
      );

      expect((await repository.loadOverview()).owedToYouCents, 1500);
      expect((await repository.loadExpenses()).expenses, hasLength(1));
    });

    test('a deleted bill stops counting immediately', () async {
      final mira = await givenPerson('Mira');
      final saved = await repository.createExpense(
        write: _bill(
          amountCents: 4000,
          participants: [SplitParticipant(personId: mira.id)],
        ),
      );

      await repository.deleteExpense(saved.id);

      expect((await repository.loadOverview()).owedToYouCents, 0);
      expect((await repository.loadExpenses()).expenses, isEmpty);
    });

    test('adding someone the device already knows is the same person',
        () async {
      final first = await givenPerson('Mira');
      final again = await givenPerson('mira');

      expect(again.id, first.id);
      expect((await repository.loadOverview()).people, hasLength(1));
    });
  });

  group('the balance rules', () {
    test('when someone else paid, only the user own slice is owed', () async {
      final mira = await givenPerson('Mira');

      await repository.createExpense(
        write: _bill(
          amountCents: 3000,
          paidByPersonId: mira.id,
          participants: [SplitParticipant(personId: mira.id)],
        ),
      );

      final overview = await repository.loadOverview();
      // She fronted it, so the user owes their half rather than being owed.
      expect(overview.balanceOf(mira.id)!.balanceCents, -1500);
      expect(overview.youOweCents, 1500);
      expect(overview.owedToYouCents, 0);
    });

    test('a treat is recorded but never becomes a debt', () async {
      final mira = await givenPerson('Mira');

      await repository.createExpense(
        write: _bill(
          amountCents: 3000,
          participants: [SplitParticipant(personId: mira.id, gifted: true)],
        ),
      );

      final overview = await repository.loadOverview();
      expect(overview.balanceOf(mira.id)!.balanceCents, 0);
      expect(overview.balanceOf(mira.id)!.coveredCents, 1500);
      expect(overview.coveredCents, 1500);
      expect(overview.owedToYouCents, 0);
    });

    test('a payback moves the balance back toward zero', () async {
      final mira = await givenPerson('Mira');
      await repository.createExpense(
        write: _bill(
          amountCents: 4000,
          participants: [SplitParticipant(personId: mira.id)],
        ),
      );

      await repository.createSettlement(
        write: SettlementWrite(
          personId: mira.id,
          amountCents: 2000,
          direction: SettlementDirection.toMe,
          dateKey: '2026-08-28',
          notes: '',
        ),
      );

      expect((await repository.loadOverview()).balanceOf(mira.id)!.balanceCents, 0);
    });

    test('two people on one bill each carry their own slice', () async {
      final mira = await givenPerson('Mira');
      final tom = await givenPerson('Tom');

      await repository.createExpense(
        write: _bill(
          amountCents: 3000,
          participants: [
            SplitParticipant(personId: mira.id),
            SplitParticipant(personId: tom.id),
          ],
        ),
      );

      final overview = await repository.loadOverview();
      expect(overview.balanceOf(mira.id)!.balanceCents, 1000);
      expect(overview.balanceOf(tom.id)!.balanceCents, 1000);
      expect(overview.owedToYouCents, 2000);
    });
  });

  group('the ledger', () {
    test('shows the bills and paybacks that made the balance', () async {
      final mira = await givenPerson('Mira');
      await repository.createExpense(
        write: _bill(
          amountCents: 4000,
          participants: [SplitParticipant(personId: mira.id)],
        ),
      );
      await repository.createSettlement(
        write: SettlementWrite(
          personId: mira.id,
          amountCents: 500,
          direction: SettlementDirection.toMe,
          dateKey: '2026-08-28',
          notes: '',
        ),
      );

      final ledger = await repository.loadLedger(mira.id);
      expect(ledger.items, hasLength(2));
      // Newest first: the payback came the day after the bill.
      expect(ledger.items.first.isSettlement, isTrue);
      expect(ledger.balanceCents, 1500);
    });
  });

  group('what the delta feed is allowed to touch', () {
    test('a synced row is replaced by the server copy', () async {
      await local.applyPeople([
        const Person(
          id: 'p1',
          name: 'Mira',
          colorValue: 0xFF000000,
          emoji: null,
          defaultPercent: null,
          order: 0,
          archived: false,
        ),
      ], const []);

      await local.applyPeople([
        const Person(
          id: 'p1',
          name: 'Mira Renamed',
          colorValue: 0xFF000000,
          emoji: null,
          defaultPercent: null,
          order: 0,
          archived: false,
        ),
      ], const []);

      expect((await local.people()).single.name, 'Mira Renamed');
    });

    test('a row this device has changed is left alone', () async {
      // The local copy is the newer one until the queue drains; a delta that
      // overwrote it would undo something the user just did.
      final mira = await givenPerson('Mira');
      await repository.updatePerson(id: mira.id, name: 'Mira Locally');

      await local.applyPeople([
        Person(
          id: mira.id,
          name: 'Mira From Server',
          colorValue: 0xFF000000,
          emoji: null,
          defaultPercent: null,
          order: 0,
          archived: false,
        ),
      ], const []);

      expect((await local.people()).single.name, 'Mira Locally');
    });

    test('a deletion the server reports removes the row here', () async {
      await local.applyPeople([
        const Person(
          id: 'p1',
          name: 'Mira',
          colorValue: 0xFF000000,
          emoji: null,
          defaultPercent: null,
          order: 0,
          archived: false,
        ),
      ], const []);

      await local.applyPeople(const [], const ['p1']);

      expect(await local.people(), isEmpty);
    });

    test('a deletion cannot undo a local change that has not been sent',
        () async {
      final mira = await givenPerson('Mira');
      await repository.updatePerson(id: mira.id, name: 'Still Here');

      await local.applyPeople(const [], [mira.id]);

      expect((await local.people()).single.name, 'Still Here');
    });
  });

  group('an id the server chose instead', () {
    test('everything pointing at the invented one follows it', () async {
      final mira = await givenPerson('Mira');
      await repository.createExpense(
        write: _bill(
          amountCents: 3000,
          participants: [SplitParticipant(personId: mira.id)],
        ),
      );

      await local.remapId('person', mira.id, 'server-mira');

      final overview = await repository.loadOverview();
      expect(overview.people.single.id, 'server-mira');
      // The bill followed her, so the balance is still hers.
      expect(overview.balanceOf('server-mira')!.balanceCents, 1500);
    });
  });
}
