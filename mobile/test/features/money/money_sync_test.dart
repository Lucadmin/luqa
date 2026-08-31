import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/core/sync/sync_engine.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/money/application/money_controller.dart';
import 'package:luqa/features/money/application/money_sync_engine.dart';
import 'package:luqa/features/money/data/money_cache.dart';
import 'package:luqa/features/money/data/money_outbox.dart';
import 'package:luqa/features/money/data/money_providers.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/domain/money_split.dart';
import 'package:luqa_api/api.dart' as api;

import '../../helpers/fake_money_repository.dart';
import '../../helpers/pump_luqa.dart';

/// A durable queue that round-trips through json, because that is what a real
/// launch reads back.
class _MemoryOutbox implements Outbox<MoneyMutation> {
  List<MoneyMutation> stored = const [];

  @override
  Future<List<MoneyMutation>> read() async => [
    for (final pending in stored) MoneyMutation.fromJson(pending.toJson())!,
  ];

  @override
  Future<void> write(List<MoneyMutation> queue) async {
    stored = List.of(queue);
  }
}

/// A discard log that round-trips through json, because that is what a real
/// relaunch reads back.
class _MemoryDiscardLog implements DiscardLog {
  List<DiscardedWrite> stored = const [];

  @override
  Future<List<DiscardedWrite>> read() async => [
    for (final entry in stored) DiscardedWrite.fromJson(entry.toJson())!,
  ];

