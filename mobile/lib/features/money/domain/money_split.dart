import 'package:luqa/features/money/domain/money_models.dart';

/// Splitting a bill.
///
/// A port of the server's rules, deliberately kept identical: the editor uses
/// them to preview a split live, and the API re-runs them on save, so what was
/// shown and what is stored can never disagree. One invariant holds
/// everywhere — the other participants' shares plus the user's own share add
/// up to the bill, exactly, in cents.

/// 100% in basis points.
const fullBp = 10000;

/// Divides [total] across [weights] so the parts sum to exactly [total].
///
/// Largest-remainder: every part is floored, then the leftover cents go to the
/// biggest fractions first, the earliest index winning a tie. Rounding each
/// part on its own would lose or invent a cent on most three-way splits.
List<int> allocate(int total, List<num> weights) {
  final count = weights.length;
  if (count == 0) return const [];

  final amount = total.abs();
  final safe = [
    for (final weight in weights)
      weight.isFinite && weight > 0 ? weight.toDouble() : 0.0,
  ];
  final weightSum = safe.fold<double>(0, (sum, weight) => sum + weight);
  if (weightSum <= 0) return List<int>.filled(count, 0);

  final exact = [for (final weight in safe) amount * weight / weightSum];
  final parts = [for (final value in exact) value.floor()];
  var leftover = amount - parts.fold<int>(0, (sum, part) => sum + part);

  final byFraction = [for (var i = 0; i < count; i++) i]
    ..sort((left, right) {
      final leftFraction = exact[left] - exact[left].floor();
      final rightFraction = exact[right] - exact[right].floor();
      final byFraction = rightFraction.compareTo(leftFraction);
      return byFraction != 0 ? byFraction : left.compareTo(right);
    });

  for (var k = 0; leftover > 0; k++, leftover--) {
    parts[byFraction[k % count]] += 1;
  }

  return total < 0 ? [for (final part in parts) -part] : parts;
}

/// One other person on a bill, as the editor holds them. Which field matters
/// depends on the split mode; the rest are carried so switching modes back and
/// forth does not lose what was typed.
class SplitParticipant {
  const SplitParticipant({
    required this.personId,
    this.percentBp,
    this.amountCents,
    this.gifted = false,
  });

  final String personId;

  /// PERCENT mode: the share of the bill this person carries, in basis points.
  final int? percentBp;

  /// AMOUNT mode: the exact cents this person carries.
  final int? amountCents;

  /// Covered as a treat — still recorded against the person, never a debt.
  final bool gifted;

  SplitParticipant copyWith({
    int? percentBp,
    bool clearPercentBp = false,
    int? amountCents,
    bool clearAmountCents = false,
    bool? gifted,
  }) => SplitParticipant(
    personId: personId,
    percentBp: clearPercentBp ? null : percentBp ?? this.percentBp,
    amountCents: clearAmountCents ? null : amountCents ?? this.amountCents,
    gifted: gifted ?? this.gifted,
  );
}

class SplitResult {
  const SplitResult({
    required this.shares,
    required this.myShareCents,
    required this.overAssigned,
  });

  final List<ExpenseShare> shares;

  /// The user's own slice — always the part of the bill nobody else carries.
  final int myShareCents;

  /// True when the other participants were given more than the whole bill.
  /// The server refuses this, so the editor has to say so before saving.
  final bool overAssigned;

  int amountFor(String personId) {
    for (final share in shares) {
      if (share.personId == personId) return share.amountCents;
    }
    return 0;
  }
}

