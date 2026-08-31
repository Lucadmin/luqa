import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/domain/money_split.dart';

/// Codecs shared by the write queue and the read cache, so a bill written by
/// one is readable by the other.

Map<String, Object?> personToJson(Person value) => {
  'id': value.id,
  'name': value.name,
  'colorValue': value.colorValue,
  'emoji': value.emoji,
  'defaultPercent': value.defaultPercent,
  'order': value.order,
  'archived': value.archived,
};

Person personFromJson(Map<String, Object?> value) => Person(
  id: value['id']! as String,
  name: value['name']! as String,
  colorValue: value['colorValue']! as int,
  emoji: value['emoji'] as String?,
  defaultPercent: value['defaultPercent'] as int?,
  order: value['order']! as int,
  archived: value['archived']! as bool,
);

Map<String, Object?> groupToJson(PersonGroup value) => {
  'id': value.id,
  'name': value.name,
  'colorValue': value.colorValue,
  'emoji': value.emoji,
  'order': value.order,
  'archived': value.archived,
  'memberIds': value.memberIds,
};

PersonGroup groupFromJson(Map<String, Object?> value) => PersonGroup(
  id: value['id']! as String,
  name: value['name']! as String,
  colorValue: value['colorValue']! as int,
  emoji: value['emoji'] as String?,
  order: value['order']! as int,
  archived: value['archived']! as bool,
  memberIds: [
    for (final id in value['memberIds']! as List<Object?>) id! as String,
  ],
);

Map<String, Object?> shareToJson(ExpenseShare value) => {
  'personId': value.personId,
  'amountCents': value.amountCents,
  'percentBp': value.percentBp,
  'gifted': value.gifted,
};

ExpenseShare shareFromJson(Map<String, Object?> value) => ExpenseShare(
  personId: value['personId']! as String,
  amountCents: value['amountCents']! as int,
  percentBp: value['percentBp'] as int?,
  gifted: value['gifted']! as bool,
);

Map<String, Object?> expenseToJson(Expense value) => {
  'id': value.id,
  'description': value.description,
  'amountCents': value.amountCents,
  'dateKey': value.dateKey,
  'paidByPersonId': value.paidByPersonId,
  'groupId': value.groupId,
  'splitMode': value.splitMode.wireName,
  'myShareCents': value.myShareCents,
  'notes': value.notes,
  'shares': [for (final share in value.shares) shareToJson(share)],
  'createdAt': value.createdAt.toUtc().toIso8601String(),
};

Expense expenseFromJson(Map<String, Object?> value) => Expense(
  id: value['id']! as String,
  description: value['description']! as String,
  amountCents: value['amountCents']! as int,
  dateKey: value['dateKey']! as String,
  paidByPersonId: value['paidByPersonId'] as String?,
  groupId: value['groupId'] as String?,
  splitMode: SplitMode.fromWire(value['splitMode'] as String?),
  myShareCents: value['myShareCents']! as int,
  notes: value['notes']! as String,
  shares: [
    for (final share in value['shares']! as List<Object?>)
      shareFromJson(share! as Map<String, Object?>),
  ],
  createdAt: DateTime.parse(value['createdAt']! as String).toLocal(),
);

Map<String, Object?> participantToJson(SplitParticipant value) => {
  'personId': value.personId,
  'percentBp': value.percentBp,
  'amountCents': value.amountCents,
  'gifted': value.gifted,
};

SplitParticipant participantFromJson(Map<String, Object?> value) =>
    SplitParticipant(
      personId: value['personId']! as String,
      percentBp: value['percentBp'] as int?,
      amountCents: value['amountCents'] as int?,
      gifted: value['gifted']! as bool,
    );

Map<String, Object?> expenseWriteToJson(ExpenseWrite value) => {
  'description': value.description,
  'amountCents': value.amountCents,
  'dateKey': value.dateKey,
  'paidByPersonId': value.paidByPersonId,
  'groupId': value.groupId,
  'splitMode': value.splitMode.wireName,
  'includeMe': value.includeMe,
  'notes': value.notes,
  'participants': [
    for (final participant in value.participants)
      participantToJson(participant),
  ],
};

