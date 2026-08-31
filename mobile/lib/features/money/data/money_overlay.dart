import 'package:luqa/features/money/data/money_outbox.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/domain/money_split.dart';

/// Compacting the queue, and laying it over what the server last said.
///
/// The overlay is the only view that is true both before and after a write
/// lands: it is the server's answer with this device's own unsent work applied
/// on top, so a bill split with no signal is on screen — and counted in every
/// balance — the moment it is entered.

/// Appends [next], folding it into whatever is already queued for the same row.
///
/// The point is that a bill edited five times offline leaves one request, and
/// a bill created then deleted before it ever synced leaves none.
List<MoneyMutation> foldMoney(List<MoneyMutation> queue, MoneyMutation next) {
  switch (next) {
    case UpdateExpense(:final expenseId, :final write):
      final folded = <MoneyMutation>[];
      var absorbed = false;
      for (final pending in queue) {
        switch (pending) {
          // Editing a bill that has not been created yet is just a different
          // create; there is nothing on the server to patch.
          case CreateExpense(expenseId: final id) when id == expenseId:
            folded.add(
              CreateExpense(
                expenseId: expenseId,
                write: write,
                createdAt: pending.createdAt,
                queuedAt: pending.queuedAt,
              ),
            );
            absorbed = true;
          // A bill is saved wholesale, so only the newest edit matters.
          case UpdateExpense(expenseId: final id) when id == expenseId:
            folded.add(
              UpdateExpense(
                expenseId: expenseId,
                write: write,
                previous: pending.previous,
                queuedAt: pending.queuedAt,
              ),
            );
            absorbed = true;
          case _:
            folded.add(pending);
        }
      }
      return absorbed ? folded : [...folded, next];

    case DeleteExpense(previous: final expense):
      // A bill created and deleted on the same offline stretch never has to
      // reach the server at all.
      final createdHere = queue.any(
        (pending) =>
            pending is CreateExpense && pending.expenseId == expense.id,
      );
      final kept = [
        for (final pending in queue)
          if (!_touchesExpense(pending, expense.id)) pending,
      ];
      return createdHere ? kept : [...kept, next];

    case UpdatePerson(:final personId):
      final folded = <MoneyMutation>[];
      var absorbed = false;
      for (final pending in queue) {
        switch (pending) {
          case CreatePerson(:final person) when person.id == personId:
            folded.add(
              CreatePerson(
                person: next.applyTo(person),
                queuedAt: pending.queuedAt,
              ),
            );
            absorbed = true;
          case UpdatePerson(personId: final id) when id == personId:
            folded.add(next.mergedOver(pending));
            absorbed = true;
          case _:
            folded.add(pending);
        }
      }
      return absorbed ? folded : [...folded, next];

    case DeletePerson(:final personId):
      final createdHere = queue.any(
        (pending) => pending is CreatePerson && pending.person.id == personId,
      );
      final kept = [
        for (final pending in queue)
          if (!_touchesPerson(pending, personId)) pending,
      ];
      return createdHere ? kept : [...kept, next];

    case UpdateGroup(:final groupId):
      final folded = <MoneyMutation>[];
      var absorbed = false;
      for (final pending in queue) {
        switch (pending) {
          case CreateGroup(:final group) when group.id == groupId:
            folded.add(
              CreateGroup(
                group: next.applyTo(group),
                queuedAt: pending.queuedAt,
              ),
            );
            absorbed = true;
          case UpdateGroup(groupId: final id) when id == groupId:
            folded.add(next.mergedOver(pending));
            absorbed = true;
          case _:
            folded.add(pending);
        }
      }
      return absorbed ? folded : [...folded, next];

    case DeleteGroup(:final groupId):
      final createdHere = queue.any(
        (pending) => pending is CreateGroup && pending.group.id == groupId,
      );
      final kept = [
        for (final pending in queue)
          if (!_touchesGroup(pending, groupId)) pending,
      ];
      return createdHere ? kept : [...kept, next];

    case DeleteSettlement(previous: final settlement):
      final createdHere = queue.any(
        (pending) =>
            pending is CreateSettlement &&
            pending.settlement.id == settlement.id,
      );
      final kept = [
        for (final pending in queue)
          if (!(pending is CreateSettlement &&
              pending.settlement.id == settlement.id))
            pending,
      ];
      return createdHere ? kept : [...kept, next];

    case CreateExpense() ||
        CreatePerson() ||
        CreateGroup() ||
        CreateSettlement():
      return [...queue, next];
  }
}

