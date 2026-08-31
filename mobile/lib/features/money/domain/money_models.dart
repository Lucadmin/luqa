import 'package:flutter/material.dart';

/// Shared expenses, as the phone sees them.
///
/// Every amount is integer cents: a bill split three ways has to add up to the
/// bill exactly, and a double can promise that only by accident. Every balance
/// is written from the user's point of view — positive means this person owes
/// the user.

/// How the per-person shares of a bill were arrived at. Stored so reopening a
/// bill shows the editor state it was saved with.
enum SplitMode {
  /// Everyone on the bill carries the same amount.
  equal,

  /// Explicit percentages, the user carrying whatever is left.
  percent,

  /// Explicit amounts typed per person, the user carrying the rest.
  amount;

  String get wireName => switch (this) {
    SplitMode.equal => 'EQUAL',
    SplitMode.percent => 'PERCENT',
    SplitMode.amount => 'AMOUNT',
  };

  static SplitMode fromWire(String? value) => switch (value) {
    'PERCENT' => SplitMode.percent,
    'AMOUNT' => SplitMode.amount,
    _ => SplitMode.equal,
  };
}

/// Which way the money moved when a debt was paid off.
enum SettlementDirection {
  /// They paid the user back.
  toMe,

  /// The user paid them.
  fromMe;

  String get wireName => this == SettlementDirection.toMe ? 'TO_ME' : 'FROM_ME';

  static SettlementDirection fromWire(String? value) =>
      value == 'FROM_ME' ? SettlementDirection.fromMe : SettlementDirection.toMe;
}

/// Someone the user shares expenses with.
@immutable
class Person {
  const Person({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.emoji,
    required this.defaultPercent,
    required this.order,
    required this.archived,
  });

  final String id;
  final String name;
  final int colorValue;

  /// An optional glyph on the avatar, e.g. "🧡".
  final String? emoji;

  /// The cut of a bill this person usually carries, in whole percent. Null
  /// means share equally with everyone else on it — right for most people.
  final int? defaultPercent;

  final int order;
  final bool archived;

  Person copyWith({
    String? name,
    int? colorValue,
    String? emoji,
    bool clearEmoji = false,
    int? defaultPercent,
    bool clearDefaultPercent = false,
    int? order,
    bool? archived,
  }) => Person(
    id: id,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    emoji: clearEmoji ? null : emoji ?? this.emoji,
    defaultPercent: clearDefaultPercent
        ? null
        : defaultPercent ?? this.defaultPercent,
    order: order ?? this.order,
    archived: archived ?? this.archived,
  );
}

/// A person plus the numbers the overview shows next to their name.
@immutable
class PersonBalance {
  const PersonBalance({
    required this.person,
    required this.balanceCents,
    required this.coveredCents,
    required this.lastActivity,
  });

  final Person person;

  /// Positive: they owe the user. Negative: the user owes them. Zero: settled.
  final int balanceCents;

  /// All-time total covered as a treat. Recorded, never a debt.
  final int coveredCents;

  /// "YYYY-MM-DD" of their newest bill or payback, or null.
  final String? lastActivity;

  String get id => person.id;

  bool get settled => balanceCents == 0;

  PersonBalance copyWith({
    Person? person,
    int? balanceCents,
    int? coveredCents,
    String? lastActivity,
  }) => PersonBalance(
    person: person ?? this.person,
    balanceCents: balanceCents ?? this.balanceCents,
    coveredCents: coveredCents ?? this.coveredCents,
    lastActivity: lastActivity ?? this.lastActivity,
  );
}

/// A named set of people — the friend group, the flat, a trip. Picking one on
/// a bill pre-selects its members; balances stay strictly per person.
@immutable
class PersonGroup {
  const PersonGroup({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.emoji,
    required this.order,
    required this.archived,
    required this.memberIds,
  });

  final String id;
  final String name;
  final int colorValue;
  final String? emoji;
  final int order;
  final bool archived;
  final List<String> memberIds;

  PersonGroup copyWith({
    String? name,
    int? colorValue,
    String? emoji,
    bool clearEmoji = false,
    int? order,
    bool? archived,
    List<String>? memberIds,
  }) => PersonGroup(
    id: id,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    emoji: clearEmoji ? null : emoji ?? this.emoji,
    order: order ?? this.order,
    archived: archived ?? this.archived,
    memberIds: memberIds ?? this.memberIds,
  );
}

/// What one participant carries on one bill.
@immutable
class ExpenseShare {
  const ExpenseShare({
    required this.personId,
    required this.amountCents,
    required this.percentBp,
    required this.gifted,
  });

  final String personId;
  final int amountCents;

  /// This slice as basis points of the bill; 10000 is 100%.
  final int? percentBp;

  /// The user covered this slice as a treat. Totalled against the person, but
  /// never a debt.
  final bool gifted;
}

/// One bill. The user's own slice lives on the expense; every other
/// participant's slice is a share.
@immutable
class Expense {
  const Expense({
    required this.id,
    required this.description,
    required this.amountCents,
    required this.dateKey,
    required this.paidByPersonId,
    required this.groupId,
    required this.splitMode,
    required this.myShareCents,
    required this.notes,
    required this.shares,
    required this.createdAt,
  });

  final String id;
  final String description;
  final int amountCents;
  final String dateKey;

  /// Who fronted the money. Null means the user did, which is the common case.
  final String? paidByPersonId;

  final String? groupId;
  final SplitMode splitMode;

  /// The user's own slice. Shares plus this equals the bill, exactly.
  final int myShareCents;

