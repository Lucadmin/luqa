import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa_api/api.dart' as api;

/// The money tab over the wire.
///
/// Bills go up as the rules that produced them — the total, who was there, and
/// how it is divided — never as resolved shares. The server re-runs the split,
/// which is what keeps the stored cents identical to the ones the editor
/// previewed.
class RemoteMoneyRepository implements MoneyRepository {
  const RemoteMoneyRepository(this.client);

  final LuqaApi client;

  @override
  Future<MoneyOverview> loadOverview() async =>
      _overviewFromApi(await client.getMoneyOverview());

  @override
  Future<ExpensePage> loadExpenses({
    String? personId,
    String? groupId,
    String? cursor,
    int limit = 20,
  }) async {
    final response = await client.listExpenses(
      personId: personId,
      groupId: groupId,
      cursor: cursor,
      limit: limit,
    );
    return ExpensePage(
      expenses: response.expenses.map(expenseFromApi).toList(growable: false),
      nextCursor: response.nextCursor,
    );
  }

  @override
  Future<Expense> createExpense({
    String? id,
    required ExpenseWrite write,
  }) async => expenseFromApi(
    await client.createExpense(
      api.CreateExpenseRequest(
        id: _optional(id),
        description: api.Optional.present(write.description),
        amountCents: write.amountCents,
        date: api.Optional.present(write.dateKey),
        paidByPersonId: api.Optional.present(write.paidByPersonId),
        groupId: api.Optional.present(write.groupId),
        splitMode: api.Optional.present(_splitModeToApi(write.splitMode)),
        includeMe: api.Optional.present(write.includeMe),
        participants: api.Optional.present(_participantsToApi(write)),
        notes: api.Optional.present(write.notes),
      ),
    ),
  );

  @override
  Future<Expense> updateExpense(String id, ExpenseWrite write) async =>
      expenseFromApi(
        await client.updateExpense(
          id,
          api.UpdateExpenseRequest(
            description: api.Optional.present(write.description),
            amountCents: api.Optional.present(write.amountCents),
            date: api.Optional.present(write.dateKey),
            paidByPersonId: api.Optional.present(write.paidByPersonId),
            groupId: api.Optional.present(write.groupId),
            splitMode: api.Optional.present(_splitModeToApi(write.splitMode)),
            includeMe: api.Optional.present(write.includeMe),
            participants: api.Optional.present(_participantsToApi(write)),
            notes: api.Optional.present(write.notes),
          ),
        ),
      );

  @override
  Future<void> deleteExpense(String id) => client.deleteExpense(id);

  @override
  Future<PersonLedger> loadLedger(String personId) async =>
      _ledgerFromApi(await client.getPersonLedger(personId));

  @override
  Future<Person> createPerson({String? id, required PersonWrite write}) async =>
      personFromApi(
        await client.createPerson(
          api.CreatePersonRequest(
            id: _optional(id),
            name: write.name,
            color: api.Optional.present(_hexColor(write.colorValue)),
            emoji: api.Optional.present(write.emoji),
            defaultPercent: api.Optional.present(write.defaultPercent),
          ),
        ),
      );

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
  }) async => personFromApi(
    await client.updatePerson(
      id,
      api.UpdatePersonRequest(
        name: _optional(name),
        color: colorValue == null
            ? const api.Optional.absent()
            : api.Optional.present(_hexColor(colorValue)),
        // Clearing is a value the server has to see, so it cannot ride on the
        // same "absent" that means "leave it alone".
        emoji: clearEmoji
            ? const api.Optional.present(null)
            : _optional(emoji),
        defaultPercent: clearDefaultPercent
            ? const api.Optional.present(null)
            : _optional(defaultPercent),
        order: _optional(order),
        archived: _optional(archived),
      ),
    ),
  );

  @override
  Future<void> deletePerson(String id) => client.deletePerson(id);

  @override
  Future<PersonGroup> createGroup({
    String? id,
    required GroupWrite write,
  }) async => groupFromApi(
    await client.createGroup(
      api.CreateGroupRequest(
        id: _optional(id),
        name: write.name,
        color: api.Optional.present(_hexColor(write.colorValue)),
        emoji: api.Optional.present(write.emoji),
        memberIds: api.Optional.present(write.memberIds),
      ),
    ),
  );

  @override
  Future<PersonGroup> updateGroup({
    required String id,
    String? name,
    int? colorValue,
    String? emoji,
    bool clearEmoji = false,
    List<String>? memberIds,
    bool? archived,
  }) async => groupFromApi(
    await client.updateGroup(
      id,
      api.UpdateGroupRequest(
        name: _optional(name),
        color: colorValue == null
            ? const api.Optional.absent()
            : api.Optional.present(_hexColor(colorValue)),
        emoji: clearEmoji
            ? const api.Optional.present(null)
            : _optional(emoji),
        memberIds: _optional(memberIds),
        archived: _optional(archived),
      ),
    ),
  );

  @override
  Future<void> deleteGroup(String id) => client.deleteGroup(id);

  @override
  Future<Settlement> createSettlement({
    String? id,
    required SettlementWrite write,
  }) async => settlementFromApi(
    await client.createSettlement(
      api.CreateSettlementRequest(
        id: _optional(id),
        personId: write.personId,
        amountCents: write.amountCents,
        direction: api.Optional.present(
          write.direction == SettlementDirection.toMe
              ? api.SettlementDirection.TO_ME
              : api.SettlementDirection.FROM_ME,
        ),
        date: api.Optional.present(write.dateKey),
        notes: api.Optional.present(write.notes),
      ),
    ),
  );

  @override
  Future<void> deleteSettlement(String id) => client.deleteSettlement(id);
}