bool _touchesExpense(MoneyMutation pending, String expenseId) => switch (pending) {
  CreateExpense(expenseId: final id) => id == expenseId,
  UpdateExpense(expenseId: final id) => id == expenseId,
  DeleteExpense(:final previous) => previous.id == expenseId,
  _ => false,
};

bool _touchesPerson(MoneyMutation pending, String personId) => switch (pending) {
  CreatePerson(:final person) => person.id == personId,
  UpdatePerson(personId: final id) => id == personId,
  DeletePerson(personId: final id) => id == personId,
  _ => false,
};

bool _touchesGroup(MoneyMutation pending, String groupId) => switch (pending) {
  CreateGroup(:final group) => group.id == groupId,
  UpdateGroup(groupId: final id) => id == groupId,
  DeleteGroup(groupId: final id) => id == groupId,
  _ => false,
};

/// How one bill moves the balances, from the user's point of view.
///
/// The rules are the server's, restated:
///   · the user paid       → every other participant's share is owed to them
///   · someone else paid   → only the user's own slice matters; what the rest
///                           owe is between them and whoever paid
///   · a gifted share      → moves no balance, only the "covered" total
void _applyExpense(
  Expense expense,
  int sign,
  Map<String, int> balances,
  Map<String, int> covered,
) {
  if (expense.paidByPersonId == null) {
    for (final share in expense.shares) {
      if (share.gifted) {
        covered[share.personId] =
            (covered[share.personId] ?? 0) + sign * share.amountCents;
      } else {
        balances[share.personId] =
            (balances[share.personId] ?? 0) + sign * share.amountCents;
      }
    }
    return;
  }
  final payer = expense.paidByPersonId!;
  balances[payer] = (balances[payer] ?? 0) - sign * expense.myShareCents;
}

