import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/sync/sync_engine.dart';
import 'package:luqa/features/money/data/money_outbox.dart';
import 'package:luqa/features/money/data/money_overlay.dart';
import 'package:luqa/features/money/data/money_providers.dart';
import 'package:luqa/features/money/data/money_repository.dart';

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

  @override
  SyncState build() {
    adoptOutbox(ref.watch(moneyOutboxProvider), ref.watch(moneyDiscardLogProvider));
    return const SyncState();
  }

  @override
  List<MoneyMutation> fold(List<MoneyMutation> queue, MoneyMutation mutation) =>
      foldMoney(queue, mutation);

  @override
  Future<void> send(MoneyMutation mutation) async {
    switch (mutation) {
      case CreateExpense(:final expenseId, :final write):
        await _remote.createExpense(id: expenseId, write: write);
      case UpdateExpense(:final expenseId, :final write):
        await _remote.updateExpense(expenseId, write);
      case DeleteExpense(:final previous):
        await _remote.deleteExpense(previous.id);

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
          await rewriteQueue(
            (queue) => remapPersonId(queue, person.id, saved.id),
          );
        }
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
      case DeletePerson(:final personId):
        await _remote.deletePerson(personId);

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
          await rewriteQueue(
            (queue) => remapGroupId(queue, group.id, saved.id),
          );
        }
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
      case DeleteGroup(:final groupId):
        await _remote.deleteGroup(groupId);

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
      case DeleteSettlement(:final previous):
        await _remote.deleteSettlement(previous.id);
    }
  }
}
