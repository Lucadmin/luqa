import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/domain/money_models.dart';

/// An in-memory money backend.
///
/// It answers the same shapes the server does, including the parts that matter
/// to the client's own rules: a person create returns the existing row when the
/// name is already taken, and a bill's shares are recomputed from the write
/// rather than echoed back.
class FakeMoneyRepository implements MoneyRepository {
  FakeMoneyRepository({
    required this.overview,
    List<Expense> expenses = const [],
    Map<String, PersonLedger> ledgers = const {},
  }) : expenses = [...expenses],
       ledgers = {...ledgers};

  factory FakeMoneyRepository.sample() {
    const mira = Person(
      id: 'mira',
      name: 'Mira',
      colorValue: 0xFF2563EB,
      emoji: null,
      defaultPercent: null,
      order: 0,
      archived: false,
    );
    const jonas = Person(
      id: 'jonas',
      name: 'Jonas',
      colorValue: 0xFF0F766E,
      emoji: null,
      defaultPercent: null,
      order: 1,
      archived: false,
    );
    const sara = Person(
      id: 'sara',
      name: 'Sara',
      colorValue: 0xFFBE185D,
      emoji: '🧡',
      defaultPercent: 0,
      order: 2,
      archived: false,
    );

    final dinner = Expense(
      id: 'dinner',
      description: 'Dinner',
      amountCents: 9000,
      dateKey: '2026-08-26',
      paidByPersonId: null,
      groupId: 'flat',
      splitMode: SplitMode.equal,
      myShareCents: 3000,
      notes: '',
      shares: const [
        ExpenseShare(
          personId: 'mira',
          amountCents: 3000,
          percentBp: 3333,
          gifted: false,
        ),
        ExpenseShare(
          personId: 'jonas',
          amountCents: 3000,
          percentBp: 3333,
          gifted: false,
        ),
      ],
      createdAt: DateTime(2026, 8, 26, 20),
    );
    final taxi = Expense(
      id: 'taxi',
      description: 'Taxi home',
      amountCents: 2400,
      dateKey: '2026-08-24',
      paidByPersonId: 'jonas',
      groupId: null,
      splitMode: SplitMode.equal,
      myShareCents: 1200,
      notes: '',
      shares: const [
        ExpenseShare(
          personId: 'jonas',
          amountCents: 1200,
          percentBp: 5000,
          gifted: false,
        ),
      ],
      createdAt: DateTime(2026, 8, 24, 23),
    );

    return FakeMoneyRepository(
      overview: const MoneyOverview(
        currency: 'EUR',
        people: [
          PersonBalance(
            person: mira,
            balanceCents: 3000,
            coveredCents: 0,
            lastActivity: '2026-08-26',
          ),
          PersonBalance(
            person: jonas,
            balanceCents: 1800,
            coveredCents: 0,
            lastActivity: '2026-08-26',
          ),
          PersonBalance(
            person: sara,
            balanceCents: 0,
            coveredCents: 1500,
            lastActivity: '2026-08-20',
          ),
        ],
        groups: [
          PersonGroup(
            id: 'flat',
            name: 'The flat',
            colorValue: 0xFF15803D,
            emoji: '🏠',
            order: 0,
            archived: false,
            memberIds: ['mira', 'jonas'],
          ),
        ],
        owedToYouCents: 4800,
        youOweCents: 0,
        coveredCents: 1500,
      ),
      expenses: [dinner, taxi],
      ledgers: {
        'sara': const PersonLedger(
          person: sara,
          currency: 'EUR',
          balanceCents: 0,
          coveredCents: 1500,
          coveredThisYearCents: 1500,
          items: [],
        ),
        'jonas': PersonLedger(
          person: jonas,
          currency: 'EUR',
          balanceCents: 1800,
          coveredCents: 0,
          coveredThisYearCents: 0,
          items: [
            LedgerItem(
              id: 'dinner',
              dateKey: '2026-08-26',
              title: 'Dinner',
              deltaCents: 3000,
              shareCents: 3000,
              gifted: false,
              amountCents: 9000,
              paidByPersonId: null,
              direction: null,
              expense: dinner,
              createdAt: DateTime(2026, 8, 26, 20),
            ),
            LedgerItem(
              id: 'taxi',
              dateKey: '2026-08-24',
              title: 'Taxi home',
              deltaCents: -1200,
              shareCents: 1200,
              gifted: false,
              amountCents: 2400,
              paidByPersonId: 'jonas',
              direction: null,
              expense: taxi,
              createdAt: DateTime(2026, 8, 24, 23),
            ),
          ],
        ),
        'mira': PersonLedger(
          person: mira,
          currency: 'EUR',
          balanceCents: 3000,
          coveredCents: 0,
          coveredThisYearCents: 0,
          items: [
            LedgerItem(
              id: 'dinner',
              dateKey: '2026-08-26',
              title: 'Dinner',
              deltaCents: 3000,
              shareCents: 3000,
              gifted: false,
              amountCents: 9000,
              paidByPersonId: null,
              direction: null,
              expense: dinner,
              createdAt: DateTime(2026, 8, 26, 20),
            ),
          ],
        ),
      },
    );
  }

  MoneyOverview overview;
  final List<Expense> expenses;
  final Map<String, PersonLedger> ledgers;

