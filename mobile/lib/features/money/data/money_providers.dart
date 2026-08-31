import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/money/application/money_sync_engine.dart';
import 'package:luqa/features/money/data/local_first_money_repository.dart';
import 'package:luqa/features/money/data/money_cache.dart';
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

final moneyCacheProvider = Provider<MoneyCache>((ref) {
  final userId = ref.watch(_namespaceProvider);
  if (userId == null) return const NullMoneyCache();
  return SharedPreferencesMoneyCache(namespace: userId);
});

final moneyOutboxProvider = Provider<Outbox<MoneyMutation>>((ref) {
  final userId = ref.watch(_namespaceProvider);
  // Queueing a write with nobody to send it as would strand it for ever.
  if (userId == null) return const NullOutbox();
  return SharedPreferencesMoneyOutbox(namespace: userId);
});

/// Where an abandoned write is recorded so the user can still be told about
/// it — including after a relaunch, since a queue often drains on the resume
/// that precedes the phone going back in a pocket.
final moneyDiscardLogProvider = Provider<DiscardLog>((ref) {
  final userId = ref.watch(_namespaceProvider);
  if (userId == null) return const NullDiscardLog();
  return SharedPreferencesDiscardLog(key: 'money', namespace: userId);
});

/// What screens use. Writes land here and return immediately.
final moneyRepositoryProvider = Provider<MoneyRepository>((ref) {
  return LocalFirstMoneyRepository(
    remote: ref.watch(remoteMoneyRepositoryProvider),
    cache: ref.watch(moneyCacheProvider),
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
