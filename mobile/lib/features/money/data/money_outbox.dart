import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/money/data/money_json.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/domain/money_models.dart';

/// The writes the money tab and the People tab can make while offline.
///
/// A bill is split at the table, and a table is exactly where a phone has one
/// bar of signal. Everything the user does is recorded here first and answered
/// from here immediately; the balances they read are the server's last word
/// with this queue laid over the top.
///
/// **Why people share this queue rather than having their own.** Two things
/// force it. A bill references a person by an id this device may have invented,
/// so a person create and an expense create have to replay in the order they
/// happened — two queues have no order between them, and the expense losing
/// that race is rejected for naming a person the server has never heard of.
/// And when the server answers a create with a different id, because it matched
/// somebody by name, everything still queued behind it has to be repointed;
/// [rewriteQueue] can only rewrite the queue it is in.
///
/// Bills are sent as an [ExpenseWrite] rather than as resolved shares — the
/// server recomputes the split from the same rules the editor previewed, so
/// the stored shares can never drift from what was shown.
sealed class MoneyMutation implements PendingMutation {
  const MoneyMutation({required this.queuedAt});

  @override
  final DateTime queuedAt;

  /// Named the way the user would name it, because this is only ever read
  /// when they are being told the change did not survive.
  @override
  String describe() => switch (this) {
    CreateExpense(:final write) => 'the ${_amount(write.amountCents)} '
        '${write.description.isEmpty ? 'expense' : write.description}',
    UpdateExpense(:final write) => 'your edit to the '
        '${write.description.isEmpty ? 'expense' : write.description}',
    DeleteExpense(:final previous) => 'deleting ${previous.title}',
    CreatePerson(:final person) => 'adding ${person.name}',
    UpdatePerson(:final name) => 'your edit to ${name ?? 'a person'}',
    DeletePerson() => 'removing a person',
    MarkPersonSeen(:final personName) => 'seeing $personName',
    AddPersonNote(:final personName, :final body) =>
      'the note about $personName — "${_short(body)}"',
    UpdatePersonNote(:final personName) => 'your edit to a note about '
        '$personName',
    RemovePersonNote(:final personName) => 'removing a note about $personName',
    AddPersonGift(:final personName, :final idea) =>
      'the gift idea for $personName — "${_short(idea)}"',
    SetGiftGiven(:final personName) => 'the gift idea for $personName',
    RemovePersonGift(:final personName) =>
      'removing a gift idea for $personName',
    AddPersonPlace(:final personName, :final city) =>
      '$personName being in $city',
    RemovePersonPlace(:final personName) => 'removing a city for $personName',
    CreateGroup(:final group) => 'the group ${group.name}',
    UpdateGroup(:final name) => 'your edit to ${name ?? 'a group'}',
    DeleteGroup() => 'deleting a group',
    CreateSettlement(:final settlement) =>
      'the ${_amount(settlement.amountCents)} payback',
    DeleteSettlement() => 'undoing a payback',
  };

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
        nickname: json['nickname'] as String?,
        clearNickname: (json['clearNickname'] as bool?) ?? false,
        birthday: birthdayFromJson(json['birthday']),
        clearBirthday: (json['clearBirthday'] as bool?) ?? false,
        cadenceDays: json['cadenceDays'] as int?,
        clearCadence: (json['clearCadence'] as bool?) ?? false,
        queuedAt: queuedAt,
      ),
      'markPersonSeen' => MarkPersonSeen(
        personId: json['personId']! as String,
        personName: json['personName']! as String,
        seenAt: DateTime.parse(json['seenAt']! as String).toLocal(),
        queuedAt: queuedAt,
      ),
      'addPersonNote' => AddPersonNote(
        personId: json['personId']! as String,
        personName: json['personName']! as String,
        noteId: json['noteId']! as String,
        body: json['body']! as String,
        pinned: json['pinned']! as bool,
        happenedOn: json['happenedOn'] as String?,
        queuedAt: queuedAt,
      ),
      'updatePersonNote' => UpdatePersonNote(
        personId: json['personId']! as String,
        personName: json['personName']! as String,
        noteId: json['noteId']! as String,
        body: json['body'] as String?,
        pinned: json['pinned'] as bool?,
        queuedAt: queuedAt,
      ),
      'removePersonNote' => RemovePersonNote(
        personId: json['personId']! as String,
        personName: json['personName']! as String,
        noteId: json['noteId']! as String,
        queuedAt: queuedAt,
      ),
      'addPersonGift' => AddPersonGift(
        personId: json['personId']! as String,
        personName: json['personName']! as String,
        giftId: json['giftId']! as String,
        idea: json['idea']! as String,
        url: json['url'] as String?,
        queuedAt: queuedAt,
      ),
      'setGiftGiven' => SetGiftGiven(
        personId: json['personId']! as String,
        personName: json['personName']! as String,
        giftId: json['giftId']! as String,
        givenAt: switch (json['givenAt']) {
          final String at => DateTime.parse(at).toLocal(),
          _ => null,
        },
        queuedAt: queuedAt,
      ),
      'removePersonGift' => RemovePersonGift(
        personId: json['personId']! as String,
        personName: json['personName']! as String,
        giftId: json['giftId']! as String,
        queuedAt: queuedAt,
      ),
      'addPersonPlace' => AddPersonPlace(
        personId: json['personId']! as String,
        personName: json['personName']! as String,
        placeId: json['placeId']! as String,
        label: json['label']! as String,
        city: json['city']! as String,
        country: json['country'] as String?,
        // Absent in anything queued before cities could be chosen, which
        // decodes as a typed name — exactly what it was.
        cityId: (json['cityId'] as num?)?.toInt(),
        isPrimary: json['isPrimary']! as bool,
        queuedAt: queuedAt,
      ),
      'removePersonPlace' => RemovePersonPlace(
        personId: json['personId']! as String,
        personName: json['personName']! as String,
        placeId: json['placeId']! as String,
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
    this.nickname,
    this.clearNickname = false,
    this.birthday,
    this.clearBirthday = false,
    this.cadenceDays,
    this.clearCadence = false,
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
  final String? nickname;
  final bool clearNickname;
  final Birthday? birthday;
  final bool clearBirthday;
  final int? cadenceDays;
  final bool clearCadence;

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
    nickname: clearNickname ? null : nickname ?? earlier.nickname,
    clearNickname: clearNickname || (nickname == null && earlier.clearNickname),
    birthday: clearBirthday ? null : birthday ?? earlier.birthday,
    clearBirthday: clearBirthday || (birthday == null && earlier.clearBirthday),
    cadenceDays: clearCadence ? null : cadenceDays ?? earlier.cadenceDays,
    clearCadence: clearCadence || (cadenceDays == null && earlier.clearCadence),
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
    nickname: nickname,
    clearNickname: clearNickname,
    birthday: birthday,
    clearBirthday: clearBirthday,
    cadenceDays: cadenceDays,
    clearCadence: clearCadence,
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
    'nickname': nickname,
    'clearNickname': clearNickname,
    'birthday': birthdayToJson(birthday),
    'clearBirthday': clearBirthday,
    'cadenceDays': cadenceDays,
    'clearCadence': clearCadence,
  };
}