/// Lays the queue over a server snapshot, so what the user sees is what they
/// did, whether or not it has been sent yet.
MoneyOverview overlayMoney(
  MoneyOverview overview,
  List<MoneyMutation> queue,
) {
  if (queue.isEmpty) return overview;

  final people = <String, Person>{
    for (final balance in overview.people) balance.id: balance.person,
  };
  final groups = <String, PersonGroup>{
    for (final group in overview.groups) group.id: group,
  };
  final balances = <String, int>{
    for (final balance in overview.people) balance.id: balance.balanceCents,
  };
  final covered = <String, int>{
    for (final balance in overview.people) balance.id: balance.coveredCents,
  };
  final lastActivity = <String, String?>{
    for (final balance in overview.people) balance.id: balance.lastActivity,
  };

  void touch(String personId, String dateKey) {
    final known = lastActivity[personId];
    if (known == null || dateKey.compareTo(known) > 0) {
      lastActivity[personId] = dateKey;
    }
  }

  void touchAll(Expense expense) {
    for (final share in expense.shares) {
      touch(share.personId, expense.dateKey);
    }
    final payer = expense.paidByPersonId;
    if (payer != null) touch(payer, expense.dateKey);
  }

  for (final pending in queue) {
    switch (pending) {
      case CreateExpense():
        _applyExpense(pending.expense, 1, balances, covered);
        touchAll(pending.expense);
      case UpdateExpense(:final previous):
        _applyExpense(previous, -1, balances, covered);
        _applyExpense(pending.expense, 1, balances, covered);
        touchAll(pending.expense);
      case DeleteExpense(:final previous):
        _applyExpense(previous, -1, balances, covered);
      case CreateSettlement(:final settlement):
        balances[settlement.personId] =
            (balances[settlement.personId] ?? 0) + settlement.deltaCents;
        touch(settlement.personId, settlement.dateKey);
      case DeleteSettlement(:final previous):
        balances[previous.personId] =
            (balances[previous.personId] ?? 0) - previous.deltaCents;
      case CreatePerson(:final person):
        people[person.id] = person;
      case UpdatePerson(:final personId):
        final existing = people[personId];
        if (existing != null) people[personId] = pending.applyTo(existing);
      case DeletePerson(:final personId):
        // Someone carrying a balance is archived rather than removed, exactly
        // as the server would do it, so the number does not vanish and come
        // back on the next refresh.
        final existing = people[personId];
        if (existing == null) continue;
        if ((balances[personId] ?? 0) != 0 || (covered[personId] ?? 0) != 0) {
          people[personId] = existing.copyWith(archived: true);
        } else {
          people.remove(personId);
          balances.remove(personId);
          covered.remove(personId);
          lastActivity.remove(personId);
        }
      case CreateGroup(:final group):
        groups[group.id] = group;
      case UpdateGroup(:final groupId):
        final existing = groups[groupId];
        if (existing != null) groups[groupId] = pending.applyTo(existing);
      case DeleteGroup(:final groupId):
        groups.remove(groupId);
    }
  }

  final rebuilt = [
    for (final person in people.values)
      PersonBalance(
        person: person,
        balanceCents: balances[person.id] ?? 0,
        coveredCents: covered[person.id] ?? 0,
        lastActivity: lastActivity[person.id],
      ),
  ]..sort(_byOutstanding);

  return overview.copyWith(
    people: rebuilt,
    groups: groups.values.toList()
      ..sort((left, right) => left.order.compareTo(right.order)),
    owedToYouCents: rebuilt.fold<int>(
      0,
      (sum, balance) => sum + (balance.balanceCents > 0 ? balance.balanceCents : 0),
    ),
    youOweCents: rebuilt.fold<int>(
      0,
      (sum, balance) =>
          sum + (balance.balanceCents < 0 ? -balance.balanceCents : 0),
    ),
    coveredCents: rebuilt.fold<int>(0, (sum, balance) => sum + balance.coveredCents),
  );
}

/// Whoever owes the most sits at the top; settled people sink to the bottom.
/// The same order the server sends, so the list does not jump when a refresh
/// replaces the overlay.
int _byOutstanding(PersonBalance left, PersonBalance right) {
  final byAmount = right.balanceCents.abs().compareTo(left.balanceCents.abs());
  if (byAmount != 0) return byAmount;
  final byOrder = left.person.order.compareTo(right.person.order);
  if (byOrder != 0) return byOrder;
  return left.person.name.compareTo(right.person.name);
}

/// The bill feed with this device's unsent work in it.
///
/// Only ever applied to the first page: a cursor into history is asking about
/// rows the server already holds, and a locally created bill belongs at the
/// top rather than wherever a later page happens to land.
List<Expense> overlayExpenses(
  List<Expense> expenses,
  List<MoneyMutation> queue, {
  String? personId,
  String? groupId,
}) {
  if (queue.isEmpty) return expenses;

  final byId = <String, Expense>{for (final expense in expenses) expense.id: expense};

  for (final pending in queue) {
    switch (pending) {
      case CreateExpense():
        byId[pending.expenseId] = pending.expense;
      case UpdateExpense():
        byId[pending.expenseId] = pending.expense;
      case DeleteExpense(:final previous):
        byId.remove(previous.id);
      case _:
        continue;
    }
  }

  bool matches(Expense expense) {
    if (groupId != null && expense.groupId != groupId) return false;
    if (personId == null) return true;
    return expense.paidByPersonId == personId ||
        expense.shares.any((share) => share.personId == personId);
  }

  return [
    for (final expense in byId.values)
      if (matches(expense)) expense,
  ]..sort((left, right) {
    final byDate = right.dateKey.compareTo(left.dateKey);
    return byDate != 0 ? byDate : right.createdAt.compareTo(left.createdAt);
  });
}

