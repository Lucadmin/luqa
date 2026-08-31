import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/money/data/money_outbox.dart';
import 'package:luqa/features/money/data/money_fold.dart';
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

  group('remapping ids reaches the profile writes too', () {
    test('a note queued against an invented id follows the person', () {
      // This is the reason people and money share one queue. The device made
      // up an id for "Mira", the server matched an existing Mira and answered
      // with a different one, and everything queued behind that create has to
      // be repointed — or it is sent naming somebody the server has never
      // heard of, refused, and reported to the user as lost.
      final queue = <MoneyMutation>[
        AddPersonNote(
          personId: 'local-mira',
          personName: 'Mira',
          noteId: 'note-1',
          body: 'Ceramics course',
          pinned: false,
          happenedOn: null,
          queuedAt: _at,
        ),
        MarkPersonSeen(
          personId: 'local-mira',
          personName: 'Mira',
          seenAt: _at,
          queuedAt: _at,
        ),
        AddPersonPlace(
          personId: 'local-mira',
          personName: 'Mira',
          placeId: 'place-1',
          label: 'Home',
          city: 'Munich',
          country: 'DE',
          isPrimary: true,
          queuedAt: _at,
        ),
      ];

      final remapped = remapPersonId(queue, 'local-mira', 'server-mira');

      expect(
        remapped.map((m) => switch (m) {
          AddPersonNote(:final personId) => personId,
          MarkPersonSeen(:final personId) => personId,
          AddPersonPlace(:final personId) => personId,
          _ => 'unexpected',
        }),
        everyElement('server-mira'),
      );
      // The rows they create keep their own ids: only the person moved.
      expect(
        remapped.whereType<AddPersonNote>().single.noteId,
        'note-1',
      );
    });

    test('a profile write for somebody else is left alone', () {
      final queue = <MoneyMutation>[
        AddPersonNote(
          personId: 'jonas',
          personName: 'Jonas',
          noteId: 'note-2',
          body: 'Moving',
          pinned: false,
          happenedOn: null,
          queuedAt: _at,
        ),
      ];

      final remapped = remapPersonId(queue, 'local-mira', 'server-mira');
      expect(remapped.whereType<AddPersonNote>().single.personId, 'jonas');
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
        // The profile writes. A mutation that cannot be read back after a
        // relaunch is a write the user made and will never be told about.
        MarkPersonSeen(
          personId: 'mira',
          personName: 'Mira',
          seenAt: _at,
          queuedAt: _at,
        ),
        AddPersonNote(
          personId: 'mira',
          personName: 'Mira',
          noteId: 'note-1',
          body: 'Allergic to hazelnuts',
          pinned: true,
          happenedOn: '2026-08-27',
          queuedAt: _at,
        ),
        UpdatePersonNote(
          personId: 'mira',
          personName: 'Mira',
          noteId: 'note-1',
          pinned: false,
          queuedAt: _at,
        ),
        RemovePersonNote(
          personId: 'mira',
          personName: 'Mira',
          noteId: 'note-1',
          queuedAt: _at,
        ),
        AddPersonGift(
          personId: 'mira',
          personName: 'Mira',
          giftId: 'gift-1',
          idea: 'Kiln time',
          url: null,
          queuedAt: _at,
        ),
        // Given and un-given both have to survive: null is the instruction
        // that puts an idea back on the list, not an absent field.
        SetGiftGiven(
          personId: 'mira',
          personName: 'Mira',
          giftId: 'gift-1',
          givenAt: _at,
          queuedAt: _at,
        ),
        SetGiftGiven(
          personId: 'mira',
          personName: 'Mira',
          giftId: 'gift-1',
          givenAt: null,
          queuedAt: _at,
        ),
        RemovePersonGift(
          personId: 'mira',
          personName: 'Mira',
          giftId: 'gift-1',
          queuedAt: _at,
        ),
        AddPersonPlace(
          personId: 'mira',
          personName: 'Mira',
          placeId: 'place-1',
          label: 'Home',
          city: 'Munich',
          country: 'DE',
          isPrimary: true,
          queuedAt: _at,
        ),
        RemovePersonPlace(
          personId: 'mira',
          personName: 'Mira',
          placeId: 'place-1',
          queuedAt: _at,
        ),
        // A person carrying a whole profile, since a create queued from the
        // People sheet already has a birthday and a rhythm on it.
        CreatePerson(
          person: _person('jonas', name: 'Jonas').copyWith(
            nickname: 'Jo',
            birthday: const Birthday(month: 2, day: 29, year: 1996),
            cadenceDays: 61,
            notes: [
              PersonNote(id: 'n', body: 'Ceramics', createdAt: _at),
            ],
            places: const [
              PersonPlace(
                id: 'p',
                label: 'Home',
                city: 'Berlin',
                country: 'DE',
                isPrimary: true,
              ),
            ],
            gifts: const [GiftIdea(id: 'g', idea: 'Rilke letters')],
          ),
          queuedAt: _at,
        ),
        UpdatePerson(
          personId: 'jonas',
          nickname: 'Jo',
          birthday: const Birthday(month: 11, day: 12),
          cadenceDays: 91,
          queuedAt: _at,
        ),
        // Clearing has to survive too: it is a value the server must see, and
        // it cannot ride on the same absence that means "leave it alone".
        UpdatePerson(
          personId: 'jonas',
          clearNickname: true,
          clearBirthday: true,
          clearCadence: true,
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
