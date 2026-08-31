import 'package:luqa/core/storage/luqa_store.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:sqflite/sqflite.dart';

/// The money feature's data, on the phone.
///
/// Not a cache of the server's answers — the rows themselves. That is the
/// whole point: a balance is a sum over what is in these tables, so it is
/// right the moment a bill is entered and still right after the bill syncs,
/// with nothing to replay over it and nothing to reverse out of it.
///
/// Two flags carry the sync state:
///
/// * `pending` — changed here, not yet acknowledged. A delta will not
///   overwrite it, because the local copy is the newer one.
/// * `removed` — deleted here, not yet tombstoned there. Hidden from every
///   read, and dropped for real once the delta confirms it.
class MoneyLocalStore {
  MoneyLocalStore({required this.namespace, LuqaStore? store})
    : _store = store ?? LuqaStore.shared;

  final String namespace;
  final LuqaStore _store;

  Future<Database> get _db => _store.database;

  // ---------------------------------------------------------------- reading

  /// Everything the money screen shows, computed here.
  ///
  /// Read whole and folded in memory rather than aggregated in SQL, for the
  /// same reason the server does it that way: a balance has to consider all of
  /// history to be correct, and one person's history is small.
  Future<MoneyOverview> overview(String currency) async {
    final db = await _db;
    final people = await _people(db);
    final groups = await _groups(db);
    final totals = await _totals(db);

    final balances = [
      for (final person in people)
        PersonBalance(
          person: person,
          balanceCents: totals[person.id]?.balanceCents ?? 0,
          coveredCents: totals[person.id]?.coveredCents ?? 0,
          lastActivity: totals[person.id]?.lastActivity,
        ),
    ];

    // Whoever owes the most sits at the top; settled people sink to the
    // bottom. Archived people stay in the list — they may carry a balance, and
    // their names have to resolve on the bills they appear on.
    balances.sort((a, b) {
      final byBalance = b.balanceCents.abs().compareTo(a.balanceCents.abs());
      if (byBalance != 0) return byBalance;
      final byOrder = a.person.order.compareTo(b.person.order);
      return byOrder != 0 ? byOrder : a.person.name.compareTo(b.person.name);
    });

    var owed = 0;
    var owe = 0;
    var covered = 0;
    for (final balance in balances) {
      if (balance.balanceCents > 0) owed += balance.balanceCents;
      if (balance.balanceCents < 0) owe += -balance.balanceCents;
      covered += balance.coveredCents;
    }

    return MoneyOverview(
      currency: currency,
      people: balances,
      groups: groups,
      owedToYouCents: owed,
      youOweCents: owe,
      coveredCents: covered,
    );
  }

  /// One page of the bill feed, newest first.
  ///
  /// Paged by the row itself rather than an offset: bills are entered while
  /// the feed is open, and an offset would repeat or skip one when they are.
  Future<ExpensePage> expenses({
    String? personId,
    String? groupId,
    String? cursor,
    int limit = 20,
  }) async {
    final db = await _db;
    final where = <String>['e.namespace = ?', 'e.removed = 0'];
    final args = <Object?>[namespace];

    if (groupId != null) {
      where.add('e.group_id = ?');
      args.add(groupId);
    }
    if (personId != null) {
      // On the bill, or the one who fronted it.
      where.add(
        '(e.paid_by = ? OR EXISTS (SELECT 1 FROM money_expense_share s '
        'WHERE s.namespace = e.namespace AND s.expense_id = e.id '
        'AND s.person_id = ?))',
      );
      args..add(personId)..add(personId);
    }

    final after = _decodeCursor(cursor);
    if (after != null) {
      where.add(
        '(e.date_key < ? OR (e.date_key = ? AND (e.created_at < ? OR '
        '(e.created_at = ? AND e.id < ?))))',
      );
      args
        ..add(after.dateKey)
        ..add(after.dateKey)
        ..add(after.createdAt)
        ..add(after.createdAt)
        ..add(after.id);
    }

    final rows = await db.rawQuery(
      'SELECT e.* FROM money_expense e WHERE ${where.join(' AND ')} '
      'ORDER BY e.date_key DESC, e.created_at DESC, e.id DESC LIMIT ?',
      [...args, limit + 1],
    );

    final hasMore = rows.length > limit;
    final page = hasMore ? rows.sublist(0, limit) : rows;
    final shares = await _sharesFor(db, [
      for (final row in page) row['id']! as String,
    ]);

    final expenses = [
      for (final row in page)
        _expenseFromRow(row, shares[row['id']] ?? const []),
    ];
    final last = page.isEmpty ? null : page.last;

    return ExpensePage(
      expenses: expenses,
      nextCursor: hasMore && last != null
          ? _encodeCursor(
              last['date_key']! as String,
              last['created_at']! as String,
              last['id']! as String,
            )
          : null,
    );
  }