/// Resolves a split into exact per-person cents.
///
/// - EQUAL   — everyone carries the same, the user included unless [includeMe]
///             is false (they paid but were not part of it).
/// - PERCENT — each participant carries the percentage entered for them; the
///             user carries whatever is left. "She pays 40%" means exactly that.
/// - AMOUNT  — each participant carries the amount entered for them; again the
///             user carries the rest.
SplitResult computeSplit({
  required int amountCents,
  required SplitMode mode,
  required List<SplitParticipant> participants,
  bool includeMe = true,
}) {
  final total = amountCents < 0 ? 0 : amountCents;

  // Nobody else on the bill: it is entirely the user's.
  if (participants.isEmpty) {
    return SplitResult(
      shares: const [],
      myShareCents: total,
      overAssigned: false,
    );
  }

  switch (mode) {
    case SplitMode.equal:
      // The user sits first so that, on an uneven cent, they absorb it.
      final weights = includeMe
          ? List<num>.filled(participants.length + 1, 1)
          : <num>[0, ...List<num>.filled(participants.length, 1)];
      final parts = allocate(total, weights);
      return SplitResult(
        myShareCents: parts[0],
        shares: [
          for (final (index, participant) in participants.indexed)
            ExpenseShare(
              personId: participant.personId,
              amountCents: parts[index + 1],
              percentBp: _derivePercentBp(parts[index + 1], total),
              gifted: participant.gifted,
            ),
        ],
        overAssigned: false,
      );

    case SplitMode.percent:
      final bps = [
        for (final participant in participants) clampBp(participant.percentBp),
      ];
      final assignedBp = bps.fold<int>(0, (sum, bp) => sum + bp);
      // The user's percentage is the remainder, so the weights always total
      // 100% and the allocation stays exact.
      final myBp = assignedBp > fullBp ? 0 : fullBp - assignedBp;
      final parts = allocate(total, <num>[myBp, ...bps]);
      return SplitResult(
        myShareCents: parts[0],
        shares: [
          for (final (index, participant) in participants.indexed)
            ExpenseShare(
              personId: participant.personId,
              amountCents: parts[index + 1],
              percentBp: bps[index],
              gifted: participant.gifted,
            ),
        ],
        overAssigned: assignedBp > fullBp,
      );

    case SplitMode.amount:
      final amounts = [
        for (final participant in participants)
          participant.amountCents == null || participant.amountCents! < 0
              ? 0
              : participant.amountCents!,
      ];
      final assigned = amounts.fold<int>(0, (sum, value) => sum + value);
      return SplitResult(
        myShareCents: assigned > total ? 0 : total - assigned,
        shares: [
          for (final (index, participant) in participants.indexed)
            ExpenseShare(
              personId: participant.personId,
              amountCents: amounts[index],
              percentBp: _derivePercentBp(amounts[index], total),
              gifted: participant.gifted,
            ),
        ],
        overAssigned: assigned > total,
      );
  }
}

int clampBp(int? bp) {
  if (bp == null) return 0;
  return bp.clamp(0, fullBp);
}

int? _derivePercentBp(int part, int total) {
  if (total <= 0) return null;
  return (part * fullBp / total).round();
}

/// The split to open the editor with for a freshly picked set of people.
///
/// People with a [Person.defaultPercent] take their usual cut; everyone else —
/// and the user — divides what is left equally. So an ordinary night out lands
/// on a plain even split, while the flatmate who always takes 30% and the
/// sibling the user always covers come out right without touching anything.
({SplitMode mode, bool includeMe, List<SplitParticipant> participants})
defaultSplitFor(List<Person> people) {
  if (people.isEmpty || people.every((person) => person.defaultPercent == null)) {
    return (
      mode: SplitMode.equal,
      includeMe: true,
      participants: [
        for (final person in people) SplitParticipant(personId: person.id),
      ],
    );
  }

  final fixedBp = people.fold<int>(
    0,
    (sum, person) =>
        sum +
        (person.defaultPercent == null
            ? 0
            : clampBp(person.defaultPercent! * 100)),
  );
  final flexible = people.where((person) => person.defaultPercent == null).length;
  final remaining = fixedBp > fullBp ? 0 : fullBp - fixedBp;
  // The user takes one of the flexible slots, and the odd basis point with it.
  final each = flexible > 0 ? remaining ~/ (flexible + 1) : 0;

  return (
    mode: SplitMode.percent,
    includeMe: true,
    participants: [
      for (final person in people)
        SplitParticipant(
          personId: person.id,
          percentBp: person.defaultPercent == null
              ? each
              : clampBp(person.defaultPercent! * 100),
        ),
    ],
  );
}