/// One person's history with this device's unsent work in it.
///
/// Rebuilt from the queue rather than patched, because a bill's contribution
/// to a ledger row depends on who paid and whether the slice was a gift — the
/// same three rules the server applies when it builds the list.
PersonLedger overlayLedger(PersonLedger ledger, List<MoneyMutation> queue) {
  if (queue.isEmpty) return ledger;

  final personId = ledger.person.id;
  final items = <String, LedgerItem>{
    for (final item in ledger.items) item.id: item,
  };
  var person = ledger.person;

  for (final pending in queue) {
    switch (pending) {
      case CreateExpense() || UpdateExpense():
        final expense = pending is CreateExpense
            ? pending.expense
            : (pending as UpdateExpense).expense;
        final item = _ledgerItemFor(expense, personId);
        if (item == null) {
          items.remove(expense.id);
        } else {
          items[expense.id] = item;
        }
      case DeleteExpense(:final previous):
        items.remove(previous.id);
      case CreateSettlement(:final settlement)
          when settlement.personId == personId:
        items[settlement.id] = LedgerItem(
          id: settlement.id,
          dateKey: settlement.dateKey,
          title: settlement.notes.isNotEmpty
              ? settlement.notes
              : settlement.direction == SettlementDirection.toMe
              ? 'Paid you back'
              : 'You paid them',
          deltaCents: settlement.deltaCents,
          shareCents: settlement.amountCents,
          gifted: false,
          amountCents: null,
          paidByPersonId: null,
          direction: settlement.direction,
          expense: null,
          createdAt: settlement.createdAt,
        );
      case DeleteSettlement(:final previous):
        items.remove(previous.id);
      case UpdatePerson(personId: final id) when id == personId:
        person = pending.applyTo(person);
      case _:
        continue;
    }
  }

  final ordered = items.values.toList()
    ..sort((left, right) {
      final byDate = right.dateKey.compareTo(left.dateKey);
      return byDate != 0 ? byDate : right.createdAt.compareTo(left.createdAt);
    });

  return ledger.copyWith(
    person: person,
    items: ordered,
    balanceCents: ordered.fold<int>(0, (sum, item) => sum + item.deltaCents),
    coveredCents: ordered.fold<int>(
      0,
      (sum, item) => sum + (item.gifted ? item.shareCents : 0),
    ),
    coveredThisYearCents: ordered.fold<int>(0, (sum, item) {
      final year = DateTime.now().year.toString().padLeft(4, '0');
      return sum +
          (item.gifted && item.dateKey.startsWith(year) ? item.shareCents : 0);
    }),
  );
}

/// The row one bill contributes to one person's history, or null when it
/// contributes nothing.
LedgerItem? _ledgerItemFor(Expense expense, String personId) {
  if (expense.paidByPersonId == personId) {
    // They paid: what the user owes them is the user's own slice. What the
    // others owe on that bill is between them and this person.
    if (expense.myShareCents == 0) return null;
    return LedgerItem(
      id: expense.id,
      dateKey: expense.dateKey,
      title: expense.title,
      deltaCents: -expense.myShareCents,
      shareCents: expense.myShareCents,
      gifted: false,
      amountCents: expense.amountCents,
      paidByPersonId: personId,
      direction: null,
      expense: expense,
      createdAt: expense.createdAt,
    );
  }

  // Somebody else fronted this one — it never touched the balance with this
  // person.
  if (expense.paidByPersonId != null) return null;

  for (final share in expense.shares) {
    if (share.personId != personId) continue;
    return LedgerItem(
      id: expense.id,
      dateKey: expense.dateKey,
      title: expense.title,
      deltaCents: share.gifted ? 0 : share.amountCents,
      shareCents: share.amountCents,
      gifted: share.gifted,
      amountCents: expense.amountCents,
      paidByPersonId: null,
      direction: null,
      expense: expense,
      createdAt: expense.createdAt,
    );
  }
  return null;
}