  Future<Expense?> expenseById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'money_expense',
      where: 'namespace = ? AND id = ? AND removed = 0',
      whereArgs: [namespace, id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final shares = await _sharesFor(db, [id]);
    return _expenseFromRow(rows.first, shares[id] ?? const []);
  }

  Future<Settlement?> settlementById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'money_settlement',
      where: 'namespace = ? AND id = ? AND removed = 0',
      whereArgs: [namespace, id],
      limit: 1,
    );
    return rows.isEmpty ? null : _settlementFromRow(rows.first);
  }

  /// One person's whole history with the user, newest first.
  Future<PersonLedger?> ledger(String personId, String currency) async {
    final db = await _db;
    final people = await _people(db);
    Person? person;
    for (final candidate in people) {
      if (candidate.id == personId) person = candidate;
    }
    if (person == null) return null;

    final totals = await _totals(db);
    final mine = totals[personId];

    final items = <LedgerItem>[];

    final expenseRows = await db.rawQuery(
      'SELECT e.* FROM money_expense e WHERE e.namespace = ? AND e.removed = 0 '
      'AND (e.paid_by = ? OR EXISTS (SELECT 1 FROM money_expense_share s '
      'WHERE s.namespace = e.namespace AND s.expense_id = e.id '
      'AND s.person_id = ?))',
      [namespace, personId, personId],
    );
    final shares = await _sharesFor(db, [
      for (final row in expenseRows) row['id']! as String,
    ]);

    for (final row in expenseRows) {
      final expense = _expenseFromRow(
        row,
        shares[row['id']] ?? const [],
      );
      ExpenseShare? theirs;
      for (final share in expense.shares) {
        if (share.personId == personId) theirs = share;
      }

      // The same rule the balance uses: when they paid, only the user's own
      // slice is between the two of them.
      final delta = expense.paidByPersonId == personId
          ? -expense.myShareCents
          : (theirs?.gifted ?? false)
          ? 0
          : theirs?.amountCents ?? 0;

      items.add(
        LedgerItem(
          id: expense.id,
          dateKey: expense.dateKey,
          title: expense.title,
          deltaCents: delta,
          shareCents: expense.paidByPersonId == personId
              ? expense.myShareCents
              : theirs?.amountCents ?? 0,
          gifted: theirs?.gifted ?? false,
          amountCents: expense.amountCents,
          paidByPersonId: expense.paidByPersonId,
          direction: null,
          expense: expense,
          createdAt: expense.createdAt,
        ),
      );
    }

    final settlementRows = await db.query(
      'money_settlement',
      where: 'namespace = ? AND person_id = ? AND removed = 0',
      whereArgs: [namespace, personId],
    );
    for (final row in settlementRows) {
      final settlement = _settlementFromRow(row);
      items.add(
        LedgerItem(
          id: settlement.id,
          dateKey: settlement.dateKey,
          title: settlement.direction == SettlementDirection.toMe
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
        ),
      );
    }

    items.sort((a, b) {
      final byDate = b.dateKey.compareTo(a.dateKey);
      if (byDate != 0) return byDate;
      return b.createdAt.compareTo(a.createdAt);
    });

    return PersonLedger(
      person: person,
      currency: currency,
      balanceCents: mine?.balanceCents ?? 0,
      coveredCents: mine?.coveredCents ?? 0,
      coveredThisYearCents: mine?.coveredThisYearCents ?? 0,
      items: items,
    );
  }

  Future<List<Person>> people() async => _people(await _db);

  Future<List<PersonGroup>> groups() async => _groups(await _db);

  // ------------------------------------------------------- local mutations

  /// Writes a row this device just changed. [txn] lets the caller put the row
  /// and the outbox entry in one transaction.
  Future<void> putPerson(
    Person person, {
    bool pending = true,
    DatabaseExecutor? txn,
  }) async {
    final db = txn ?? await _db;
    await db.insert('money_person', {
      'namespace': namespace,
      'id': person.id,
      'name': person.name,
      'color': person.colorValue,
      'emoji': person.emoji,
      'default_percent': person.defaultPercent,
      'ord': person.order,
      'archived': person.archived ? 1 : 0,
      'pending': pending ? 1 : 0,
      'removed': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> putGroup(
    PersonGroup group, {
    bool pending = true,
    DatabaseExecutor? txn,
  }) async {
    final db = txn ?? await _db;
    await db.insert('money_group', {
      'namespace': namespace,
      'id': group.id,
      'name': group.name,
      'color': group.colorValue,
      'emoji': group.emoji,
      'ord': group.order,
      'archived': group.archived ? 1 : 0,
      'pending': pending ? 1 : 0,
      'removed': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.delete(
      'money_group_member',
      where: 'namespace = ? AND group_id = ?',
      whereArgs: [namespace, group.id],
    );
    for (final personId in group.memberIds) {
      await db.insert('money_group_member', {
        'namespace': namespace,
        'group_id': group.id,
        'person_id': personId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> putExpense(
    Expense expense, {
    bool pending = true,
    DatabaseExecutor? txn,
  }) async {
    final db = txn ?? await _db;
    await db.insert('money_expense', {
      'namespace': namespace,
      'id': expense.id,
      'description': expense.description,
      'amount_cents': expense.amountCents,
      'date_key': expense.dateKey,
      'paid_by': expense.paidByPersonId,
      'group_id': expense.groupId,
      'split_mode': expense.splitMode.wireName,
      'my_share_cents': expense.myShareCents,
      'notes': expense.notes,
      'created_at': expense.createdAt.toUtc().toIso8601String(),
      'pending': pending ? 1 : 0,
      'removed': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    // Shares are replaced wholesale: a re-split changes every one of them, and
    // there is no such thing as a share that outlives its bill.
    await db.delete(
      'money_expense_share',
      where: 'namespace = ? AND expense_id = ?',
      whereArgs: [namespace, expense.id],
    );
    for (final share in expense.shares) {
      await db.insert('money_expense_share', {
        'namespace': namespace,
        'expense_id': expense.id,
        'person_id': share.personId,
        'amount_cents': share.amountCents,
        'percent_bp': share.percentBp,
        'gifted': share.gifted ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> putSettlement(
    Settlement settlement, {
    bool pending = true,
    DatabaseExecutor? txn,
  }) async {
    final db = txn ?? await _db;
    await db.insert('money_settlement', {
      'namespace': namespace,
      'id': settlement.id,
      'person_id': settlement.personId,
      'amount_cents': settlement.amountCents,
      'direction': settlement.direction.wireName,
      'date_key': settlement.dateKey,
      'notes': settlement.notes,
      'created_at': settlement.createdAt.toUtc().toIso8601String(),
      'pending': pending ? 1 : 0,
      'removed': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Hides a row the user deleted. It stays until the server confirms, so a
  /// delta that has not caught up cannot bring it back.
  Future<void> remove(
    String table,
    String id, {
    DatabaseExecutor? txn,
  }) async {
    final db = txn ?? await _db;
    await db.update(
      table,
      {'removed': 1, 'pending': 1},
      where: 'namespace = ? AND id = ?',
      whereArgs: [namespace, id],
    );
  }

  /// Forgets a row outright, for one created and deleted before it ever
  /// reached the server — there is nothing for a delta to confirm.
  Future<void> forget(
    String table,
    String id, {
    DatabaseExecutor? txn,
  }) async {
    final db = txn ?? await _db;
    await db.delete(
      table,
      where: 'namespace = ? AND id = ?',
      whereArgs: [namespace, id],
    );
    if (table == 'money_expense') {
      await db.delete(
        'money_expense_share',
        where: 'namespace = ? AND expense_id = ?',
        whereArgs: [namespace, id],
      );
    }
  }

  /// The row has landed. Clearing the flag lets the next delta own it again.
  Future<void> settle(String table, String id) async {
    final db = await _db;
    await db.update(
      table,
      {'pending': 0},
      where: 'namespace = ? AND id = ?',
      whereArgs: [namespace, id],
    );
  }

  /// Renames a row the server gave a different id to — a person it matched by
  /// name, say. Everything pointing at the old id follows it.
  Future<void> remapId(String table, String from, String to) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(
        table,
        {'id': to},
        where: 'namespace = ? AND id = ?',
        whereArgs: [namespace, from],
      );
      if (table == 'money_person') {
        for (final ref in const [
          ('money_expense_share', 'person_id'),
          ('money_settlement', 'person_id'),
          ('money_group_member', 'person_id'),
        ]) {
          await txn.update(
            ref.$1,
            {ref.$2: to},
            where: 'namespace = ? AND ${ref.$2} = ?',
            whereArgs: [namespace, from],
          );
        }
        await txn.update(
          'money_expense',
          {'paid_by': to},
          where: 'namespace = ? AND paid_by = ?',
          whereArgs: [namespace, from],
        );
      }
      if (table == 'money_group') {
        await txn.update(
          'money_group_member',
          {'group_id': to},
          where: 'namespace = ? AND group_id = ?',
          whereArgs: [namespace, from],
        );
        await txn.update(
          'money_expense',
          {'group_id': to},
          where: 'namespace = ? AND group_id = ?',
          whereArgs: [namespace, from],
        );
      }
      if (table == 'money_expense') {
        await txn.update(
          'money_expense_share',
          {'expense_id': to},
          where: 'namespace = ? AND expense_id = ?',
          whereArgs: [namespace, from],
        );
      }
    });
  }

  // ------------------------------------------------------------ delta sync

  /// True when this device has changed the row and is still waiting on the
  /// server. A delta must leave it alone; the local copy is newer.
  Future<Set<String>> _pendingIds(DatabaseExecutor db, String table) async {
    final rows = await db.query(
      table,
      columns: ['id'],
      where: 'namespace = ? AND pending = 1',
      whereArgs: [namespace],
    );
    return {for (final row in rows) row['id']! as String};
  }

  Future<void> applyPeople(List<Person> rows, List<String> deleted) async {
    final db = await _db;
    await db.transaction((txn) async {
      final pending = await _pendingIds(txn, 'money_person');
      for (final person in rows) {
        if (pending.contains(person.id)) continue;
        await putPerson(person, pending: false, txn: txn);
      }
      await _applyDeletions(txn, 'money_person', deleted, pending);
    });
  }

  Future<void> applyGroups(List<PersonGroup> rows, List<String> deleted) async {
    final db = await _db;
    await db.transaction((txn) async {
      final pending = await _pendingIds(txn, 'money_group');
      for (final group in rows) {
        if (pending.contains(group.id)) continue;
        await putGroup(group, pending: false, txn: txn);
      }
      await _applyDeletions(txn, 'money_group', deleted, pending);
    });
  }

  Future<void> applyExpenses(List<Expense> rows, List<String> deleted) async {
    final db = await _db;
    await db.transaction((txn) async {
      final pending = await _pendingIds(txn, 'money_expense');
      for (final expense in rows) {
        if (pending.contains(expense.id)) continue;
        await putExpense(expense, pending: false, txn: txn);
      }
      await _applyDeletions(txn, 'money_expense', deleted, pending);
    });
  }

  Future<void> applySettlements(
    List<Settlement> rows,
    List<String> deleted,
  ) async {
    final db = await _db;
    await db.transaction((txn) async {
      final pending = await _pendingIds(txn, 'money_settlement');
      for (final settlement in rows) {
        if (pending.contains(settlement.id)) continue;
        await putSettlement(settlement, pending: false, txn: txn);
      }
      await _applyDeletions(txn, 'money_settlement', deleted, pending);
    });
  }

  /// A row the server says is gone is gone here too — unless this device has
  /// since changed it, in which case the change is still on its way and gets
  /// to argue its case first.
  Future<void> _applyDeletions(
    DatabaseExecutor txn,
    String table,
    List<String> deleted,
    Set<String> pending,
  ) async {
    for (final id in deleted) {
      if (pending.contains(id)) continue;
      await txn.delete(
        table,
        where: 'namespace = ? AND id = ?',
        whereArgs: [namespace, id],
      );
      if (table == 'money_expense') {
        await txn.delete(
          'money_expense_share',
          where: 'namespace = ? AND expense_id = ?',
          whereArgs: [namespace, id],
        );
      }
      if (table == 'money_group') {
        await txn.delete(
          'money_group_member',
          where: 'namespace = ? AND group_id = ?',
          whereArgs: [namespace, id],
        );
      }
    }
  }

  Future<String?> cursor(String collection) async {
    final db = await _db;
    final rows = await db.query(
      'sync_cursor',
      columns: ['cursor'],
      where: 'namespace = ? AND collection = ?',
      whereArgs: [namespace, collection],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['cursor'] as String;
  }

  Future<void> setCursor(String collection, String cursor) async {
    final db = await _db;
    await db.insert('sync_cursor', {
      'namespace': namespace,
      'collection': collection,
      'cursor': cursor,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// The account's currency, as the last sync reported it.
  ///
  /// Kept here because the money screen is rendered entirely from this device
  /// now, and it cannot format an amount without knowing what the amount is
  /// in. Defaults to euros until a sync says otherwise.
  Future<String> get currency async =>
      await _store.readDocument(
        namespace: namespace,
        collection: 'money',
        key: 'currency',
      ) ??
      'EUR';

  Future<void> setCurrency(String value) => _store.writeDocument(
    namespace: namespace,
    collection: 'money',
    key: 'currency',
    value: value,
  );

  /// True when this device has never completed a sync, so a screen knows the
  /// difference between "nothing yet" and "nothing at all".
  Future<bool> get isEmpty async {
    final db = await _db;
    final rows = await db.query(
      'sync_cursor',
      columns: ['collection'],
      where: 'namespace = ?',
      whereArgs: [namespace],
      limit: 1,
    );
    return rows.isEmpty;
  }

  // ------------------------------------------------------------- internals

  Future<List<Person>> _people(DatabaseExecutor db) async {
    final rows = await db.query(
      'money_person',
      where: 'namespace = ? AND removed = 0',
      whereArgs: [namespace],
      orderBy: 'ord ASC, name ASC',
    );
    return [
      for (final row in rows)
        Person(
          id: row['id']! as String,
          name: row['name']! as String,
          colorValue: row['color']! as int,
          emoji: row['emoji'] as String?,
          defaultPercent: row['default_percent'] as int?,
          order: row['ord']! as int,
          archived: (row['archived']! as int) == 1,
        ),
    ];
  }

  Future<List<PersonGroup>> _groups(DatabaseExecutor db) async {
    final rows = await db.query(
      'money_group',
      where: 'namespace = ? AND removed = 0 AND archived = 0',
      whereArgs: [namespace],
      orderBy: 'ord ASC, name ASC',
    );
    final members = await db.query(
      'money_group_member',
      where: 'namespace = ?',
      whereArgs: [namespace],
    );
    final byGroup = <String, List<String>>{};
    for (final member in members) {
      byGroup
          .putIfAbsent(member['group_id']! as String, () => [])
          .add(member['person_id']! as String);
    }
    return [
      for (final row in rows)
        PersonGroup(
          id: row['id']! as String,
          name: row['name']! as String,
          colorValue: row['color']! as int,
          emoji: row['emoji'] as String?,
          order: row['ord']! as int,
          archived: (row['archived']! as int) == 1,
          memberIds: byGroup[row['id']] ?? const [],
        ),
    ];
  }

  Future<Map<String, List<ExpenseShare>>> _sharesFor(
    DatabaseExecutor db,
    List<String> expenseIds,
  ) async {
    if (expenseIds.isEmpty) return const {};
    final placeholders = List.filled(expenseIds.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT * FROM money_expense_share WHERE namespace = ? '
      'AND expense_id IN ($placeholders)',
      [namespace, ...expenseIds],
    );
    final byExpense = <String, List<ExpenseShare>>{};
    for (final row in rows) {
      byExpense.putIfAbsent(row['expense_id']! as String, () => []).add(
        ExpenseShare(
          personId: row['person_id']! as String,
          amountCents: row['amount_cents']! as int,
          percentBp: row['percent_bp'] as int?,
          gifted: (row['gifted']! as int) == 1,
        ),
      );
    }
    return byExpense;
  }

  /// Every bill and payback folded into per-person totals.
  ///
  /// The rules, all from the user's point of view, and the same ones the
  /// server applies:
  ///   · the user paid → each other participant's share is owed to the user
  ///   · someone else paid → only the user's own share matters; what the
  ///     others owe in that case is between them and whoever paid
  ///   · a gifted share moves no balance, it only adds to "covered"
  ///   · a payback moves the balance back toward zero
  Future<Map<String, _Totals>> _totals(DatabaseExecutor db) async {
    final totals = <String, _Totals>{};
    _Totals forPerson(String id) => totals.putIfAbsent(id, _Totals.new);

    final expenses = await db.query(
      'money_expense',
      columns: ['id', 'date_key', 'paid_by', 'my_share_cents'],
      where: 'namespace = ? AND removed = 0',
      whereArgs: [namespace],
    );
    final shares = await _sharesFor(db, [
      for (final row in expenses) row['id']! as String,
    ]);

    final thisYear = '${DateTime.now().toUtc().year}';

    for (final row in expenses) {
      final dateKey = row['date_key']! as String;
      final paidBy = row['paid_by'] as String?;
      if (paidBy == null) {
        for (final share in shares[row['id']] ?? const <ExpenseShare>[]) {
          final totalsFor = forPerson(share.personId);
          if (share.gifted) {
            totalsFor.coveredCents += share.amountCents;
            if (dateKey.startsWith(thisYear)) {
              totalsFor.coveredThisYearCents += share.amountCents;
            }
          } else {
            totalsFor.balanceCents += share.amountCents;
          }
          totalsFor.touch(dateKey);
        }
      } else {
        final totalsFor = forPerson(paidBy);
        totalsFor.balanceCents -= row['my_share_cents']! as int;
        totalsFor.touch(dateKey);
      }
    }

    final settlements = await db.query(
      'money_settlement',
      columns: ['person_id', 'amount_cents', 'direction', 'date_key'],
      where: 'namespace = ? AND removed = 0',
      whereArgs: [namespace],
    );
    for (final row in settlements) {
      final totalsFor = forPerson(row['person_id']! as String);
      final amount = row['amount_cents']! as int;
      totalsFor.balanceCents += row['direction'] == 'TO_ME' ? -amount : amount;
      totalsFor.touch(row['date_key']! as String);
    }

    return totals;
  }

  Expense _expenseFromRow(
    Map<String, Object?> row,
    List<ExpenseShare> shares,
  ) => Expense(
    id: row['id']! as String,
    description: row['description']! as String,
    amountCents: row['amount_cents']! as int,
    dateKey: row['date_key']! as String,
    paidByPersonId: row['paid_by'] as String?,
    groupId: row['group_id'] as String?,
    splitMode: SplitMode.fromWire(row['split_mode'] as String?),
    myShareCents: row['my_share_cents']! as int,
    notes: row['notes']! as String,
    shares: shares,
    createdAt: DateTime.parse(row['created_at']! as String).toLocal(),
  );

  Settlement _settlementFromRow(Map<String, Object?> row) => Settlement(
    id: row['id']! as String,
    personId: row['person_id']! as String,
    amountCents: row['amount_cents']! as int,
    direction: SettlementDirection.fromWire(row['direction'] as String?),
    dateKey: row['date_key']! as String,
    notes: row['notes']! as String,
    createdAt: DateTime.parse(row['created_at']! as String).toLocal(),
  );

  static String _encodeCursor(String dateKey, String createdAt, String id) =>
      '$dateKey|$createdAt|$id';

  static ({String dateKey, String createdAt, String id})? _decodeCursor(
    String? value,
  ) {
    if (value == null) return null;
    final parts = value.split('|');
    if (parts.length != 3) return null;
    return (dateKey: parts[0], createdAt: parts[1], id: parts[2]);
  }
}

class _Totals {
  int balanceCents = 0;
  int coveredCents = 0;
  int coveredThisYearCents = 0;
  String? lastActivity;

  void touch(String dateKey) {
    if (lastActivity == null || dateKey.compareTo(lastActivity!) > 0) {
      lastActivity = dateKey;
    }
  }
}