ExpenseWrite expenseWriteFromJson(Map<String, Object?> value) => ExpenseWrite(
  description: value['description']! as String,
  amountCents: value['amountCents']! as int,
  dateKey: value['dateKey']! as String,
  paidByPersonId: value['paidByPersonId'] as String?,
  groupId: value['groupId'] as String?,
  splitMode: SplitMode.fromWire(value['splitMode'] as String?),
  includeMe: value['includeMe']! as bool,
  notes: value['notes']! as String,
  participants: [
    for (final participant in value['participants']! as List<Object?>)
      participantFromJson(participant! as Map<String, Object?>),
  ],
);

Map<String, Object?> settlementToJson(Settlement value) => {
  'id': value.id,
  'personId': value.personId,
  'amountCents': value.amountCents,
  'direction': value.direction.wireName,
  'dateKey': value.dateKey,
  'notes': value.notes,
  'createdAt': value.createdAt.toUtc().toIso8601String(),
};

Settlement settlementFromJson(Map<String, Object?> value) => Settlement(
  id: value['id']! as String,
  personId: value['personId']! as String,
  amountCents: value['amountCents']! as int,
  direction: SettlementDirection.fromWire(value['direction'] as String?),
  dateKey: value['dateKey']! as String,
  notes: value['notes']! as String,
  createdAt: DateTime.parse(value['createdAt']! as String).toLocal(),
);

Map<String, Object?> personWriteToJson(PersonWrite value) => {
  'name': value.name,
  'colorValue': value.colorValue,
  'emoji': value.emoji,
  'defaultPercent': value.defaultPercent,
};

PersonWrite personWriteFromJson(Map<String, Object?> value) => PersonWrite(
  name: value['name']! as String,
  colorValue: value['colorValue']! as int,
  emoji: value['emoji'] as String?,
  defaultPercent: value['defaultPercent'] as int?,
);

Map<String, Object?> groupWriteToJson(GroupWrite value) => {
  'name': value.name,
  'colorValue': value.colorValue,
  'emoji': value.emoji,
  'memberIds': value.memberIds,
};

GroupWrite groupWriteFromJson(Map<String, Object?> value) => GroupWrite(
  name: value['name']! as String,
  colorValue: value['colorValue']! as int,
  emoji: value['emoji'] as String?,
  memberIds: [
    for (final id in value['memberIds']! as List<Object?>) id! as String,
  ],
);

Map<String, Object?> balanceToJson(PersonBalance value) => {
  'person': personToJson(value.person),
  'balanceCents': value.balanceCents,
  'coveredCents': value.coveredCents,
  'lastActivity': value.lastActivity,
};

PersonBalance balanceFromJson(Map<String, Object?> value) => PersonBalance(
  person: personFromJson(value['person']! as Map<String, Object?>),
  balanceCents: value['balanceCents']! as int,
  coveredCents: value['coveredCents']! as int,
  lastActivity: value['lastActivity'] as String?,
);

Map<String, Object?> overviewToJson(MoneyOverview value) => {
  'currency': value.currency,
  'people': [for (final balance in value.people) balanceToJson(balance)],
  'groups': [for (final group in value.groups) groupToJson(group)],
  'owedToYouCents': value.owedToYouCents,
  'youOweCents': value.youOweCents,
  'coveredCents': value.coveredCents,
};

MoneyOverview overviewFromJson(Map<String, Object?> value) => MoneyOverview(
  currency: value['currency']! as String,
  people: [
    for (final balance in value['people']! as List<Object?>)
      balanceFromJson(balance! as Map<String, Object?>),
  ],
  groups: [
    for (final group in value['groups']! as List<Object?>)
      groupFromJson(group! as Map<String, Object?>),
  ],
  owedToYouCents: value['owedToYouCents']! as int,
  youOweCents: value['youOweCents']! as int,
  coveredCents: value['coveredCents']! as int,
);
