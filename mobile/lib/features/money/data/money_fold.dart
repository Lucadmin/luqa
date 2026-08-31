import 'package:luqa/features/money/data/money_outbox.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/money/domain/money_split.dart';

/// Keeping the queue of unsent money writes as small as it can honestly be.
///
/// A bill edited five times offline should leave one request behind, and a
/// bill created and deleted before it ever synced should leave none. That is
/// all this does now: the rows themselves live in the device's own tables, so
/// nothing here has to reconstruct what a screen should show.

List<MoneyMutation> foldMoney(List<MoneyMutation> queue, MoneyMutation next) {
  switch (next) {
    case UpdateExpense(:final expenseId, :final write):
      final folded = <MoneyMutation>[];
      var absorbed = false;
      for (final pending in queue) {
        switch (pending) {
          // Editing a bill that has not been created yet is just a different
          // create; there is nothing on the server to patch.
          case CreateExpense(expenseId: final id) when id == expenseId:
            folded.add(
              CreateExpense(
                expenseId: expenseId,
                write: write,
                createdAt: pending.createdAt,
                queuedAt: pending.queuedAt,
              ),
            );
            absorbed = true;
          // A bill is saved wholesale, so only the newest edit matters.
          case UpdateExpense(expenseId: final id) when id == expenseId:
            folded.add(
              UpdateExpense(
                expenseId: expenseId,
                write: write,
                previous: pending.previous,
                queuedAt: pending.queuedAt,
              ),
            );
            absorbed = true;
          case _:
            folded.add(pending);
        }
      }
      return absorbed ? folded : [...folded, next];

    case DeleteExpense(previous: final expense):
      // A bill created and deleted on the same offline stretch never has to
      // reach the server at all.
      final createdHere = queue.any(
        (pending) =>
            pending is CreateExpense && pending.expenseId == expense.id,
      );
      final kept = [
        for (final pending in queue)
          if (!_touchesExpense(pending, expense.id)) pending,
      ];
      return createdHere ? kept : [...kept, next];

    case UpdatePerson(:final personId):
      final folded = <MoneyMutation>[];
      var absorbed = false;
      for (final pending in queue) {
        switch (pending) {
          case CreatePerson(:final person) when person.id == personId:
            folded.add(
              CreatePerson(
                person: next.applyTo(person),
                queuedAt: pending.queuedAt,
              ),
            );
            absorbed = true;
          case UpdatePerson(personId: final id) when id == personId:
            folded.add(next.mergedOver(pending));
            absorbed = true;
          case _:
            folded.add(pending);
        }
      }
      return absorbed ? folded : [...folded, next];

    case DeletePerson(:final personId):
      final createdHere = queue.any(
        (pending) => pending is CreatePerson && pending.person.id == personId,
      );
      final kept = [
        for (final pending in queue)
          if (!_touchesPerson(pending, personId)) pending,
      ];
      return createdHere ? kept : [...kept, next];

    case UpdateGroup(:final groupId):
      final folded = <MoneyMutation>[];
      var absorbed = false;
      for (final pending in queue) {
        switch (pending) {
          case CreateGroup(:final group) when group.id == groupId:
            folded.add(
              CreateGroup(
                group: next.applyTo(group),
                queuedAt: pending.queuedAt,
              ),
            );
            absorbed = true;
          case UpdateGroup(groupId: final id) when id == groupId:
            folded.add(next.mergedOver(pending));
            absorbed = true;
          case _:
            folded.add(pending);
        }
      }
      return absorbed ? folded : [...folded, next];

    case DeleteGroup(:final groupId):
      final createdHere = queue.any(
        (pending) => pending is CreateGroup && pending.group.id == groupId,
      );
      final kept = [
        for (final pending in queue)
          if (!_touchesGroup(pending, groupId)) pending,
      ];
      return createdHere ? kept : [...kept, next];

    case DeleteSettlement(previous: final settlement):
      final createdHere = queue.any(
        (pending) =>
            pending is CreateSettlement &&
            pending.settlement.id == settlement.id,
      );
      final kept = [
        for (final pending in queue)
          if (!(pending is CreateSettlement &&
              pending.settlement.id == settlement.id))
            pending,
      ];
      return createdHere ? kept : [...kept, next];

    // A note written and then removed before either reached the server never
    // has to be sent at all — and the removal would 404 on a note the server
    // has never seen, which is a discarded write for something the user
    // already undid.
    case RemovePersonNote(:final noteId):
      return _dropOrQueue(queue, next, noteId, (pending) => pending is AddPersonNote);
    case RemovePersonGift(:final giftId):
      return _dropOrQueue(queue, next, giftId, (pending) => pending is AddPersonGift);
    case RemovePersonPlace(:final placeId):
      return _dropOrQueue(queue, next, placeId, (pending) => pending is AddPersonPlace);

    // Only the newest matters: seeing somebody twice before a sync is one
    // sighting, and a note pinned then unpinned is one state.
    case MarkPersonSeen(:final personId):
      return _replaceMatching(
        queue,
        next,
        (pending) => pending is MarkPersonSeen && pending.personId == personId,
      );
    case UpdatePersonNote(:final noteId):
      return _replaceMatching(
        queue,
        next,
        (pending) => pending is UpdatePersonNote && pending.noteId == noteId,
      );
    case SetGiftGiven(:final giftId):
      return _replaceMatching(
        queue,
        next,
        (pending) => pending is SetGiftGiven && pending.giftId == giftId,
      );

    case CreateExpense() ||
        CreatePerson() ||
        CreateGroup() ||
        CreateSettlement() ||
        AddPersonNote() ||
        AddPersonGift() ||
        AddPersonPlace():
      return [...queue, next];
  }
}

