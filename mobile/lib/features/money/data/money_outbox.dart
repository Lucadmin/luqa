import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/money/data/money_json.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/domain/money_models.dart';

/// The writes the money tab can make while offline.
///
/// A bill is split at the table, and a table is exactly where a phone has one
/// bar of signal. Everything the user does is recorded here first and answered
/// from here immediately; the balances they read are the server's last word
/// with this queue laid over the top.
///
/// Bills are sent as an [ExpenseWrite] rather than as resolved shares — the
/// server recomputes the split from the same rules the editor previewed, so
/// the stored shares can never drift from what was shown.
sealed class MoneyMutation implements PendingMutation {
  const MoneyMutation({required this.queuedAt});

  @override
  final DateTime queuedAt;

  static MoneyMutation? fromJson(Map<String, Object?> json) {
    final queuedAt = DateTime.tryParse(json['queuedAt'] as String? ?? '');
    if (queuedAt == null) return null;
    return switch (json['op']) {
      'createExpense' => CreateExpense(
        expenseId: json['expenseId']! as String,
        write: expenseWriteFromJson(json['write']! as Map<String, Object?>),
        createdAt: DateTime.parse(json['createdAt']! as String).toLocal(),
        queuedAt: queuedAt,
      ),
      'updateExpense' => UpdateExpense(
        expenseId: json['expenseId']! as String,
        write: expenseWriteFromJson(json['write']! as Map<String, Object?>),
        previous: expenseFromJson(json['previous']! as Map<String, Object?>),
        queuedAt: queuedAt,
      ),
      'deleteExpense' => DeleteExpense(
        previous: expenseFromJson(json['previous']! as Map<String, Object?>),
        queuedAt: queuedAt,
      ),
      'createPerson' => CreatePerson(
        person: personFromJson(json['person']! as Map<String, Object?>),
        queuedAt: queuedAt,
      ),
      'updatePerson' => UpdatePerson(
        personId: json['personId']! as String,
        name: json['name'] as String?,
        colorValue: json['colorValue'] as int?,
        emoji: json['emoji'] as String?,
        clearEmoji: json['clearEmoji']! as bool,
        defaultPercent: json['defaultPercent'] as int?,
        clearDefaultPercent: json['clearDefaultPercent']! as bool,
        order: json['order'] as int?,
        archived: json['archived'] as bool?,
        queuedAt: queuedAt,
      ),
      'deletePerson' => DeletePerson(
        personId: json['personId']! as String,
        queuedAt: queuedAt,
      ),
      'createGroup' => CreateGroup(
        group: groupFromJson(json['group']! as Map<String, Object?>),
        queuedAt: queuedAt,
      ),
      'updateGroup' => UpdateGroup(
        groupId: json['groupId']! as String,
        name: json['name'] as String?,
        colorValue: json['colorValue'] as int?,
        emoji: json['emoji'] as String?,
        clearEmoji: json['clearEmoji']! as bool,
        memberIds: switch (json['memberIds']) {
          final List<Object?> ids => [for (final id in ids) id! as String],
          _ => null,
        },
        archived: json['archived'] as bool?,
        queuedAt: queuedAt,
      ),
      'deleteGroup' => DeleteGroup(
        groupId: json['groupId']! as String,
        queuedAt: queuedAt,
      ),
      'createSettlement' => CreateSettlement(
        settlement: settlementFromJson(
          json['settlement']! as Map<String, Object?>,
        ),
        queuedAt: queuedAt,
      ),
      'deleteSettlement' => DeleteSettlement(
        previous: settlementFromJson(
          json['previous']! as Map<String, Object?>,
        ),
        queuedAt: queuedAt,
      ),
      // An op written by a newer build is not something this one can replay.
      _ => null,
    };
  }
}

final class CreateExpense extends MoneyMutation {
  const CreateExpense({
    required this.expenseId,
    required this.write,
    required this.createdAt,
    required super.queuedAt,
  });

  final String expenseId;
  final ExpenseWrite write;
  final DateTime createdAt;

  /// The bill as it will be stored — which is what the user is already
  /// looking at.
  Expense get expense => write.resolve(id: expenseId, createdAt: createdAt);

  @override
  String get subjectId => expenseId;

  @override
  Map<String, Object?> toJson() => {
    'op': 'createExpense',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'expenseId': expenseId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'write': expenseWriteToJson(write),
  };
}

final class UpdateExpense extends MoneyMutation {
  const UpdateExpense({
    required this.expenseId,
    required this.write,
    required this.previous,
    required super.queuedAt,
  });

  final String expenseId;
  final ExpenseWrite write;

  /// The bill as it was before this edit, so the overlay can take its effect
  /// on the balances back out before adding the new one.
  final Expense previous;

  Expense get expense =>
      write.resolve(id: expenseId, createdAt: previous.createdAt);

  @override
  String get subjectId => expenseId;

  @override
  Map<String, Object?> toJson() => {
    'op': 'updateExpense',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'expenseId': expenseId,
    'write': expenseWriteToJson(write),
    'previous': expenseToJson(previous),
  };
}

final class DeleteExpense extends MoneyMutation {
  const DeleteExpense({required this.previous, required super.queuedAt});

  final Expense previous;

  @override
  String get subjectId => previous.id;

  @override
  Map<String, Object?> toJson() => {
    'op': 'deleteExpense',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'previous': expenseToJson(previous),
  };
}

final class CreatePerson extends MoneyMutation {
  const CreatePerson({required this.person, required super.queuedAt});

  final Person person;

  @override
  String get subjectId => person.id;

