import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/domain/money_split.dart';

/// The split rules are a port of the server's, so the numbers previewed at the
/// table are the numbers stored. These tests pin the parts that would silently
/// drift: which way a stray cent goes, and what the user is left carrying.
void main() {
  group('allocate', () {
    test('parts always add up to the total, cent for cent', () {
      for (final total in [1, 2, 7, 99, 100, 1000, 9999, 100000]) {
        for (final count in [1, 2, 3, 4, 7]) {
          final parts = allocate(total, List<num>.filled(count, 1));
          expect(
            parts.fold<int>(0, (sum, part) => sum + part),
            total,
            reason: '$total across $count ways',
          );
        }
      }
    });

    test('leftover cents go to the earliest parts', () {
      // 100 three ways is 33.33…, so the first two absorb the odd cents.
      expect(allocate(100, [1, 1, 1]), [34, 33, 33]);
    });

    test('weights of zero carry nothing', () {
      expect(allocate(900, [0, 1, 1]), [0, 450, 450]);
    });

    test('a total with no weight at all divides into nothing', () {
      expect(allocate(500, [0, 0]), [0, 0]);
    });
  });

  group('equal split', () {
    test('the user absorbs the odd cent, so nobody is over-charged', () {
      final split = computeSplit(
        amountCents: 1000,
        mode: SplitMode.equal,
        participants: const [
          SplitParticipant(personId: 'mira'),
          SplitParticipant(personId: 'jonas'),
        ],
      );
      expect(split.myShareCents, 334);
      expect(split.amountFor('mira'), 333);
      expect(split.amountFor('jonas'), 333);
    });

    test('leaving the user out gives the whole bill to the others', () {
      final split = computeSplit(
        amountCents: 1000,
        mode: SplitMode.equal,
        includeMe: false,
        participants: const [
          SplitParticipant(personId: 'mira'),
          SplitParticipant(personId: 'jonas'),
        ],
      );
      expect(split.myShareCents, 0);
      expect(split.amountFor('mira'), 500);
      expect(split.amountFor('jonas'), 500);
    });

    test('a bill with nobody else on it is entirely the user\'s', () {
      final split = computeSplit(
        amountCents: 4200,
        mode: SplitMode.equal,
        participants: const [],
      );
      expect(split.myShareCents, 4200);
      expect(split.shares, isEmpty);
    });
  });

  group('percent split', () {
    test('a stated percentage means exactly that, and the user takes the rest', () {
      final split = computeSplit(
        amountCents: 10000,
        mode: SplitMode.percent,
        participants: const [
          SplitParticipant(personId: 'mira', percentBp: 4000),
        ],
      );
      expect(split.amountFor('mira'), 4000);
      expect(split.myShareCents, 6000);
      expect(split.overAssigned, isFalse);
    });

    test('over a hundred percent is reported rather than silently clamped', () {
      final split = computeSplit(
        amountCents: 10000,
        mode: SplitMode.percent,
        participants: const [
          SplitParticipant(personId: 'mira', percentBp: 7000),
          SplitParticipant(personId: 'jonas', percentBp: 6000),
        ],
      );
      expect(split.overAssigned, isTrue);
      // Still exact: the shares are what was asked for, and the user carries
      // nothing rather than a negative slice.
      expect(split.myShareCents, 0);
    });

    test('a hundred percent to one person leaves the user with nothing', () {
      final split = computeSplit(
        amountCents: 3300,
        mode: SplitMode.percent,
        participants: const [
          SplitParticipant(personId: 'sara', percentBp: 10000),
        ],
      );
      expect(split.amountFor('sara'), 3300);
      expect(split.myShareCents, 0);
    });
  });

  group('amount split', () {
    test('typed amounts are kept and the user carries the remainder', () {
      final split = computeSplit(
        amountCents: 5000,
        mode: SplitMode.amount,
        participants: const [
          SplitParticipant(personId: 'mira', amountCents: 1250),
        ],
      );
      expect(split.amountFor('mira'), 1250);
      expect(split.myShareCents, 3750);
    });

    test('assigning more than the bill is reported', () {
      final split = computeSplit(
        amountCents: 1000,
        mode: SplitMode.amount,
        participants: const [
          SplitParticipant(personId: 'mira', amountCents: 1500),
        ],
      );
      expect(split.overAssigned, isTrue);
      expect(split.myShareCents, 0);
    });
  });

  group('gifts', () {
    test('a covered slice is still a slice of the bill', () {
      final split = computeSplit(
        amountCents: 3000,
        mode: SplitMode.equal,
        participants: const [
          SplitParticipant(personId: 'sara', gifted: true),
        ],
      );
      expect(split.amountFor('sara'), 1500);
      expect(split.shares.single.gifted, isTrue);
      // The amount is recorded; whether it becomes a debt is a separate rule.
      expect(split.myShareCents, 1500);
    });
  });

  group('defaultSplitFor', () {
    test('an ordinary group lands on a plain even split', () {
      final defaults = defaultSplitFor(const [
        Person(
          id: 'mira',
          name: 'Mira',
          colorValue: 0,
          emoji: null,
          defaultPercent: null,
          order: 0,
          archived: false,
        ),
        Person(
          id: 'jonas',
          name: 'Jonas',
          colorValue: 0,
          emoji: null,
          defaultPercent: null,
          order: 1,
          archived: false,
        ),
      ]);
      expect(defaults.mode, SplitMode.equal);
      expect(defaults.includeMe, isTrue);
      expect(defaults.participants, hasLength(2));
    });

    test('somebody with a usual cut takes it, the rest divide what is left', () {
      final defaults = defaultSplitFor(const [
        Person(
          id: 'flatmate',
          name: 'Ines',
          colorValue: 0,
          emoji: null,
          defaultPercent: 30,
          order: 0,
          archived: false,
        ),
        Person(
          id: 'jonas',
          name: 'Jonas',
          colorValue: 0,
          emoji: null,
          defaultPercent: null,
          order: 1,
          archived: false,
        ),
      ]);
      expect(defaults.mode, SplitMode.percent);
      final ines = defaults.participants.firstWhere(
        (p) => p.personId == 'flatmate',
      );
      final jonas = defaults.participants.firstWhere(
        (p) => p.personId == 'jonas',
      );
      expect(ines.percentBp, 3000);
      // 70% left over, shared between Jonas and the user.
      expect(jonas.percentBp, 3500);
    });

    test('a sibling always covered at 0% leaves the bill with the user', () {
      final defaults = defaultSplitFor(const [
        Person(
          id: 'sara',
          name: 'Sara',
          colorValue: 0,
          emoji: null,
          defaultPercent: 0,
          order: 0,
          archived: false,
        ),
      ]);
      final split = computeSplit(
        amountCents: 4000,
        mode: defaults.mode,
        includeMe: defaults.includeMe,
        participants: defaults.participants,
      );
      expect(split.amountFor('sara'), 0);
      expect(split.myShareCents, 4000);
    });
  });
}
