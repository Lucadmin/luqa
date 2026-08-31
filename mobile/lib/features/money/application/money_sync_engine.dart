import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/sync/sync_engine.dart';
import 'package:luqa/features/money/data/money_outbox.dart';
import 'package:luqa/features/money/data/money_fold.dart';
import 'package:luqa/features/money/data/money_local_store.dart';
import 'package:luqa/features/money/data/money_providers.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:luqa/features/people/data/people_providers.dart';
import 'package:luqa/features/people/data/people_repository.dart';

/// Sends the bills, people and paybacks this device has already recorded.
///
/// Not tied to a screen: a bill split over dinner has to reach the server
/// whenever signal returns, long after the sheet was closed.
final moneySyncEngineProvider = NotifierProvider<MoneySyncEngine, SyncState>(
  MoneySyncEngine.new,
);

class MoneySyncEngine extends Notifier<SyncState> with SyncQueue<MoneyMutation> {
  /// Read at the moment of sending rather than held, so an empty queue never
  /// causes a network stack to be built at all.
  MoneyRepository get _remote => ref.read(remoteMoneyRepositoryProvider);

  /// This device's own rows, so a write that has landed can stop being
  /// treated as newer than the server's copy of it.
  MoneyLocalStore? get _store => ref.read(moneyLocalStoreProvider);

  /// The People contract. Person writes ride in this queue rather than one of
  /// their own — see [MoneyMutation] for why — so this engine is what sends
  /// them.
  PeopleRepository get _people => ref.read(remotePeopleRepositoryProvider);

  /// Takes the server's copy of a person, record and all, and stops treating
  /// the local one as newer.
  Future<void> _savePerson(Person person) async {
    await _store?.putPerson(person, pending: false);
  }

  @override
  SyncState build() {
    adoptOutbox(ref.watch(moneyOutboxProvider), ref.watch(moneyDiscardLogProvider));
    return const SyncState();
  }

  @override
  List<MoneyMutation> fold(List<MoneyMutation> queue, MoneyMutation mutation) =>
      foldMoney(queue, mutation);

  /// A write has landed. Clearing its `pending` flag hands the row back to
  /// the delta feed — until now a sync had to leave it alone, because the
  /// local copy was the newer one.
  ///
  /// A row deleted here is not settled but forgotten: there is nothing left
  /// for a delta to confirm, and leaving it would keep it hidden for ever.
  Future<void> _settled(String table, String id) async =>
      _store?.settle(table, id);

  Future<void> _forgotten(String table, String id) async =>
      _store?.forget(table, id);

  /// The server chose a different id — it matched an existing row by name.
  /// Everything on this device that pointed at the id we invented follows it.
  Future<void> _remapped(String table, String from, String to) async =>
      _store?.remapId(table, from, to);