  @override
  Future<void> write(List<DiscardedWrite> entries) async {
    stored = List.of(entries);
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

/// Offline is modelled the way the generated client reports it: a synthetic
/// 400 carrying the real cause, which the engine must read as "try again"
/// rather than as a refusal.
class _Offline implements Exception {}

api.ApiException _transportFailure() => api.ApiException.withInner(
  400,
  'connection failed',
  _Offline(),
  StackTrace.current,
);

/// The whole money stack minus the widget tree: the real controller over the
/// real local-first repository over the real sync engine, with only the
/// network and the disk faked.
class _Stack {
  _Stack({
    bool offline = false,
    _MemoryOutbox? outbox,
    _MemoryCache? cache,
    _MemoryDiscardLog? discardLog,
  }) {
    remote = _FlakyMoneyRepository(FakeMoneyRepository.sample())
      ..offline = offline;
    this.outbox = outbox ?? _MemoryOutbox();
    this.cache = cache ?? _MemoryCache();
    this.discardLog = discardLog ?? _MemoryDiscardLog();
    container = ProviderContainer(
      overrides: [
        remoteMoneyRepositoryProvider.overrideWithValue(remote),
        moneyOutboxProvider.overrideWithValue(this.outbox),
        moneyDiscardLogProvider.overrideWithValue(this.discardLog),
        moneyCacheProvider.overrideWithValue(this.cache),
        moneyNowProvider.overrideWithValue(DateTime(2026, 8, 27, 12)),
        authControllerProvider.overrideWith(FixedAuthController.new),
      ],
    );
  }

  late final _FlakyMoneyRepository remote;
  late final _MemoryOutbox outbox;
  late final _MemoryCache cache;
  late final _MemoryDiscardLog discardLog;
  late final ProviderContainer container;

  MoneyController get money => container.read(moneyControllerProvider.notifier);

  MoneyState get state => container.read(moneyControllerProvider);

  MoneySyncEngine get engine =>
      container.read(moneySyncEngineProvider.notifier);

  SyncState get syncState => container.read(moneySyncEngineProvider);

  /// Builds the controller and lets its first load run. Providers are lazy, so
  /// without this the screen state is still untouched when a test looks at it.
  Future<void> warmUp() async {
    container.read(moneyControllerProvider);
    await settle();
  }

  Future<void> settle() async {
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  void dispose() => container.dispose();
}

class _FlakyMoneyRepository implements MoneyRepository {
  _FlakyMoneyRepository(this.inner);

  final FakeMoneyRepository inner;
  bool offline = false;

  /// Ids the server insists on renaming, standing in for a name that already
  /// existed on the account.
  final Map<String, String> renamePerson = {};

  /// A participant the server does not know, so any bill naming them is
  /// refused outright rather than failing in a way worth retrying.
  String? rejectExpensesFor;

  void _guard() {
    if (offline) throw _transportFailure();
  }

  @override
  Future<MoneyOverview> loadOverview() async {
    _guard();
    return inner.loadOverview();
  }

  @override
  Future<ExpensePage> loadExpenses({
    String? personId,
    String? groupId,
    String? cursor,
    int limit = 20,
  }) async {
    _guard();
    return inner.loadExpenses(
      personId: personId,
      groupId: groupId,
      cursor: cursor,
      limit: limit,
    );
  }

  @override
  Future<Expense> createExpense({String? id, required ExpenseWrite write}) async {
    _guard();
    if (write.participants.any((p) => p.personId == rejectExpensesFor)) {
      // Shaped exactly like the route's refusal, so the reason the user is
      // shown is the one the server actually gave.
      throw api.ApiException(
        400,
        '{"error":{"code":"invalid_input","message":"Unknown person"}}',
      );
    }
    return inner.createExpense(id: id, write: write);
  }

  @override
  Future<Expense> updateExpense(String id, ExpenseWrite write) async {
    _guard();
    return inner.updateExpense(id, write);
  }

  @override
  Future<void> deleteExpense(String id) async {
    _guard();
    return inner.deleteExpense(id);
  }

  @override
  Future<PersonLedger> loadLedger(String personId) async {
    _guard();
    return inner.loadLedger(personId);
  }

  @override
  Future<Person> createPerson({String? id, required PersonWrite write}) async {
    _guard();
    final renamed = renamePerson[id];
    final person = await inner.createPerson(id: renamed ?? id, write: write);
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
    return inner.updatePerson(
      id: id,
      name: name,
      colorValue: colorValue,
      emoji: emoji,
      clearEmoji: clearEmoji,
      defaultPercent: defaultPercent,
      clearDefaultPercent: clearDefaultPercent,
      order: order,
      archived: archived,
    );
  }

  @override
  Future<void> deletePerson(String id) async {
    _guard();
    return inner.deletePerson(id);
  }

  @override
  Future<PersonGroup> createGroup({String? id, required GroupWrite write}) async {
    _guard();
    return inner.createGroup(id: id, write: write);
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
    return inner.updateGroup(
      id: id,
      name: name,
      colorValue: colorValue,
      emoji: emoji,
      clearEmoji: clearEmoji,
      memberIds: memberIds,
      archived: archived,
    );
  }

  @override
  Future<void> deleteGroup(String id) async {
    _guard();
    return inner.deleteGroup(id);
  }

  @override
  Future<Settlement> createSettlement({
    String? id,
    required SettlementWrite write,
  }) async {
    _guard();
    return inner.createSettlement(id: id, write: write);
  }

  @override
  Future<void> deleteSettlement(String id) async {
    _guard();
    return inner.deleteSettlement(id);
  }
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
  test('a bill split with no signal reaches the server when it returns',
      () async {
    final stack = _Stack(offline: true);
    addTearDown(stack.dispose);
    await stack.settle();

    await stack.money.saveExpense(write: _dinner());
    await stack.settle();

    expect(stack.syncState.pending, 1);
    expect(stack.remote.inner.savedExpenses, isEmpty);

    stack.remote.offline = false;
    await stack.engine.sync();
    await stack.settle();

    expect(stack.syncState.pending, 0);
    expect(stack.remote.inner.savedExpenses.single.amountCents, 3000);
  });

  test('the queue survives being killed and is sent on the next launch',
      () async {
    final outbox = _MemoryOutbox();
    final first = _Stack(offline: true, outbox: outbox);
    await first.settle();
    await first.money.saveExpense(write: _dinner(amountCents: 4200));
    await first.settle();
    expect(outbox.stored, hasLength(1));
    first.dispose();

    final second = _Stack(outbox: outbox);
    addTearDown(second.dispose);
    await second.settle();
    await second.engine.sync();
    await second.settle();

    expect(second.remote.inner.savedExpenses.single.amountCents, 4200);
    expect(outbox.stored, isEmpty);
  });

  test('a bill follows a person to the id the server chose for them', () async {
    final stack = _Stack(offline: true);
    addTearDown(stack.dispose);
    await stack.settle();

    final person = await stack.money.addPerson(
      const PersonWrite(
        name: 'Ines',
        colorValue: 0xFF2563EB,
        emoji: null,
        defaultPercent: null,
      ),
    );
    expect(person, isNotNull);

    await stack.money.saveExpense(
      write: _dinner().copyWith(
        participants: [SplitParticipant(personId: person!.id)],
      ),
    );
    await stack.settle();
    expect(stack.syncState.pending, 2);

    // The server answers the create with an id of its own.
    stack.remote
      ..offline = false
      ..renamePerson[person.id] = 'server-ines';

    await stack.engine.sync();
    await stack.settle();

    expect(stack.syncState.pending, 0);
    expect(
      stack.remote.inner.savedExpenses.single.participants.single.personId,
      'server-ines',
    );
  });

  test('a refused write is dropped so the ones behind it can through', () async {
    final stack = _Stack();
    addTearDown(stack.dispose);
    await stack.warmUp();

    // Nobody by this id exists, so the server refuses the bill outright.
    stack.remote.rejectExpensesFor = 'ghost';
    await stack.money.saveExpense(
      write: _dinner().copyWith(
        participants: const [SplitParticipant(personId: 'ghost')],
      ),
    );
    await stack.money.saveExpense(write: _dinner(amountCents: 5500));
    await stack.settle();
    await stack.engine.sync();
    await stack.settle();

    // The doomed one is gone and the good one behind it landed, rather than
    // the queue jamming behind a request that can never succeed.
    expect(stack.syncState.pending, 0);
    expect(stack.remote.inner.savedExpenses.single.amountCents, 5500);
  });

  test('a write the server refused is reported, not silently lost', () async {
    final stack = _Stack();
    addTearDown(stack.dispose);
    await stack.warmUp();

    stack.remote.rejectExpensesFor = 'ghost';
    await stack.money.saveExpense(
      write: _dinner(amountCents: 4250).copyWith(
        participants: const [SplitParticipant(personId: 'ghost')],
      ),
    );
    await stack.settle();
    await stack.engine.sync();
    await stack.settle();

    // The queue emptying is exactly the moment the old code wiped this.
    expect(stack.syncState.pending, 0);
    expect(stack.syncState.discarded, hasLength(1));
    final lost = stack.syncState.discarded.single;
    // Named so the user knows what to enter again.
    expect(lost.description, contains('42.50'));
    expect(lost.description, contains('Dinner'));
    expect(lost.reason, contains('Unknown person'));
    // And the screen hears about it.
    expect(stack.state.discarded, hasLength(1));
  });

  test('the notice survives the relaunch after the drain that lost it',
      () async {
    final log = _MemoryDiscardLog();
    final first = _Stack(discardLog: log);
    await first.warmUp();
    first.remote.rejectExpensesFor = 'ghost';
    await first.money.saveExpense(
      write: _dinner().copyWith(
        participants: const [SplitParticipant(personId: 'ghost')],
      ),
    );
    await first.settle();
    await first.engine.sync();
    await first.settle();
    expect(log.stored, hasLength(1));
    // A queue very often drains on the resume before the phone goes back in a
    // pocket; the notice cannot live only in memory.
    first.dispose();

    final second = _Stack(discardLog: log);
    addTearDown(second.dispose);
    await second.warmUp();

    expect(second.syncState.discarded, hasLength(1));
    expect(second.state.discarded, hasLength(1));
  });

  test('acknowledging it is the only thing left to do, and it sticks',
      () async {
    final log = _MemoryDiscardLog();
    final stack = _Stack(discardLog: log);
    addTearDown(stack.dispose);
    await stack.warmUp();

    stack.remote.rejectExpensesFor = 'ghost';
    await stack.money.saveExpense(
      write: _dinner().copyWith(
        participants: const [SplitParticipant(personId: 'ghost')],
      ),
    );
    await stack.settle();
    await stack.engine.sync();
    await stack.settle();
    expect(stack.state.discarded, hasLength(1));

    await stack.money.acknowledgeDiscarded();
    await stack.settle();

    expect(stack.state.discarded, isEmpty);
    expect(log.stored, isEmpty);
  });

  test('a queue that merely stalls reports nothing lost', () async {
    final stack = _Stack(offline: true);
    addTearDown(stack.dispose);
    await stack.warmUp();

    await stack.money.saveExpense(write: _dinner());
    await stack.settle();

    // Offline is not loss: the write is still queued and still coming.
    expect(stack.syncState.pending, 1);
    expect(stack.syncState.discarded, isEmpty);
  });

  test('the balances on screen include work that has not been sent', () async {
    final stack = _Stack();
    addTearDown(stack.dispose);
    await stack.warmUp();
    expect(stack.state.overview!.owedToYouCents, 4800);

    stack.remote.offline = true;
    await stack.money.saveExpense(write: _dinner());
    await stack.settle();

    // 15.00 of the new bill is Mira's, on top of the 48.00 already out there.
    expect(stack.state.overview!.owedToYouCents, 6300);
    expect(stack.state.pendingWrites, 1);
  });

  test('once the queue drains, the server\'s copy replaces the overlay',
      () async {
    final stack = _Stack();
    addTearDown(stack.dispose);
    await stack.warmUp();

    await stack.money.saveExpense(write: _dinner());
    await stack.settle();
    await stack.engine.sync();
    await stack.settle();

    expect(stack.state.pendingWrites, 0);
    // The fake server does not recompute balances, so the overlay coming off
    // is exactly what returns the number to the server's own answer.
    expect(stack.state.overview!.owedToYouCents, 4800);
  });
}
