import 'package:luqa/core/id/local_id.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/money/data/money_cache.dart';
import 'package:luqa/features/money/data/money_outbox.dart';
import 'package:luqa/features/money/data/money_overlay.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/domain/money_models.dart';

/// Makes the money tab work on the phone.
///
/// Splitting a bill, adding someone, and settling up all complete without a
/// round trip: the row is given an id here, recorded in the queue, and handed
/// straight back with the balances already moved. Reads come back as the
/// server's last known state with the queue laid over the top.
class LocalFirstMoneyRepository implements MoneyRepository {
  LocalFirstMoneyRepository({
    required this.remote,
    required this.cache,
    required this.queue,
    String Function()? mintId,
    DateTime Function()? now,
  }) : _mintId = mintId ?? newLocalId,
       _now = now ?? DateTime.now;

  final MoneyRepository remote;
  final MoneyCache cache;
  final MutationQueue<MoneyMutation> queue;

  final String Function() _mintId;
  final DateTime Function() _now;

  /// Mirrors the server's default so someone added offline usually keeps the
  /// colour they were given once it syncs.
  static const fallbackColor = 0xFF6366F1;

  @override
  Future<MoneyOverview> loadOverview() async {
    await queue.ready;
    try {
      final overview = await remote.loadOverview();
      await cache.writeOverview(overview);
      return overlayMoney(overview, queue.pending);
    } on Object {
      // Offline is a normal state for a phone, not an error page. The cached
      // overview with local work on top is a complete, usable screen.
      final cached = await cache.readOverview();
      if (cached == null) rethrow;
      return overlayMoney(cached, queue.pending);
    }
  }

  /// The server's last answer with the queue laid over it, or null when this
  /// device has never stored one.
  ///
  /// This is the view to re-derive after a local write: the cache holds the
  /// server's copy, so applying the queue to it is the only way to get a
  /// figure that is neither stale nor double-counted.
  Future<MoneyOverview?> cachedOverview() async {
    await queue.ready;
    final cached = await cache.readOverview();
    return cached == null ? null : overlayMoney(cached, queue.pending);
  }

  /// What to paint on a device that has never completed a load — a fresh
  /// install where the first thing that happened was splitting a bill in a
  /// basement. Null when there is genuinely nothing to show.
  ///
  /// Kept apart from [cachedOverview] on purpose: an overview derived from
  /// nothing but the queue is the right screen here and the wrong one after a
  /// write, where it would drop every person the server already knows about.
  Future<MoneyOverview?> queuedOverview() async {
    await queue.ready;
    final pending = overlayMoney(MoneyOverview.empty, queue.pending);
    return pending.people.isEmpty && pending.groups.isEmpty ? null : pending;
  }

  /// The cached bill feed alone, for the same reason.
  Future<List<Expense>?> cachedExpenses() async {
    await queue.ready;
    final cached = await cache.readExpenses();
    if (cached == null && queue.pending.isEmpty) return null;
    return overlayExpenses(cached ?? const [], queue.pending);
  }

  @override
  Future<ExpensePage> loadExpenses({
    String? personId,
    String? groupId,
    String? cursor,
    int limit = 20,
  }) async {
    await queue.ready;
    final firstPage = cursor == null;
    try {
      final page = await remote.loadExpenses(
        personId: personId,
        groupId: groupId,
        cursor: cursor,
        limit: limit,
      );
      // Only the head of an unfiltered feed is worth caching; a page deep in
      // history, or one narrowed to a person, is not what the screen opens on.
      if (firstPage && personId == null && groupId == null) {
        await cache.writeExpenses(page.expenses);
      }
      // A cursor into history is asking about rows the server already holds,
      // and a bill entered here belongs at the top rather than in page four.
      if (!firstPage) return page;
      return ExpensePage(
        expenses: overlayExpenses(
          page.expenses,
          queue.pending,
          personId: personId,
          groupId: groupId,
        ),
        nextCursor: page.nextCursor,
      );
    } on Object {
      if (!firstPage) rethrow;
      final cached = await cache.readExpenses();
      if (cached == null) rethrow;
      return ExpensePage(
        expenses: overlayExpenses(
          cached,
          queue.pending,
          personId: personId,
          groupId: groupId,
        ),
        nextCursor: null,
      );
    }
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
    await queue.enqueue(mutation);
    return mutation.expense;
  }

  @override
  Future<Expense> updateExpense(String id, ExpenseWrite write) async {
    await queue.ready;
    final previous = await _knownExpense(id);
    // Nothing on this device remembers the bill — which happens when it was
    // paged in and then evicted. Sending the edit is still right; the overlay
    // simply has nothing to reverse until the next refresh answers.
    final mutation = UpdateExpense(
      expenseId: id,
      write: write,
      previous: previous ?? write.resolve(id: id, createdAt: _now()),
      queuedAt: _now(),
    );
    await queue.enqueue(mutation);
    return mutation.expense;
  }

