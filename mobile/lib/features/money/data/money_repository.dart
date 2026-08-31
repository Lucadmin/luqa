import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/domain/money_split.dart';

/// A bill as the editor hands it over: the total, who was there, and how it is
/// to be divided. The shares themselves are never sent — both this device and
/// the server derive them from these rules, so they cannot disagree.
class ExpenseWrite {
  const ExpenseWrite({
    required this.description,
    required this.amountCents,
    required this.dateKey,
    required this.paidByPersonId,
    required this.groupId,
    required this.splitMode,
    required this.includeMe,
    required this.participants,
    required this.notes,
  });

  final String description;
  final int amountCents;
  final String dateKey;

  /// Null means the user paid.
  final String? paidByPersonId;

  final String? groupId;
  final SplitMode splitMode;
  final bool includeMe;
  final List<SplitParticipant> participants;
  final String notes;

  ExpenseWrite copyWith({
    String? description,
    int? amountCents,
    String? dateKey,
    String? paidByPersonId,
    bool clearPaidBy = false,
    String? groupId,
    bool clearGroup = false,
    SplitMode? splitMode,
    bool? includeMe,
    List<SplitParticipant>? participants,
    String? notes,
  }) => ExpenseWrite(
    description: description ?? this.description,
    amountCents: amountCents ?? this.amountCents,
    dateKey: dateKey ?? this.dateKey,
    paidByPersonId: clearPaidBy ? null : paidByPersonId ?? this.paidByPersonId,
    groupId: clearGroup ? null : groupId ?? this.groupId,
    splitMode: splitMode ?? this.splitMode,
    includeMe: includeMe ?? this.includeMe,
    participants: participants ?? this.participants,
    notes: notes ?? this.notes,
  );

  /// The bill as it will be stored, computed here so the screen can show the
  /// row the instant it is saved rather than after a round trip.
  Expense resolve({required String id, required DateTime createdAt}) {
    final split = computeSplit(
      amountCents: amountCents,
      mode: splitMode,
      participants: paidByPersonId == null
          ? participants
          // A treat only means something when the user is the one who paid.
          : [for (final p in participants) p.copyWith(gifted: false)],
      includeMe: includeMe,
    );
    return Expense(
      id: id,
      description: description,
      amountCents: amountCents,
      dateKey: dateKey,
      paidByPersonId: paidByPersonId,
      groupId: groupId,
      splitMode: splitMode,
      myShareCents: split.myShareCents,
      notes: notes,
      shares: split.shares,
      createdAt: createdAt,
    );
  }
}

class SettlementWrite {
  const SettlementWrite({
    required this.personId,
    required this.amountCents,
    required this.direction,
    required this.dateKey,
    required this.notes,
  });

  final String personId;
  final int amountCents;
  final SettlementDirection direction;
  final String dateKey;
  final String notes;
}

class PersonWrite {
  const PersonWrite({
    required this.name,
    required this.colorValue,
    required this.emoji,
    required this.defaultPercent,
  });

  final String name;
  final int colorValue;
  final String? emoji;
  final int? defaultPercent;
}

class GroupWrite {
  const GroupWrite({
    required this.name,
    required this.colorValue,
    required this.emoji,
    required this.memberIds,
  });

  final String name;
  final int colorValue;
  final String? emoji;
  final List<String> memberIds;
}

abstract interface class MoneyRepository {
  Future<MoneyOverview> loadOverview();

  Future<ExpensePage> loadExpenses({
    String? personId,
    String? groupId,
    String? cursor,
    int limit = 20,
  });

  /// [id] is the identity the device already gave the bill. Sending it makes
  /// the create idempotent, so a retry after a lost response cannot charge
  /// everyone twice.
  Future<Expense> createExpense({String? id, required ExpenseWrite write});

  Future<Expense> updateExpense(String id, ExpenseWrite write);

  Future<void> deleteExpense(String id);

  Future<PersonLedger> loadLedger(String personId);

  Future<Person> createPerson({String? id, required PersonWrite write});

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
  });

  /// Removes someone outright when nothing references them, and archives them
  /// otherwise so the history behind their balance survives.
  Future<void> deletePerson(String id);

  Future<PersonGroup> createGroup({String? id, required GroupWrite write});

  Future<PersonGroup> updateGroup({
    required String id,
    String? name,
    int? colorValue,
    String? emoji,
    bool clearEmoji = false,
    List<String>? memberIds,
    bool? archived,
  });

  Future<void> deleteGroup(String id);

  Future<Settlement> createSettlement({
    String? id,
    required SettlementWrite write,
  });

  Future<void> deleteSettlement(String id);
}