// --------------------------------------------------------- person profile
//
// Every one of these carries `personName` as well as `personId`. It is used
// for exactly one thing: telling the user which change was lost when a write
// has to be abandoned. "removing a note about Mira" is actionable; a ULID is
// not.
//
// Each also names the row it creates, so a write retried after a lost response
// lands once rather than twice.

final class MarkPersonSeen extends MoneyMutation {
  const MarkPersonSeen({
    required this.personId,
    required this.personName,
    required this.seenAt,
    required super.queuedAt,
  });

  final String personId;
  final String personName;
  final DateTime seenAt;

  @override
  String get subjectId => personId;

  @override
  Map<String, Object?> toJson() => {
    'op': 'markPersonSeen',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'personId': personId,
    'personName': personName,
    'seenAt': seenAt.toUtc().toIso8601String(),
  };
}

final class AddPersonNote extends MoneyMutation {
  const AddPersonNote({
    required this.personId,
    required this.personName,
    required this.noteId,
    required this.body,
    required this.pinned,
    required this.happenedOn,
    required super.queuedAt,
  });

  final String personId;
  final String personName;
  final String noteId;
  final String body;
  final bool pinned;
  final String? happenedOn;

  @override
  String get subjectId => noteId;

  @override
  Map<String, Object?> toJson() => {
    'op': 'addPersonNote',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'personId': personId,
    'personName': personName,
    'noteId': noteId,
    'body': body,
    'pinned': pinned,
    'happenedOn': happenedOn,
  };
}

final class UpdatePersonNote extends MoneyMutation {
  const UpdatePersonNote({
    required this.personId,
    required this.personName,
    required this.noteId,
    this.body,
    this.pinned,
    required super.queuedAt,
  });

  final String personId;
  final String personName;
  final String noteId;
  final String? body;
  final bool? pinned;

  @override
  String get subjectId => noteId;

