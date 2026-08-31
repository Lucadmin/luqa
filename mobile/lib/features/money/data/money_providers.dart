import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/money/application/money_sync_engine.dart';
import 'package:luqa/features/money/data/local_first_money_repository.dart';
import 'package:luqa/features/money/data/money_local_store.dart';
import 'package:luqa/features/money/data/money_sync_service.dart';
import 'package:luqa/features/money/data/money_outbox.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/data/remote_money_repository.dart';

/// Everything device-local is filed under the signed-in user, so switching
/// accounts on one phone never shows or sends the other's balances.
final _namespaceProvider = Provider<String?>(
  (ref) => ref.watch(authControllerProvider).value?.user?.id,
);

/// The network. The sync engine talks to this directly; screens do not.
final remoteMoneyRepositoryProvider = Provider<MoneyRepository>(
  (ref) => RemoteMoneyRepository(ref.watch(luqaApiProvider)),
);

/// This device's own money rows. Null while signed out: there is no account
/// to file them under, and a write with nobody to send it as is stranded.
final moneyLocalStoreProvider = Provider<MoneyLocalStore?>((ref) {
  final userId = ref.watch(_namespaceProvider);
  return userId == null ? null : MoneyLocalStore(namespace: userId);
});

final moneySyncServiceProvider = Provider<MoneySyncService?>((ref) {
  final store = ref.watch(moneyLocalStoreProvider);
  if (store == null) return null;
  return MoneySyncService(client: ref.watch(luqaApiProvider), store: store);
});

final moneyOutboxProvider = Provider<Outbox<MoneyMutation>>((ref) {
  final userId = ref.watch(_namespaceProvider);
  // Queueing a write with nobody to send it as would strand it for ever.
  if (userId == null) return const NullOutbox();
  return SqliteMoneyOutbox(namespace: userId);
});

/// Where an abandoned write is recorded so the user can still be told about
/// it — including after a relaunch, since a queue often drains on the resume
/// that precedes the phone going back in a pocket.
final moneyDiscardLogProvider = Provider<DiscardLog>((ref) {
  final userId = ref.watch(_namespaceProvider);
  if (userId == null) return const NullDiscardLog();
  return SqliteDiscardLog(key: 'money', namespace: userId);
});

/// What screens use. Writes land here and return immediately.
///
/// Signed out there is nowhere local to put anything, so the plain remote
/// repository stands in — it will simply fail, which is the honest answer.
final moneyRepositoryProvider = Provider<MoneyRepository>((ref) {
  final store = ref.watch(moneyLocalStoreProvider);
  final sync = ref.watch(moneySyncServiceProvider);
  if (store == null || sync == null) {
    return ref.watch(remoteMoneyRepositoryProvider);
  }
  return LocalFirstMoneyRepository(
    store: store,
    sync: sync,
    queue: ref.watch(moneySyncEngineProvider.notifier),
  );
});

/// The local-first repository, for the few callers that need its cache-only
/// reads as well as the interface.
final localFirstMoneyRepositoryProvider = Provider<LocalFirstMoneyRepository?>((
  ref,
) {
  final repository = ref.watch(moneyRepositoryProvider);
  return repository is LocalFirstMoneyRepository ? repository : null;
});