/// Drops a queued create and its removal, or queues the removal when the row
/// already exists on the server.
List<MoneyMutation> _dropOrQueue(
  List<MoneyMutation> queue,
  MoneyMutation removal,
  String rowId,
  bool Function(MoneyMutation) isCreate,
) {
  final createdHere = queue.any(
    (pending) => isCreate(pending) && pending.subjectId == rowId,
  );
  final kept = [
    for (final pending in queue)
      if (pending.subjectId != rowId) pending,
  ];
  return createdHere ? kept : [...kept, removal];
}

/// Keeps one mutation per subject, in the position the first one took, so the
/// order the user did things in survives the collapse.
List<MoneyMutation> _replaceMatching(
  List<MoneyMutation> queue,
  MoneyMutation next,
  bool Function(MoneyMutation) matches,
) {
  var absorbed = false;
  final folded = <MoneyMutation>[];
  for (final pending in queue) {
    if (matches(pending)) {
      folded.add(next);
      absorbed = true;
    } else {
      folded.add(pending);
    }
  }
  return absorbed ? folded : [...folded, next];
}

bool _touchesExpense(MoneyMutation pending, String expenseId) => switch (pending) {
  CreateExpense(expenseId: final id) => id == expenseId,
  UpdateExpense(expenseId: final id) => id == expenseId,
  DeleteExpense(:final previous) => previous.id == expenseId,
  _ => false,
};

bool _touchesPerson(MoneyMutation pending, String personId) => switch (pending) {
  CreatePerson(:final person) => person.id == personId,
  UpdatePerson(personId: final id) => id == personId,
  DeletePerson(personId: final id) => id == personId,
  // Their record goes with them. A note still queued against somebody removed
  // before either write synced has nowhere to land.
  MarkPersonSeen(personId: final id) => id == personId,
  AddPersonNote(personId: final id) => id == personId,
  UpdatePersonNote(personId: final id) => id == personId,
  RemovePersonNote(personId: final id) => id == personId,
  AddPersonGift(personId: final id) => id == personId,
  SetGiftGiven(personId: final id) => id == personId,
  RemovePersonGift(personId: final id) => id == personId,
  AddPersonPlace(personId: final id) => id == personId,
  RemovePersonPlace(personId: final id) => id == personId,
  _ => false,
};

bool _touchesGroup(MoneyMutation pending, String groupId) => switch (pending) {
  CreateGroup(:final group) => group.id == groupId,
  UpdateGroup(groupId: final id) => id == groupId,
  DeleteGroup(groupId: final id) => id == groupId,
  _ => false,
};

