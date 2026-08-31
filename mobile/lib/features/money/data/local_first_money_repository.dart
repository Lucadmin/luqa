import 'dart:async';

import 'package:luqa/core/id/local_id.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/money/data/money_local_store.dart';
import 'package:luqa/features/money/data/money_outbox.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/data/money_sync_service.dart';
import 'package:luqa/features/money/domain/money_models.dart';

/// Makes the money tab work on the phone.
///
/// Every read is answered from this device's own rows, and every write goes
/// into them before it goes anywhere else. There is no cached copy of the
/// server's answers and nothing laid over the top: a balance is a sum over
/// what is in the tables, so it is right the moment a bill is split at the
/// table and still right once the bill has synced.
///
/// The server's part is to be told, and to say what changed while this device
/// was not listening. Neither of those is on the path between a tap and the
/// screen.
class LocalFirstMoneyRepository implements MoneyRepository {
  LocalFirstMoneyRepository({
    required this.store,
    required this.sync,
    required this.queue,
    String Function()? mintId,
    DateTime Function()? now,
  }) : _mintId = mintId ?? newLocalId,
       _now = now ?? DateTime.now;

  final MoneyLocalStore store;
  final MoneySyncService sync;
  final MutationQueue<MoneyMutation> queue;

  final String Function() _mintId;
  final DateTime Function() _now;

  /// Mirrors the server's default so someone added offline usually keeps the
  /// colour they were given once it syncs.
  static const fallbackColor = 0xFF6366F1;

  // ----------------------------------------------------------------- reads

  @override
  Future<MoneyOverview> loadOverview() async {
    await queue.ready;
    return store.overview(await store.currency);
  }

  @override
  Future<ExpensePage> loadExpenses({
    String? personId,
    String? groupId,
    String? cursor,
    int limit = 20,
  }) async {
    await queue.ready;
    return store.expenses(
      personId: personId,
      groupId: groupId,
      cursor: cursor,
      limit: limit,
    );
  }

  @override
  Future<PersonLedger> loadLedger(String personId) async {
    await queue.ready;
    final ledger = await store.ledger(personId, await store.currency);
    if (ledger == null) {
      throw StateError('No person $personId on this device');
    }
    return ledger;
  }

  /// Catches up with the server. Kept apart from the reads because it is not
  /// on the path between a tap and the screen — the screen is already correct.
  Future<void> pull() => sync.pull();

  /// True when this device has never synced, so a screen can tell "nothing
  /// yet" apart from "nothing at all".
  Future<bool> get isUnsynced => store.isEmpty;

  // ---------------------------------------------------------------- writes

  /// Queues the mutation, writes the row, and only then lets the queue drain.
  ///
  /// Queueing first is on purpose: dying between the two leaves a write that
  /// will still be sent and a screen that catches up on the next sync, where
  /// the other order can lose it entirely. Holding the drain until the row is
  /// written matters just as much — sending immediately would let the server
  /// rename an id while the write that refers to it is still being made.
  Future<void> _write(
    MoneyMutation mutation,
    Future<void> Function() apply,
  ) async {
    await queue.enqueue(mutation, sendNow: false);
    await apply();
    unawaited(queue.sync());
  }

  @override
  Future<Expense> createExpense({
    String? id,
    required ExpenseWrite write,
  }) async {
    await queue.ready;
    final now = _now();
    final mutation = CreateExpense(
      expenseId: id ?? _mintId(),
      write: write,
      createdAt: now,
      queuedAt: now,
    );
    await _write(mutation, () => store.putExpense(mutation.expense));
    return mutation.expense;
  }

  @override
  Future<Expense> updateExpense(String id, ExpenseWrite write) async {
    await queue.ready;
    // The bill as it will be, computed here — the same arithmetic the server
    // will do, so the row on screen is the row that lands.
    final previous =
        await store.expenseById(id) ?? write.resolve(id: id, createdAt: _now());
    final mutation = UpdateExpense(
      expenseId: id,
      write: write,
      previous: previous,
      queuedAt: _now(),
    );
    await _write(mutation, () => store.putExpense(mutation.expense));
    return mutation.expense;
  }

  @override
  Future<void> deleteExpense(String id) async {
    await queue.ready;
    final previous = await store.expenseById(id);
    if (previous == null) {
      // Nothing here to take back out, but the server still has to hear it.
      await queue.enqueue(
        DeleteExpense(
          previous: Expense(
            id: id,
            description: '',
            amountCents: 0,
            dateKey: moneyDateKey(_now()),
            paidByPersonId: null,
            groupId: null,
            splitMode: SplitMode.equal,
            myShareCents: 0,
            notes: '',
            shares: const [],
            createdAt: _now(),
          ),
          queuedAt: _now(),
        ),
      );
      return;
    }
    await _write(
      DeleteExpense(previous: previous, queuedAt: _now()),
      () => store.remove('money_expense', id),
    );
  }