  final String notes;
  final List<ExpenseShare> shares;
  final DateTime createdAt;

  String get title => description.isEmpty ? 'Expense' : description;

  bool get hasGift => shares.any((share) => share.gifted);

  /// What this bill did to the user's balances: everything they fronted for
  /// other people, or — when someone else paid — their own slice, owed out.
  int get deltaCents => paidByPersonId == null
      ? shares.fold(0, (sum, s) => sum + (s.gifted ? 0 : s.amountCents))
      : -myShareCents;
}

/// A payback. Settles part or all of a person's balance without touching the
/// bills it came from.
@immutable
class Settlement {
  const Settlement({
    required this.id,
    required this.personId,
    required this.amountCents,
    required this.direction,
    required this.dateKey,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String personId;
  final int amountCents;
  final SettlementDirection direction;
  final String dateKey;
  final String notes;
  final DateTime createdAt;

  /// Effect on the balance: a payback always moves it back toward zero.
  int get deltaCents =>
      direction == SettlementDirection.toMe ? -amountCents : amountCents;
}

/// Everything the money screen needs in one payload.
@immutable
class MoneyOverview {
  const MoneyOverview({
    required this.currency,
    required this.people,
    required this.groups,
    required this.owedToYouCents,
    required this.youOweCents,
    required this.coveredCents,
  });

  static const empty = MoneyOverview(
    currency: 'EUR',
    people: [],
    groups: [],
    owedToYouCents: 0,
    youOweCents: 0,
    coveredCents: 0,
  );

  final String currency;

  /// Biggest outstanding balance first; settled people sink to the bottom.
  /// Archived people are included — they may still carry a balance, and their
  /// names have to resolve on old bills.
  final List<PersonBalance> people;

  final List<PersonGroup> groups;
  final int owedToYouCents;
  final int youOweCents;
  final int coveredCents;

  int get netCents => owedToYouCents - youOweCents;

  /// Nothing outstanding in either direction.
  bool get isSettled => owedToYouCents == 0 && youOweCents == 0;

  PersonBalance? balanceOf(String? personId) {
    if (personId == null) return null;
    for (final balance in people) {
      if (balance.id == personId) return balance;
    }
    return null;
  }

  Person? personById(String? personId) => balanceOf(personId)?.person;

  String nameOf(String? personId) => personById(personId)?.name ?? 'someone';

  PersonGroup? groupById(String? groupId) {
    if (groupId == null) return null;
    for (final group in groups) {
      if (group.id == groupId) return group;
    }
    return null;
  }

  /// The people worth listing: everyone active, plus anyone archived who still
  /// owes or is owed something.
  List<PersonBalance> get listed => [
    for (final balance in people)
      if (!balance.person.archived || balance.balanceCents != 0) balance,
  ];

  MoneyOverview copyWith({
    String? currency,
    List<PersonBalance>? people,
    List<PersonGroup>? groups,
    int? owedToYouCents,
    int? youOweCents,
    int? coveredCents,
  }) => MoneyOverview(
    currency: currency ?? this.currency,
    people: people ?? this.people,
    groups: groups ?? this.groups,
    owedToYouCents: owedToYouCents ?? this.owedToYouCents,
    youOweCents: youOweCents ?? this.youOweCents,
    coveredCents: coveredCents ?? this.coveredCents,
  );
}

/// One page of the bill feed, newest first.
@immutable
class ExpensePage {
  const ExpensePage({required this.expenses, required this.nextCursor});

  final List<Expense> expenses;
  final String? nextCursor;
}

/// One row of a person's history.
@immutable
class LedgerItem {
  const LedgerItem({
    required this.id,
    required this.dateKey,
    required this.title,
    required this.deltaCents,
    required this.shareCents,
    required this.gifted,
    required this.amountCents,
    required this.paidByPersonId,
    required this.direction,
    required this.expense,
    required this.createdAt,
  });

  final String id;
  final String dateKey;
  final String title;

  /// Effect on the balance: positive raises what they owe. A gift is zero.
  final int deltaCents;

  /// Their slice of the bill, or the amount a payback moved.
  final int shareCents;

  final bool gifted;

  /// The whole bill, for context. Null on paybacks.
  final int? amountCents;

  final String? paidByPersonId;

  /// Set on paybacks only.
  final SettlementDirection? direction;

  /// Full editor state for bill rows. Null on paybacks.
  final Expense? expense;

  final DateTime createdAt;

  bool get isSettlement => direction != null;
}

/// One person's whole history with the user, and what it adds up to.
@immutable
class PersonLedger {
  const PersonLedger({
    required this.person,
    required this.currency,
    required this.balanceCents,
    required this.coveredCents,
    required this.coveredThisYearCents,
    required this.items,
  });

  final Person person;
  final String currency;
  final int balanceCents;
  final int coveredCents;
  final int coveredThisYearCents;
  final List<LedgerItem> items;

  PersonLedger copyWith({
    Person? person,
    int? balanceCents,
    int? coveredCents,
    int? coveredThisYearCents,
    List<LedgerItem>? items,
  }) => PersonLedger(
    person: person ?? this.person,
    currency: currency,
    balanceCents: balanceCents ?? this.balanceCents,
    coveredCents: coveredCents ?? this.coveredCents,
    coveredThisYearCents: coveredThisYearCents ?? this.coveredThisYearCents,
    items: items ?? this.items,
  );
}

/// A "YYYY-MM-DD" key in the user's own timezone, which is the day they would
/// say a bill happened on.
String moneyDateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

DateTime moneyDateFromKey(String key) =>
    DateTime.tryParse(key) ?? DateTime.now();