  @override
  Map<String, Object?> toJson() => {
    'op': 'createPerson',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'person': personToJson(person),
  };
}

final class UpdatePerson extends MoneyMutation {
  const UpdatePerson({
    required this.personId,
    this.name,
    this.colorValue,
    this.emoji,
    this.clearEmoji = false,
    this.defaultPercent,
    this.clearDefaultPercent = false,
    this.order,
    this.archived,
    required super.queuedAt,
  });

  final String personId;
  final String? name;
  final int? colorValue;
  final String? emoji;
  final bool clearEmoji;
  final int? defaultPercent;
  final bool clearDefaultPercent;
  final int? order;
  final bool? archived;

  @override
  String get subjectId => personId;

  UpdatePerson mergedOver(UpdatePerson earlier) => UpdatePerson(
    personId: personId,
    name: name ?? earlier.name,
    colorValue: colorValue ?? earlier.colorValue,
    emoji: clearEmoji ? null : emoji ?? earlier.emoji,
    clearEmoji: clearEmoji || (emoji == null && earlier.clearEmoji),
    defaultPercent: clearDefaultPercent
        ? null
        : defaultPercent ?? earlier.defaultPercent,
    clearDefaultPercent:
        clearDefaultPercent ||
        (defaultPercent == null && earlier.clearDefaultPercent),
    order: order ?? earlier.order,
    archived: archived ?? earlier.archived,
    queuedAt: earlier.queuedAt,
  );

  Person applyTo(Person person) => person.copyWith(
    name: name,
    colorValue: colorValue,
    emoji: emoji,
    clearEmoji: clearEmoji,
    defaultPercent: defaultPercent,
    clearDefaultPercent: clearDefaultPercent,
    order: order,
    archived: archived,
  );

  @override
  Map<String, Object?> toJson() => {
    'op': 'updatePerson',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'personId': personId,
    'name': name,
    'colorValue': colorValue,
    'emoji': emoji,
    'clearEmoji': clearEmoji,
    'defaultPercent': defaultPercent,
    'clearDefaultPercent': clearDefaultPercent,
    'order': order,
    'archived': archived,
  };
}

final class DeletePerson extends MoneyMutation {
  const DeletePerson({required this.personId, required super.queuedAt});

  final String personId;

  @override
  String get subjectId => personId;

  @override
  Map<String, Object?> toJson() => {
    'op': 'deletePerson',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'personId': personId,
  };
}

final class CreateGroup extends MoneyMutation {
  const CreateGroup({required this.group, required super.queuedAt});

  final PersonGroup group;

  @override
  String get subjectId => group.id;

  @override
  Map<String, Object?> toJson() => {
    'op': 'createGroup',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'group': groupToJson(group),
  };
}

final class UpdateGroup extends MoneyMutation {
  const UpdateGroup({
    required this.groupId,
    this.name,
    this.colorValue,
    this.emoji,
    this.clearEmoji = false,
    this.memberIds,
    this.archived,
    required super.queuedAt,
  });

  final String groupId;
  final String? name;
  final int? colorValue;
  final String? emoji;
  final bool clearEmoji;
  final List<String>? memberIds;
  final bool? archived;

  @override
  String get subjectId => groupId;

  UpdateGroup mergedOver(UpdateGroup earlier) => UpdateGroup(
    groupId: groupId,
    name: name ?? earlier.name,
    colorValue: colorValue ?? earlier.colorValue,
    emoji: clearEmoji ? null : emoji ?? earlier.emoji,
    clearEmoji: clearEmoji || (emoji == null && earlier.clearEmoji),
    memberIds: memberIds ?? earlier.memberIds,
    archived: archived ?? earlier.archived,
    queuedAt: earlier.queuedAt,
  );

  PersonGroup applyTo(PersonGroup group) => group.copyWith(
    name: name,
    colorValue: colorValue,
    emoji: emoji,
    clearEmoji: clearEmoji,
    memberIds: memberIds,
    archived: archived,
  );

  @override
  Map<String, Object?> toJson() => {
    'op': 'updateGroup',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'groupId': groupId,
    'name': name,
    'colorValue': colorValue,
    'emoji': emoji,
    'clearEmoji': clearEmoji,
    'memberIds': memberIds,
    'archived': archived,
  };
}

final class DeleteGroup extends MoneyMutation {
  const DeleteGroup({required this.groupId, required super.queuedAt});

  final String groupId;

  @override
  String get subjectId => groupId;

  @override
  Map<String, Object?> toJson() => {
    'op': 'deleteGroup',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'groupId': groupId,
  };
}

final class CreateSettlement extends MoneyMutation {
  const CreateSettlement({required this.settlement, required super.queuedAt});

  final Settlement settlement;

  @override
  String get subjectId => settlement.id;

  @override
  Map<String, Object?> toJson() => {
    'op': 'createSettlement',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'settlement': settlementToJson(settlement),
  };
}

final class DeleteSettlement extends MoneyMutation {
  const DeleteSettlement({required this.previous, required super.queuedAt});

  final Settlement previous;

  @override
  String get subjectId => previous.id;

  @override
  Map<String, Object?> toJson() => {
    'op': 'deleteSettlement',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'previous': settlementToJson(previous),
  };
}

/// The money tab's durable queue.
class SharedPreferencesMoneyOutbox
    extends SharedPreferencesOutbox<MoneyMutation> {
  SharedPreferencesMoneyOutbox({required super.namespace, super.preferences})
    : super(key: 'money', decode: MoneyMutation.fromJson);
}