/// Rewrites references to a person this device named itself, once the server
/// has answered with an id of its own — which happens when the same name was
/// already on the account.
List<MoneyMutation> remapPersonId(
  List<MoneyMutation> queue,
  String from,
  String to,
) {
  if (from == to) return queue;
  return [
    for (final pending in queue)
      switch (pending) {
        CreateExpense(:final expenseId, :final write) =>
          CreateExpense(
            expenseId: expenseId,
            write: _remapWrite(write, from, to),
            createdAt: pending.createdAt,
            queuedAt: pending.queuedAt,
          ),
        UpdateExpense(:final expenseId, :final write, :final previous) =>
          UpdateExpense(
            expenseId: expenseId,
            write: _remapWrite(write, from, to),
            previous: previous,
            queuedAt: pending.queuedAt,
          ),
        CreateGroup(:final group) when group.memberIds.contains(from) =>
          CreateGroup(
            group: group.copyWith(
              memberIds: [
                for (final id in group.memberIds) id == from ? to : id,
              ],
            ),
            queuedAt: pending.queuedAt,
          ),
        UpdateGroup(:final memberIds) when memberIds?.contains(from) ?? false =>
          UpdateGroup(
            groupId: pending.groupId,
            name: pending.name,
            colorValue: pending.colorValue,
            emoji: pending.emoji,
            clearEmoji: pending.clearEmoji,
            memberIds: [for (final id in memberIds!) id == from ? to : id],
            archived: pending.archived,
            queuedAt: pending.queuedAt,
          ),
        UpdatePerson(:final personId) when personId == from => UpdatePerson(
          personId: to,
          name: pending.name,
          colorValue: pending.colorValue,
          emoji: pending.emoji,
          clearEmoji: pending.clearEmoji,
          defaultPercent: pending.defaultPercent,
          clearDefaultPercent: pending.clearDefaultPercent,
          order: pending.order,
          archived: pending.archived,
          queuedAt: pending.queuedAt,
        ),
        DeletePerson(:final personId) when personId == from =>
          DeletePerson(personId: to, queuedAt: pending.queuedAt),
        CreateSettlement(:final settlement) when settlement.personId == from =>
          CreateSettlement(
            settlement: Settlement(
              id: settlement.id,
              personId: to,
              amountCents: settlement.amountCents,
              direction: settlement.direction,
              dateKey: settlement.dateKey,
              notes: settlement.notes,
              createdAt: settlement.createdAt,
            ),
            queuedAt: pending.queuedAt,
          ),
        _ => pending,
      },
  ];
}

ExpenseWrite _remapWrite(ExpenseWrite write, String from, String to) {
  final touchesPayer = write.paidByPersonId == from;
  final touchesParticipant = write.participants.any(
    (participant) => participant.personId == from,
  );
  if (!touchesPayer && !touchesParticipant) return write;
  return write.copyWith(
    paidByPersonId: touchesPayer ? to : write.paidByPersonId,
    participants: [
      for (final participant in write.participants)
        participant.personId == from
            ? SplitParticipant(
                personId: to,
                percentBp: participant.percentBp,
                amountCents: participant.amountCents,
                gifted: participant.gifted,
              )
            : participant,
    ],
  );
}

/// Rewrites references to a group this device named itself.
List<MoneyMutation> remapGroupId(
  List<MoneyMutation> queue,
  String from,
  String to,
) {
  if (from == to) return queue;
  return [
    for (final pending in queue)
      switch (pending) {
        CreateExpense(:final expenseId, :final write)
            when write.groupId == from =>
          CreateExpense(
            expenseId: expenseId,
            write: write.copyWith(groupId: to),
            createdAt: pending.createdAt,
            queuedAt: pending.queuedAt,
          ),
        UpdateExpense(:final expenseId, :final write, :final previous)
            when write.groupId == from =>
          UpdateExpense(
            expenseId: expenseId,
            write: write.copyWith(groupId: to),
            previous: previous,
            queuedAt: pending.queuedAt,
          ),
        UpdateGroup(:final groupId) when groupId == from => UpdateGroup(
          groupId: to,
          name: pending.name,
          colorValue: pending.colorValue,
          emoji: pending.emoji,
          clearEmoji: pending.clearEmoji,
          memberIds: pending.memberIds,
          archived: pending.archived,
          queuedAt: pending.queuedAt,
        ),
        DeleteGroup(:final groupId) when groupId == from =>
          DeleteGroup(groupId: to, queuedAt: pending.queuedAt),
        _ => pending,
      },
  ];
}
