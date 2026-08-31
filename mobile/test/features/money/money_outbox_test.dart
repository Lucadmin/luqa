import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/money/data/money_outbox.dart';
import 'package:luqa/features/money/data/money_overlay.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/domain/money_split.dart';

final _at = DateTime(2026, 8, 27, 12);

Person _person(String id, {String? name, bool archived = false}) => Person(
  id: id,
  name: name ?? id,
  colorValue: 0xFF2563EB,
  emoji: null,
  defaultPercent: null,
  order: 0,
  archived: archived,
);

MoneyOverview _overview({
  List<PersonBalance> people = const [],
  List<PersonGroup> groups = const [],
}) {
  final owed = people.fold<int>(
    0,
    (sum, p) => sum + (p.balanceCents > 0 ? p.balanceCents : 0),
  );
  final owe = people.fold<int>(
    0,
    (sum, p) => sum + (p.balanceCents < 0 ? -p.balanceCents : 0),
  );
  return MoneyOverview(
    currency: 'EUR',
    people: people,
    groups: groups,
    owedToYouCents: owed,
    youOweCents: owe,
    coveredCents: people.fold<int>(0, (sum, p) => sum + p.coveredCents),
  );
}

PersonBalance _balance(String id, {int cents = 0, int covered = 0}) =>
    PersonBalance(
      person: _person(id),
      balanceCents: cents,
      coveredCents: covered,
      lastActivity: null,
    );

ExpenseWrite _write({
  int amountCents = 3000,
  String? paidByPersonId,
  List<SplitParticipant> participants = const [
    SplitParticipant(personId: 'mira'),
  ],
  String dateKey = '2026-08-27',
  String? groupId,
}) => ExpenseWrite(
  description: 'Dinner',
  amountCents: amountCents,
  dateKey: dateKey,
  paidByPersonId: paidByPersonId,
  groupId: groupId,
  splitMode: SplitMode.equal,
  includeMe: true,
  participants: participants,
  notes: '',
);

CreateExpense _create(String id, {ExpenseWrite? write}) => CreateExpense(
  expenseId: id,
  write: write ?? _write(),
  createdAt: _at,
  queuedAt: _at,
);