  @override
  Map<String, Object?> toJson() => {
    'op': 'updatePersonNote',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'personId': personId,
    'personName': personName,
    'noteId': noteId,
    'body': body,
    'pinned': pinned,
  };
}

final class RemovePersonNote extends MoneyMutation {
  const RemovePersonNote({
    required this.personId,
    required this.personName,
    required this.noteId,
    required super.queuedAt,
  });

  final String personId;
  final String personName;
  final String noteId;

  @override
  String get subjectId => noteId;

  @override
  Map<String, Object?> toJson() => {
    'op': 'removePersonNote',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'personId': personId,
    'personName': personName,
    'noteId': noteId,
  };
}

final class AddPersonGift extends MoneyMutation {
  const AddPersonGift({
    required this.personId,
    required this.personName,
    required this.giftId,
    required this.idea,
    required this.url,
    required super.queuedAt,
  });

  final String personId;
  final String personName;
  final String giftId;
  final String idea;
  final String? url;

  @override
  String get subjectId => giftId;

  @override
  Map<String, Object?> toJson() => {
    'op': 'addPersonGift',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'personId': personId,
    'personName': personName,
    'giftId': giftId,
    'idea': idea,
    'url': url,
  };
}

final class SetGiftGiven extends MoneyMutation {
  const SetGiftGiven({
    required this.personId,
    required this.personName,
    required this.giftId,
    required this.givenAt,
    required super.queuedAt,
  });

  final String personId;
  final String personName;
  final String giftId;

  /// Null puts the idea back on the list, so it is a value rather than an
  /// absence and always travels.
  final DateTime? givenAt;

  @override
  String get subjectId => giftId;

  @override
  Map<String, Object?> toJson() => {
    'op': 'setGiftGiven',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'personId': personId,
    'personName': personName,
    'giftId': giftId,
    'givenAt': givenAt?.toUtc().toIso8601String(),
  };
}

final class RemovePersonGift extends MoneyMutation {
  const RemovePersonGift({
    required this.personId,
    required this.personName,
    required this.giftId,
    required super.queuedAt,
  });

  final String personId;
  final String personName;
  final String giftId;

  @override
  String get subjectId => giftId;

  @override
  Map<String, Object?> toJson() => {
    'op': 'removePersonGift',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'personId': personId,
    'personName': personName,
    'giftId': giftId,
  };
}

final class AddPersonPlace extends MoneyMutation {
  const AddPersonPlace({
    required this.personId,
    required this.personName,
    required this.placeId,
    required this.label,
    required this.city,
    required this.country,
    required this.isPrimary,
    required super.queuedAt,
    this.cityId,
  });

  final String personId;
  final String personName;
  final String placeId;
  final String label;
  final String city;
  final String? country;
  final bool isPrimary;

  /// The city that was chosen, if one was. Null for a name typed offline,
  /// which is the case this queue exists for — the server takes the name as
  /// given and its geocoding batch guesses at it later.
  ///
  /// Nullable rather than required because anything already sitting in a
  /// device's queue was written before this field existed.
  final int? cityId;

  @override
  String get subjectId => placeId;

  @override
  Map<String, Object?> toJson() => {
    'op': 'addPersonPlace',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'personId': personId,
    'personName': personName,
    'placeId': placeId,
    'label': label,
    'city': city,
    'country': country,
    'cityId': cityId,
    'isPrimary': isPrimary,
  };
}

final class RemovePersonPlace extends MoneyMutation {
  const RemovePersonPlace({
    required this.personId,
    required this.personName,
    required this.placeId,
    required super.queuedAt,
  });

  final String personId;
  final String personName;
  final String placeId;

  @override
  String get subjectId => placeId;

  @override
  Map<String, Object?> toJson() => {
    'op': 'removePersonPlace',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'personId': personId,
    'personName': personName,
    'placeId': placeId,
  };
}

/// Enough of a body to recognise which one it was, without turning a notice
/// into a wall of text.
String _short(String value) {
  final trimmed = value.trim();
  return trimmed.length <= 40 ? trimmed : '${trimmed.substring(0, 39)}…';
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

/// Cents as a bare figure. The notice this appears in has no currency to hand
/// — it is written from a queue, not from a loaded overview — and a wrong
/// symbol would be worse than none.
String _amount(int cents) => cents % 100 == 0
    ? '${cents ~/ 100}'
    : '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

/// The money tab's durable queue.
class SqliteMoneyOutbox extends SqliteOutbox<MoneyMutation> {
  SqliteMoneyOutbox({required super.namespace, super.store})
    : super(key: 'money', decode: MoneyMutation.fromJson);
}