  final List<ExpenseWrite> savedExpenses = [];
  final List<SettlementWrite> savedSettlements = [];
  final List<PersonWrite> savedPeople = [];
  final List<GroupWrite> savedGroups = [];
  final List<String> deletedExpenses = [];

  /// Set to make every call fail, which is what "no signal" looks like here.
  Object? failure;

  int _minted = 0;

  String _mintId() => 'server-${++_minted}';

  void _guard() {
    final error = failure;
    if (error != null) throw error;
  }

  @override
  Future<MoneyOverview> loadOverview() async {
    _guard();
    return overview;
  }

  @override
  Future<ExpensePage> loadExpenses({
    String? personId,
    String? groupId,
    String? cursor,
    int limit = 20,
  }) async {
    _guard();
    return ExpensePage(
      expenses: [
        for (final expense in expenses)
          if (groupId == null || expense.groupId == groupId)
            if (personId == null ||
                expense.paidByPersonId == personId ||
                expense.shares.any((share) => share.personId == personId))
              expense,
      ],
      nextCursor: null,
    );
  }

  @override
  Future<Expense> createExpense({
    String? id,
    required ExpenseWrite write,
  }) async {
    _guard();
    savedExpenses.add(write);
    final expense = write.resolve(
      id: id ?? _mintId(),
      createdAt: DateTime(2026, 8, 27, 12),
    );
    expenses.insert(0, expense);
    return expense;
  }

  @override
  Future<Expense> updateExpense(String id, ExpenseWrite write) async {
    _guard();
    savedExpenses.add(write);
    final existing = expenses.indexWhere((expense) => expense.id == id);
    final expense = write.resolve(
      id: id,
      createdAt: existing == -1
          ? DateTime(2026, 8, 27, 12)
          : expenses[existing].createdAt,
    );
    if (existing == -1) {
      expenses.insert(0, expense);
    } else {
      expenses[existing] = expense;
    }
    return expense;
  }

  @override
  Future<void> deleteExpense(String id) async {
    _guard();
    deletedExpenses.add(id);
    expenses.removeWhere((expense) => expense.id == id);
  }

  @override
  Future<PersonLedger> loadLedger(String personId) async {
    _guard();
    final ledger = ledgers[personId];
    if (ledger == null) throw StateError('No ledger for $personId');
    return ledger;
  }

  @override
  Future<Person> createPerson({String? id, required PersonWrite write}) async {
    _guard();
    savedPeople.add(write);
    for (final balance in overview.people) {
      if (balance.person.name == write.name) return balance.person;
    }
    final person = Person(
      id: id ?? _mintId(),
      name: write.name,
      colorValue: write.colorValue,
      emoji: write.emoji,
      defaultPercent: write.defaultPercent,
      order: overview.people.length,
      archived: false,
    );
    overview = overview.copyWith(
      people: [
        ...overview.people,
        PersonBalance(
          person: person,
          balanceCents: 0,
          coveredCents: 0,
          lastActivity: null,
        ),
      ],
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
    _guard();
    late Person updated;
    overview = overview.copyWith(
      people: [
        for (final balance in overview.people)
          if (balance.id != id)
            balance
          else
            balance.copyWith(
              person: updated = balance.person.copyWith(
                name: name,
                colorValue: colorValue,
                emoji: emoji,
                clearEmoji: clearEmoji,
                defaultPercent: defaultPercent,
                clearDefaultPercent: clearDefaultPercent,
                order: order,
                archived: archived,
              ),
            ),
      ],
    );
    return updated;
  }

  @override
  Future<void> deletePerson(String id) async {
    _guard();
    overview = overview.copyWith(
      people: [
        for (final balance in overview.people)
          if (balance.id != id) balance,
      ],
    );
  }

  @override
  Future<PersonGroup> createGroup({
    String? id,
    required GroupWrite write,
  }) async {
    _guard();
    savedGroups.add(write);
    for (final group in overview.groups) {
      if (group.name == write.name) return group;
    }
    final group = PersonGroup(
      id: id ?? _mintId(),
      name: write.name,
      colorValue: write.colorValue,
      emoji: write.emoji,
      order: overview.groups.length,
      archived: false,
      memberIds: write.memberIds,
    );
    overview = overview.copyWith(groups: [...overview.groups, group]);
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
    _guard();
    late PersonGroup updated;
    overview = overview.copyWith(
      groups: [
        for (final group in overview.groups)
          if (group.id != id)
            group
          else
            updated = group.copyWith(
              name: name,
              colorValue: colorValue,
              emoji: emoji,
              clearEmoji: clearEmoji,
              memberIds: memberIds,
              archived: archived,
            ),
      ],
    );
    return updated;
  }

  @override
  Future<void> deleteGroup(String id) async {
    _guard();
    overview = overview.copyWith(
      groups: [
        for (final group in overview.groups)
          if (group.id != id) group,
      ],
    );
  }

  @override
  Future<Settlement> createSettlement({
    String? id,
    required SettlementWrite write,
  }) async {
    _guard();
    savedSettlements.add(write);
    return Settlement(
      id: id ?? _mintId(),
      personId: write.personId,
      amountCents: write.amountCents,
      direction: write.direction,
      dateKey: write.dateKey,
      notes: write.notes,
      createdAt: DateTime(2026, 8, 27, 12),
    );
  }

  @override
  Future<void> deleteSettlement(String id) async {
    _guard();
  }
}