  @override
  Future<void> deleteExpense(String id) async {
    await queue.ready;
    final previous = await _knownExpense(id);
    if (previous == null) {
      // With no local copy there is no balance effect to take back out, but
      // the server still has to hear about the delete.
      await remote.deleteExpense(id);
      return;
    }
    await queue.enqueue(DeleteExpense(previous: previous, queuedAt: _now()));
  }

  @override
  Future<PersonLedger> loadLedger(String personId) async {
    await queue.ready;
    return overlayLedger(await remote.loadLedger(personId), queue.pending);
  }

  @override
  Future<Person> createPerson({String? id, required PersonWrite write}) async {
    await queue.ready;
    final known = await _knownOverview();
    // Adding someone the device already knows by name is the same person, not
    // a second row for the server to merge — the same rule the API applies.
    for (final balance in known.people) {
      if (balance.person.name.toLowerCase() == write.name.toLowerCase()) {
        return balance.person;
      }
    }

    final person = Person(
      id: id ?? _mintId(),
      name: write.name,
      colorValue: write.colorValue == 0 ? fallbackColor : write.colorValue,
      emoji: write.emoji,
      defaultPercent: write.defaultPercent,
      order: known.people.length,
      archived: false,
    );
    await queue.enqueue(CreatePerson(person: person, queuedAt: _now()));
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
    await queue.enqueue(mutation);

    for (final balance in (await _knownOverview()).people) {
      if (balance.id == id) return balance.person;
    }
    return mutation.applyTo(
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
  }

  @override
  Future<void> deletePerson(String id) async {
    await queue.ready;
    await queue.enqueue(DeletePerson(personId: id, queuedAt: _now()));
  }

  @override
  Future<PersonGroup> createGroup({
    String? id,
    required GroupWrite write,
  }) async {
    await queue.ready;
    final known = await _knownOverview();
    for (final group in known.groups) {
      if (group.name.toLowerCase() == write.name.toLowerCase()) return group;
    }

    final group = PersonGroup(
      id: id ?? _mintId(),
      name: write.name,
      colorValue: write.colorValue == 0 ? fallbackColor : write.colorValue,
      emoji: write.emoji,
      order: known.groups.length,
      archived: false,
      memberIds: write.memberIds,
    );
    await queue.enqueue(CreateGroup(group: group, queuedAt: _now()));
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
    await queue.enqueue(mutation);

    for (final group in (await _knownOverview()).groups) {
      if (group.id == id) return group;
    }
    return mutation.applyTo(
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
  }

  @override
  Future<void> deleteGroup(String id) async {
    await queue.ready;
    await queue.enqueue(DeleteGroup(groupId: id, queuedAt: _now()));
  }

  @override
  Future<Settlement> createSettlement({
    String? id,
    required SettlementWrite write,
  }) async {
    await queue.ready;
    final settlement = Settlement(
      id: id ?? _mintId(),
      personId: write.personId,
      amountCents: write.amountCents,
      direction: write.direction,
      dateKey: write.dateKey,
      notes: write.notes,
      createdAt: _now(),
    );
    await queue.enqueue(
      CreateSettlement(settlement: settlement, queuedAt: _now()),
    );
    return settlement;
  }

  @override
  Future<void> deleteSettlement(String id) async {
    await queue.ready;
    final previous = await _knownSettlement(id);
    if (previous == null) {
      await remote.deleteSettlement(id);
      return;
    }
    await queue.enqueue(
      DeleteSettlement(previous: previous, queuedAt: _now()),
    );
  }

  /// What this device believes the world looks like right now.
  Future<MoneyOverview> _knownOverview() async => overlayMoney(
    await cache.readOverview() ?? MoneyOverview.empty,
    queue.pending,
  );

  /// The bill as this device last saw it — from the queue if it was entered
  /// here, from the cached feed otherwise.
  Future<Expense?> _knownExpense(String id) async {
    for (final expense in overlayExpenses(
      await cache.readExpenses() ?? const [],
      queue.pending,
    )) {
      if (expense.id == id) return expense;
    }
    return null;
  }

  /// A payback is only reversible from the queue: settlements are not part of
  /// the cached feed, so one made on another device is deleted server-side.
  Future<Settlement?> _knownSettlement(String id) async {
    for (final pending in queue.pending) {
      if (pending is CreateSettlement && pending.settlement.id == id) {
        return pending.settlement;
      }
    }
    return null;
  }
}