List<MoneyMutation> remapPersonId(
  List<MoneyMutation> queue,
  String from,
  String to,
) {
  if (from == to) return queue;
  return [
    for (final pending in queue)
      switch (pending) {
        CreateExpense(:final expenseId, :final write) =>
          CreateExpense(
            expenseId: expenseId,
            write: _remapWrite(write, from, to),
            createdAt: pending.createdAt,
            queuedAt: pending.queuedAt,
          ),
        UpdateExpense(:final expenseId, :final write, :final previous) =>
          UpdateExpense(
            expenseId: expenseId,
            write: _remapWrite(write, from, to),
            previous: previous,
            queuedAt: pending.queuedAt,
          ),
        CreateGroup(:final group) when group.memberIds.contains(from) =>
          CreateGroup(
            group: group.copyWith(
              memberIds: [
                for (final id in group.memberIds) id == from ? to : id,
              ],
            ),
            queuedAt: pending.queuedAt,
          ),
        UpdateGroup(:final memberIds) when memberIds?.contains(from) ?? false =>
          UpdateGroup(
            groupId: pending.groupId,
            name: pending.name,
            colorValue: pending.colorValue,
            emoji: pending.emoji,
            clearEmoji: pending.clearEmoji,
            memberIds: [for (final id in memberIds!) id == from ? to : id],
            archived: pending.archived,
            queuedAt: pending.queuedAt,
          ),
        UpdatePerson(:final personId) when personId == from => UpdatePerson(
          personId: to,
          name: pending.name,
          colorValue: pending.colorValue,
          emoji: pending.emoji,
          clearEmoji: pending.clearEmoji,
          defaultPercent: pending.defaultPercent,
          clearDefaultPercent: pending.clearDefaultPercent,
          order: pending.order,
          archived: pending.archived,
          nickname: pending.nickname,
          clearNickname: pending.clearNickname,
          birthday: pending.birthday,
          clearBirthday: pending.clearBirthday,
          cadenceDays: pending.cadenceDays,
          clearCadence: pending.clearCadence,
          queuedAt: pending.queuedAt,
        ),
        DeletePerson(:final personId) when personId == from =>
          DeletePerson(personId: to, queuedAt: pending.queuedAt),
        // Their record follows them. A note or a gift idea still queued
        // against the id this device made up would otherwise be sent to a
        // person the server has never heard of, and discarded.
        MarkPersonSeen(:final personId) when personId == from => MarkPersonSeen(
          personId: to,
          personName: pending.personName,
          seenAt: pending.seenAt,
          queuedAt: pending.queuedAt,
        ),
        AddPersonNote(:final personId) when personId == from => AddPersonNote(
          personId: to,
          personName: pending.personName,
          noteId: pending.noteId,
          body: pending.body,
          pinned: pending.pinned,
          happenedOn: pending.happenedOn,
          queuedAt: pending.queuedAt,
        ),
        UpdatePersonNote(:final personId) when personId == from =>
          UpdatePersonNote(
            personId: to,
            personName: pending.personName,
            noteId: pending.noteId,
            body: pending.body,
            pinned: pending.pinned,
            queuedAt: pending.queuedAt,
          ),
        RemovePersonNote(:final personId) when personId == from =>
          RemovePersonNote(
            personId: to,
            personName: pending.personName,
            noteId: pending.noteId,
            queuedAt: pending.queuedAt,
          ),
        AddPersonGift(:final personId) when personId == from => AddPersonGift(
          personId: to,
          personName: pending.personName,
          giftId: pending.giftId,
          idea: pending.idea,
          url: pending.url,
          queuedAt: pending.queuedAt,
        ),
        SetGiftGiven(:final personId) when personId == from => SetGiftGiven(
          personId: to,
          personName: pending.personName,
          giftId: pending.giftId,
          givenAt: pending.givenAt,
          queuedAt: pending.queuedAt,
        ),
        RemovePersonGift(:final personId) when personId == from =>
          RemovePersonGift(
            personId: to,
            personName: pending.personName,
            giftId: pending.giftId,
            queuedAt: pending.queuedAt,
          ),
        AddPersonPlace(:final personId) when personId == from => AddPersonPlace(
          personId: to,
          personName: pending.personName,
          placeId: pending.placeId,
          label: pending.label,
          city: pending.city,
          country: pending.country,
          isPrimary: pending.isPrimary,
          queuedAt: pending.queuedAt,
        ),
        RemovePersonPlace(:final personId) when personId == from =>
          RemovePersonPlace(
            personId: to,
            personName: pending.personName,
            placeId: pending.placeId,
            queuedAt: pending.queuedAt,
          ),
        CreateSettlement(:final settlement) when settlement.personId == from =>
          CreateSettlement(
            settlement: Settlement(
              id: settlement.id,
              personId: to,
              amountCents: settlement.amountCents,
              direction: settlement.direction,
              dateKey: settlement.dateKey,
              notes: settlement.notes,
              createdAt: settlement.createdAt,
            ),
            queuedAt: pending.queuedAt,
          ),
        _ => pending,
      },
  ];
}

ExpenseWrite _remapWrite(ExpenseWrite write, String from, String to) {
  final touchesPayer = write.paidByPersonId == from;
  final touchesParticipant = write.participants.any(
    (participant) => participant.personId == from,
  );
  if (!touchesPayer && !touchesParticipant) return write;
  return write.copyWith(
    paidByPersonId: touchesPayer ? to : write.paidByPersonId,
    participants: [
      for (final participant in write.participants)
        participant.personId == from
            ? SplitParticipant(
                personId: to,
                percentBp: participant.percentBp,
                amountCents: participant.amountCents,
                gifted: participant.gifted,
              )
            : participant,
    ],
  );
}

/// Rewrites references to a group this device named itself.
List<MoneyMutation> remapGroupId(
  List<MoneyMutation> queue,
  String from,
  String to,
) {
  if (from == to) return queue;
  return [
    for (final pending in queue)
      switch (pending) {
        CreateExpense(:final expenseId, :final write)
            when write.groupId == from =>
          CreateExpense(
            expenseId: expenseId,
            write: write.copyWith(groupId: to),
            createdAt: pending.createdAt,
            queuedAt: pending.queuedAt,
          ),
        UpdateExpense(:final expenseId, :final write, :final previous)
            when write.groupId == from =>
          UpdateExpense(
            expenseId: expenseId,
            write: write.copyWith(groupId: to),
            previous: previous,
            queuedAt: pending.queuedAt,
          ),
        UpdateGroup(:final groupId) when groupId == from => UpdateGroup(
          groupId: to,
          name: pending.name,
          colorValue: pending.colorValue,
          emoji: pending.emoji,
          clearEmoji: pending.clearEmoji,
          memberIds: pending.memberIds,
          archived: pending.archived,
          queuedAt: pending.queuedAt,
        ),
        DeleteGroup(:final groupId) when groupId == from =>
          DeleteGroup(groupId: to, queuedAt: pending.queuedAt),
        _ => pending,
      },
  ];
}