  @override
  Future<void> send(MoneyMutation mutation) async {
    switch (mutation) {
      case CreateExpense(:final expenseId, :final write):
        await _remote.createExpense(id: expenseId, write: write);
        await _settled('money_expense', expenseId);
      case UpdateExpense(:final expenseId, :final write):
        await _remote.updateExpense(expenseId, write);
        await _settled('money_expense', expenseId);
      case DeleteExpense(:final previous):
        await _remote.deleteExpense(previous.id);
        await _forgotten('money_expense', previous.id);

      case CreatePerson(:final person):
        final saved = await _remote.createPerson(
          id: person.id,
          write: PersonWrite(
            name: person.name,
            colorValue: person.colorValue,
            emoji: person.emoji,
            defaultPercent: person.defaultPercent,
          ),
        );
        // Someone with this name may already exist server-side under another
        // id. Every bill still queued behind this one points at the one this
        // device made up, so they have to be repointed before they are sent.
        if (saved.id != person.id) {
          // Recorded first: a write being made right now resolves through it,
          // one already queued is caught by the rewrite below.
          await _remapped('person', person.id, saved.id);
          await rewriteQueue(
            (queue) => remapPersonId(queue, person.id, saved.id),
          );
        }
        await _settled('person', saved.id);
      case UpdatePerson(:final personId):
        await _remote.updatePerson(
          id: personId,
          name: mutation.name,
          colorValue: mutation.colorValue,
          emoji: mutation.emoji,
          clearEmoji: mutation.clearEmoji,
          defaultPercent: mutation.defaultPercent,
          clearDefaultPercent: mutation.clearDefaultPercent,
          order: mutation.order,
          archived: mutation.archived,
        );
        await _settled('person', personId);
      case DeletePerson(:final personId):
        await _remote.deletePerson(personId);
        await _forgotten('person', personId);

      // The profile writes. Every one of them answers with the whole person,
      // so the row this device is holding is replaced outright rather than
      // patched — which is also what clears its pending flag, since the copy
      // that comes back is the server's and no longer needs protecting from
      // the delta feed.
      case MarkPersonSeen(:final personId, :final seenAt):
        await _savePerson(await _people.markSeen(personId, seenAt));
      case AddPersonNote(:final personId, :final noteId):
        await _savePerson(
          await _people.addNote(
            personId,
            id: noteId,
            body: mutation.body,
            pinned: mutation.pinned,
            happenedOn: mutation.happenedOn,
          ),
        );
      case UpdatePersonNote(:final personId, :final noteId):
        await _savePerson(
          await _people.updateNote(
            personId,
            noteId: noteId,
            body: mutation.body,
            pinned: mutation.pinned,
          ),
        );
      case RemovePersonNote(:final personId, :final noteId):
        await _savePerson(await _people.removeNote(personId, noteId));
      case AddPersonGift(:final personId, :final giftId):
        await _savePerson(
          await _people.addGift(
            personId,
            id: giftId,
            idea: mutation.idea,
            url: mutation.url,
          ),
        );
      case SetGiftGiven(:final personId, :final giftId, :final givenAt):
        await _savePerson(
          await _people.setGiftGiven(
            personId,
            giftId: giftId,
            givenAt: givenAt,
          ),
        );
      case RemovePersonGift(:final personId, :final giftId):
        await _savePerson(await _people.removeGift(personId, giftId));
      case AddPersonPlace(:final personId, :final placeId):
        await _savePerson(
          await _people.addPlace(
            personId,
            id: placeId,
            label: mutation.label,
            city: mutation.city,
            country: mutation.country,
            isPrimary: mutation.isPrimary,
          ),
        );
      case RemovePersonPlace(:final personId, :final placeId):
        await _savePerson(await _people.removePlace(personId, placeId));

      case CreateGroup(:final group):
        final saved = await _remote.createGroup(
          id: group.id,
          write: GroupWrite(
            name: group.name,
            colorValue: group.colorValue,
            emoji: group.emoji,
            memberIds: group.memberIds,
          ),
        );
        if (saved.id != group.id) {
          await _remapped('money_group', group.id, saved.id);
          await rewriteQueue(
            (queue) => remapGroupId(queue, group.id, saved.id),
          );
        }
        await _settled('money_group', saved.id);
      case UpdateGroup(:final groupId):
        await _remote.updateGroup(
          id: groupId,
          name: mutation.name,
          colorValue: mutation.colorValue,
          emoji: mutation.emoji,
          clearEmoji: mutation.clearEmoji,
          memberIds: mutation.memberIds,
          archived: mutation.archived,
        );
        await _settled('money_group', groupId);
      case DeleteGroup(:final groupId):
        await _remote.deleteGroup(groupId);
        await _forgotten('money_group', groupId);

      case CreateSettlement(:final settlement):
        await _remote.createSettlement(
          id: settlement.id,
          write: SettlementWrite(
            personId: settlement.personId,
            amountCents: settlement.amountCents,
            direction: settlement.direction,
            dateKey: settlement.dateKey,
            notes: settlement.notes,
          ),
        );
        await _settled('money_settlement', settlement.id);
      case DeleteSettlement(:final previous):
        await _remote.deleteSettlement(previous.id);
        await _forgotten('money_settlement', previous.id);
    }
  }
}