api.Optional<T> _optional<T>(T? value) => value == null
    ? api.Optional<T>.absent()
    : api.Optional<T>.present(value);

List<api.ExpenseParticipantInput> _participantsToApi(ExpenseWrite write) => [
  for (final participant in write.participants)
    api.ExpenseParticipantInput(
      personId: participant.personId,
      percentBp: api.Optional.present(participant.percentBp),
      amountCents: api.Optional.present(participant.amountCents),
      gifted: api.Optional.present(participant.gifted),
    ),
];

api.SplitMode _splitModeToApi(SplitMode mode) => switch (mode) {
  SplitMode.equal => api.SplitMode.EQUAL,
  SplitMode.percent => api.SplitMode.PERCENT,
  SplitMode.amount => api.SplitMode.AMOUNT,
};

MoneyOverview _overviewFromApi(api.MoneyOverview overview) => MoneyOverview(
  currency: overview.currency,
  people: [
    for (final balance in overview.people)
      PersonBalance(
        person: Person(
          id: balance.id,
          name: balance.name,
          colorValue: parseHexColor(balance.color),
          emoji: balance.emoji,
          defaultPercent: balance.defaultPercent,
          order: balance.order,
          archived: balance.archived,
        ),
        balanceCents: balance.balanceCents,
        coveredCents: balance.coveredCents,
        lastActivity: balance.lastActivity,
      ),
  ],
  groups: overview.groups.map(groupFromApi).toList(growable: false),
  owedToYouCents: overview.owedToYouCents,
  youOweCents: overview.youOweCents,
  coveredCents: overview.coveredCents,
);

Person personFromApi(api.Person person) => Person(
  id: person.id,
  name: person.name,
  colorValue: parseHexColor(person.color),
  emoji: person.emoji,
  defaultPercent: person.defaultPercent,
  order: person.order,
  archived: person.archived,
);

PersonGroup groupFromApi(api.PersonGroup group) => PersonGroup(
  id: group.id,
  name: group.name,
  colorValue: parseHexColor(group.color),
  emoji: group.emoji,
  order: group.order,
  archived: group.archived,
  memberIds: group.memberIds.toList(growable: false),
);

Expense expenseFromApi(api.Expense expense) => Expense(
  id: expense.id,
  description: expense.description,
  amountCents: expense.amountCents,
  dateKey: expense.date,
  paidByPersonId: expense.paidByPersonId,
  groupId: expense.groupId,
  splitMode: SplitMode.fromWire(expense.splitMode.toJson()),
  myShareCents: expense.myShareCents,
  notes: expense.notes,
  shares: [
    for (final share in expense.shares)
      ExpenseShare(
        personId: share.personId,
        amountCents: share.amountCents,
        percentBp: share.percentBp,
        gifted: share.gifted,
      ),
  ],
  createdAt: expense.createdAt.toLocal(),
);

Settlement settlementFromApi(api.Settlement settlement) => Settlement(
  id: settlement.id,
  personId: settlement.personId,
  amountCents: settlement.amountCents,
  direction: SettlementDirection.fromWire(settlement.direction.toJson()),
  dateKey: settlement.date,
  notes: settlement.notes,
  createdAt: settlement.createdAt.toLocal(),
);

PersonLedger _ledgerFromApi(api.PersonLedger ledger) => PersonLedger(
  person: personFromApi(ledger.person),
  currency: ledger.currency,
  balanceCents: ledger.balanceCents,
  coveredCents: ledger.coveredCents,
  coveredThisYearCents: ledger.coveredThisYearCents,
  items: [
    for (final item in ledger.items)
      LedgerItem(
        id: item.id,
        dateKey: item.date,
        title: item.title,
        deltaCents: item.deltaCents,
        shareCents: item.shareCents,
        gifted: item.gifted,
        amountCents: item.amountCents,
        paidByPersonId: item.paidByPersonId,
        direction: item.direction == null
            ? null
            : SettlementDirection.fromWire(item.direction!.toJson()),
        expense: item.expense == null ? null : expenseFromApi(item.expense!),
        createdAt: item.createdAt.toLocal(),
      ),
  ],
);

/// The palette is shared with the browser, which stores colors as hex.
String _hexColor(int value) =>
    '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

int parseHexColor(String value) {
  final digits = value.startsWith('#') ? value.substring(1) : value;
  final parsed = int.tryParse(digits, radix: 16);
  // A colour that will not parse is not worth failing a whole screen over.
  return parsed == null ? 0xFF6366F1 : 0xFF000000 | parsed;
}