void main() {
  group('folding the queue', () {
    test('editing an unsent bill rewrites the create, not a second request', () {
      final queue = foldMoney(
        [_create('bill')],
        UpdateExpense(
          expenseId: 'bill',
          write: _write(amountCents: 5000),
          previous: _create('bill').expense,
          queuedAt: _at,
        ),
      );
      expect(queue, hasLength(1));
      expect(queue.single, isA<CreateExpense>());
      expect((queue.single as CreateExpense).write.amountCents, 5000);
    });

    test('five edits to one bill leave one request', () {
      var queue = <MoneyMutation>[];
      for (final amount in [1000, 2000, 3000, 4000, 5000]) {
        queue = foldMoney(
          queue,
          UpdateExpense(
            expenseId: 'bill',
            write: _write(amountCents: amount),
            previous: _create('bill').expense,
            queuedAt: _at,
          ),
        );
      }
      expect(queue, hasLength(1));
      expect((queue.single as UpdateExpense).write.amountCents, 5000);
    });

    test('a bill created and deleted offline never has to be sent', () {
      final created = foldMoney([], _create('bill'));
      final queue = foldMoney(
        created,
        DeleteExpense(previous: _create('bill').expense, queuedAt: _at),
      );
      expect(queue, isEmpty);
    });

    test('deleting a bill the server has drops the pending edits first', () {
      var queue = foldMoney([], _create('other'));
      queue = foldMoney(
        queue,
        UpdateExpense(
          expenseId: 'bill',
          write: _write(),
          previous: _create('bill').expense,
          queuedAt: _at,
        ),
      );
      queue = foldMoney(
        queue,
        DeleteExpense(previous: _create('bill').expense, queuedAt: _at),
      );
      expect(queue, hasLength(2));
      expect(queue.first, isA<CreateExpense>());
      expect(queue.last, isA<DeleteExpense>());
    });

    test('person edits merge rather than queue up', () {
      var queue = foldMoney(
        [],
        UpdatePerson(personId: 'mira', name: 'Mira', queuedAt: _at),
      );
      queue = foldMoney(
        queue,
        UpdatePerson(personId: 'mira', colorValue: 0xFF15803D, queuedAt: _at),
      );
      expect(queue, hasLength(1));
      final merged = queue.single as UpdatePerson;
      expect(merged.name, 'Mira');
      expect(merged.colorValue, 0xFF15803D);
    });

    test('an edit to an unsent person folds into their create', () {
      final queue = foldMoney(
        [CreatePerson(person: _person('mira', name: 'Mira'), queuedAt: _at)],
        UpdatePerson(personId: 'mira', name: 'Mira K', queuedAt: _at),
      );
      expect(queue, hasLength(1));
      expect((queue.single as CreatePerson).person.name, 'Mira K');
    });

    test('clearing a glyph survives a later merge that does not mention it', () {
      var queue = foldMoney(
        [],
        UpdatePerson(personId: 'mira', clearEmoji: true, queuedAt: _at),
      );
      queue = foldMoney(
        queue,
        UpdatePerson(personId: 'mira', name: 'Mira', queuedAt: _at),
      );
      expect((queue.single as UpdatePerson).clearEmoji, isTrue);
      expect((queue.single as UpdatePerson).emoji, isNull);
    });
  });

  group('overlaying the queue on the server\'s answer', () {
    test('a bill entered offline moves the balances immediately', () {
      final overlaid = overlayMoney(
        _overview(people: [_balance('mira')]),
        [_create('bill')],
      );
      // 30.00 split two ways: Mira carries 15.00 and owes it.
      expect(overlaid.people.single.balanceCents, 1500);
      expect(overlaid.owedToYouCents, 1500);
      expect(overlaid.netCents, 1500);
    });

    test('a bill someone else paid puts the user in debt for their own slice', () {
      final overlaid = overlayMoney(
        _overview(people: [_balance('mira')]),
        [
          _create(
            'bill',
            write: _write(
              amountCents: 4000,
              paidByPersonId: 'mira',
              participants: const [SplitParticipant(personId: 'mira')],
            ),
          ),
        ],
      );
      expect(overlaid.people.single.balanceCents, -2000);
      expect(overlaid.youOweCents, 2000);
      expect(overlaid.owedToYouCents, 0);
    });

    test('a gifted slice is recorded but never becomes a debt', () {
      final overlaid = overlayMoney(
        _overview(people: [_balance('sara')]),
        [
          _create(
            'bill',
            write: _write(
              amountCents: 2000,
              participants: const [
                SplitParticipant(personId: 'sara', gifted: true),
              ],
            ),
          ),
        ],
      );
      expect(overlaid.people.single.balanceCents, 0);
      expect(overlaid.people.single.coveredCents, 1000);
      expect(overlaid.coveredCents, 1000);
    });

    test('editing a bill takes the old effect back out before adding the new', () {
      final original = _create('bill', write: _write(amountCents: 3000));
      final overlaid = overlayMoney(_overview(people: [_balance('mira')]), [
        UpdateExpense(
          expenseId: 'bill',
          write: _write(amountCents: 9000),
          previous: original.expense,
          queuedAt: _at,
        ),
      ]);
      // The server's copy already held the 15.00 from the original, so only
      // the difference should show — but the server copy here is zero, so the
      // reversal leaves the new share minus the old one.
      expect(overlaid.people.single.balanceCents, 4500 - 1500);
    });

    test('deleting a bill takes its effect back out', () {
      final existing = _create('bill').expense;
      final overlaid = overlayMoney(
        _overview(people: [_balance('mira', cents: 1500)]),
        [DeleteExpense(previous: existing, queuedAt: _at)],
      );
      expect(overlaid.people.single.balanceCents, 0);
      expect(overlaid.owedToYouCents, 0);
    });

    test('a payback moves the balance back toward zero', () {
      final overlaid = overlayMoney(
        _overview(people: [_balance('mira', cents: 3000)]),
        [
          CreateSettlement(
            settlement: Settlement(
              id: 'paid',
              personId: 'mira',
              amountCents: 3000,
              direction: SettlementDirection.toMe,
              dateKey: '2026-08-27',
              notes: '',
              createdAt: _at,
            ),
            queuedAt: _at,
          ),
        ],
      );
      expect(overlaid.people.single.balanceCents, 0);
      expect(overlaid.isSettled, isTrue);
    });

    test('someone added offline is in the list before the server hears of them', () {
      final overlaid = overlayMoney(_overview(), [
        CreatePerson(person: _person('new', name: 'Ines'), queuedAt: _at),
      ]);
      expect(overlaid.people.single.person.name, 'Ines');
    });

    test('removing someone who carries a balance archives them instead', () {
      final overlaid = overlayMoney(
        _overview(people: [_balance('mira', cents: 1200)]),
        [DeletePerson(personId: 'mira', queuedAt: _at)],
      );
      expect(overlaid.people.single.person.archived, isTrue);
      // The number does not vanish and reappear on the next refresh.
      expect(overlaid.owedToYouCents, 1200);
    });

    test('removing someone with nothing attached takes them off the list', () {
      final overlaid = overlayMoney(
        _overview(people: [_balance('mira')]),
        [DeletePerson(personId: 'mira', queuedAt: _at)],
      );
      expect(overlaid.people, isEmpty);
    });

    test('the biggest outstanding balance still sorts first', () {
      final overlaid = overlayMoney(
        _overview(
          people: [_balance('small', cents: 100), _balance('big', cents: 9000)],
        ),
        [_create('bill')],
      );
      expect(overlaid.people.first.id, 'big');
    });
  });

  group('overlaying the bill feed', () {
    test('a bill entered offline is at the top of the feed', () {
      final feed = overlayExpenses(
        [
          Expense(
            id: 'old',
            description: 'Old',
            amountCents: 1000,
            dateKey: '2026-08-01',
            paidByPersonId: null,
            groupId: null,
            splitMode: SplitMode.equal,
            myShareCents: 1000,
            notes: '',
            shares: const [],
            createdAt: DateTime(2026, 8, 1),
          ),
        ],
        [_create('bill')],
      );
      expect(feed.first.id, 'bill');
      expect(feed, hasLength(2));
    });

    test('a filtered feed only shows bills that person is on', () {
      final feed = overlayExpenses(
        const [],
        [_create('bill')],
        personId: 'jonas',
      );
      expect(feed, isEmpty);
    });
  });

  group('remapping ids the server renamed', () {
    test('a queued bill follows the person to their real id', () {
      final queue = remapPersonId([_create('bill')], 'mira', 'server-mira');
      final write = (queue.single as CreateExpense).write;
      expect(write.participants.single.personId, 'server-mira');
    });

    test('a payer reference follows too', () {
      final queue = remapPersonId(
        [_create('bill', write: _write(paidByPersonId: 'mira'))],
        'mira',
        'server-mira',
      );
      expect(
        (queue.single as CreateExpense).write.paidByPersonId,
        'server-mira',
      );
    });

    test('group membership follows', () {
      final queue = remapPersonId(
        [
          CreateGroup(
            group: const PersonGroup(
              id: 'flat',
              name: 'The flat',
              colorValue: 0,
              emoji: null,
              order: 0,
              archived: false,
              memberIds: ['mira', 'jonas'],
            ),
            queuedAt: _at,
          ),
        ],
        'mira',
        'server-mira',
      );
      expect((queue.single as CreateGroup).group.memberIds, [
        'server-mira',
        'jonas',
      ]);
    });

    test('a bill follows its group to the real id', () {
      final queue = remapGroupId(
        [_create('bill', write: _write(groupId: 'flat'))],
        'flat',
        'server-flat',
      );
      expect((queue.single as CreateExpense).write.groupId, 'server-flat');
    });
  });

  group('the durable queue survives a restart', () {
    test('every mutation round-trips through json', () {
      final mutations = <MoneyMutation>[
        _create('bill'),
        UpdateExpense(
          expenseId: 'bill',
          write: _write(amountCents: 4200),
          previous: _create('bill').expense,
          queuedAt: _at,
        ),
        DeleteExpense(previous: _create('bill').expense, queuedAt: _at),
        CreatePerson(person: _person('mira', name: 'Mira'), queuedAt: _at),
        UpdatePerson(
          personId: 'mira',
          name: 'Mira K',
          clearEmoji: true,
          clearDefaultPercent: true,
          queuedAt: _at,
        ),
        DeletePerson(personId: 'mira', queuedAt: _at),
        CreateGroup(
          group: const PersonGroup(
            id: 'flat',
            name: 'The flat',
            colorValue: 0xFF15803D,
            emoji: '🏠',
            order: 0,
            archived: false,
            memberIds: ['mira'],
          ),
          queuedAt: _at,
        ),
        UpdateGroup(groupId: 'flat', memberIds: const ['mira'], queuedAt: _at),
        DeleteGroup(groupId: 'flat', queuedAt: _at),
        CreateSettlement(
          settlement: Settlement(
            id: 'paid',
            personId: 'mira',
            amountCents: 3000,
            direction: SettlementDirection.fromMe,
            dateKey: '2026-08-27',
            notes: 'cash',
            createdAt: _at,
          ),
          queuedAt: _at,
        ),
        DeleteSettlement(
          previous: Settlement(
            id: 'paid',
            personId: 'mira',
            amountCents: 3000,
            direction: SettlementDirection.toMe,
            dateKey: '2026-08-27',
            notes: '',
            createdAt: _at,
          ),
          queuedAt: _at,
        ),
      ];

      for (final mutation in mutations) {
        final restored = MoneyMutation.fromJson(mutation.toJson());
        expect(
          restored.runtimeType,
          mutation.runtimeType,
          reason: '${mutation.runtimeType} did not survive a restart',
        );
        expect(restored!.subjectId, mutation.subjectId);
        expect(restored.toJson(), mutation.toJson());
      }
    });

    test('an op written by a newer build is skipped, not fatal', () {
      expect(
        MoneyMutation.fromJson({
          'op': 'somethingNewer',
          'queuedAt': _at.toIso8601String(),
        }),
        isNull,
      );
    });
  });
}