  @override
  Future<Person> createPerson({String? id, required PersonWrite write}) async {
    await queue.ready;
    // Adding someone this device already knows by name is the same person, not
    // a second row for the server to merge — the same rule the API applies.
    for (final person in await store.people()) {
      if (person.name.toLowerCase() == write.name.toLowerCase()) return person;
    }

    final person = Person(
      id: id ?? _mintId(),
      name: write.name,
      colorValue: write.colorValue == 0 ? fallbackColor : write.colorValue,
      emoji: write.emoji,
      defaultPercent: write.defaultPercent,
      order: (await store.people()).length,
      archived: false,
    );
    await _write(
      CreatePerson(person: person, queuedAt: _now()),
      () => store.putPerson(person),
    );
    return person;
  }

  @override
  Future<Person> updatePerson({
    required String id,
    String? name,
    int? colorValue,
    String? emoji,
    bool clearEmoji = false,
    int? defaultPercent,
    bool clearDefaultPercent = false,
    int? order,
    bool? archived,
  }) async {
    await queue.ready;
    final mutation = UpdatePerson(
      personId: id,
      name: name,
      colorValue: colorValue,
      emoji: emoji,
      clearEmoji: clearEmoji,
      defaultPercent: defaultPercent,
      clearDefaultPercent: clearDefaultPercent,
      order: order,
      archived: archived,
      queuedAt: _now(),
    );

    Person? existing;
    for (final person in await store.people()) {
      if (person.id == id) existing = person;
    }
    final updated = mutation.applyTo(
      existing ??
          Person(
            id: id,
            name: name ?? '',
            colorValue: colorValue ?? fallbackColor,
            emoji: emoji,
            defaultPercent: defaultPercent,
            order: order ?? 0,
            archived: archived ?? false,
          ),
    );

    await _write(mutation, () => store.putPerson(updated));
    return updated;
  }

  @override
  Future<void> deletePerson(String id) async {
    await queue.ready;
    await _write(
      DeletePerson(personId: id, queuedAt: _now()),
      () => store.remove('person', id),
    );
  }

  @override
  Future<PersonGroup> createGroup({
    String? id,
    required GroupWrite write,
  }) async {
    await queue.ready;
    for (final group in await store.groups()) {
      if (group.name.toLowerCase() == write.name.toLowerCase()) return group;
    }

    final group = PersonGroup(
      id: id ?? _mintId(),
      name: write.name,
      colorValue: write.colorValue == 0 ? fallbackColor : write.colorValue,
      emoji: write.emoji,
      order: (await store.groups()).length,
      archived: false,
      memberIds: write.memberIds,
    );
    await _write(
      CreateGroup(group: group, queuedAt: _now()),
      () => store.putGroup(group),
    );
    return group;
  }

  @override
  Future<PersonGroup> updateGroup({
    required String id,
    String? name,
    int? colorValue,
    String? emoji,
    bool clearEmoji = false,
    List<String>? memberIds,
    bool? archived,
  }) async {
    await queue.ready;
    final mutation = UpdateGroup(
      groupId: id,
      name: name,
      colorValue: colorValue,
      emoji: emoji,
      clearEmoji: clearEmoji,
      memberIds: memberIds,
      archived: archived,
      queuedAt: _now(),
    );

    PersonGroup? existing;
    for (final group in await store.groups()) {
      if (group.id == id) existing = group;
    }
    final updated = mutation.applyTo(
      existing ??
          PersonGroup(
            id: id,
            name: name ?? '',
            colorValue: colorValue ?? fallbackColor,
            emoji: emoji,
            order: 0,
            archived: archived ?? false,
            memberIds: memberIds ?? const [],
          ),
    );

    await _write(mutation, () => store.putGroup(updated));
    return updated;
  }

  @override
  Future<void> deleteGroup(String id) async {
    await queue.ready;
    await _write(
      DeleteGroup(groupId: id, queuedAt: _now()),
      () => store.remove('money_group', id),
    );
  }

  @override
  Future<Settlement> createSettlement({
    String? id,
    required SettlementWrite write,
  }) async {
    await queue.ready;
    final settlement = Settlement(
      id: id ?? _mintId(),
      // The sheet may be holding a person id the server has since replaced
      // with its own, having matched the name.
      personId: (await store.resolve('person', write.personId))!,
      amountCents: write.amountCents,
      direction: write.direction,
      dateKey: write.dateKey,
      notes: write.notes,
      createdAt: _now(),
    );
    await _write(
      CreateSettlement(settlement: settlement, queuedAt: _now()),
      () => store.putSettlement(settlement),
    );
    return settlement;
  }

  @override
  Future<void> deleteSettlement(String id) async {
    await queue.ready;
    final previous = await store.settlementById(id);
    if (previous == null) return;
    await _write(
      DeleteSettlement(previous: previous, queuedAt: _now()),
      () => store.remove('money_settlement', id),
    );
  }
}
