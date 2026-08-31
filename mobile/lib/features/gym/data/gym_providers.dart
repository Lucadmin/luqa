import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/gym/application/gym_sync_engine.dart';
import 'package:luqa/features/gym/data/gym_local_store.dart';
import 'package:luqa/features/gym/data/gym_sync_service.dart';
import 'package:luqa/features/gym/data/gym_outbox.dart';
import 'package:luqa/features/gym/data/gym_repository.dart';
import 'package:luqa/features/gym/data/local_first_gym_repository.dart';
import 'package:luqa/features/gym/data/remote_gym_repository.dart';

/// Everything device-local is filed under the signed-in user, so switching
/// accounts on one phone never shows or sends the other's workouts.
final _namespaceProvider = Provider<String?>(
  (ref) => ref.watch(authControllerProvider).value?.user?.id,
);

/// The network. The sync engine talks to this directly; screens do not.
final remoteGymRepositoryProvider = Provider<GymRepository>(
  (ref) => RemoteGymRepository(ref.watch(luqaApiProvider)),
);

/// This device's own gym rows. Null while signed out: there is no account to
/// file them under.
final gymLocalStoreProvider = Provider<GymLocalStore?>((ref) {
  final userId = ref.watch(_namespaceProvider);
  return userId == null ? null : GymLocalStore(namespace: userId);
});

final gymSyncServiceProvider = Provider<GymSyncService?>((ref) {
  final store = ref.watch(gymLocalStoreProvider);
  if (store == null) return null;
  return GymSyncService(client: ref.watch(luqaApiProvider), store: store);
});

final gymOutboxProvider = Provider<Outbox<GymMutation>>((ref) {
  final userId = ref.watch(_namespaceProvider);
  // Queueing a write with nobody to send it as would strand it for ever.
  if (userId == null) return const NullOutbox();
  return SqliteGymOutbox(namespace: userId);
});

/// Where an abandoned write is recorded so the user can still be told about
/// it — including after a relaunch, since a queue often drains on the resume
/// that precedes the phone going back in a pocket.
final gymDiscardLogProvider = Provider<DiscardLog>((ref) {
  final userId = ref.watch(_namespaceProvider);
  if (userId == null) return const NullDiscardLog();
  return SqliteDiscardLog(key: 'gym', namespace: userId);
});

/// What screens use. Writes land here and return immediately.
final gymRepositoryProvider = Provider<GymRepository>((ref) {
  final store = ref.watch(gymLocalStoreProvider);
  final sync = ref.watch(gymSyncServiceProvider);
  if (store == null || sync == null) {
    return ref.watch(remoteGymRepositoryProvider);
  }
  return LocalFirstGymRepository(
    store: store,
    sync: sync,
    remote: ref.watch(remoteGymRepositoryProvider),
    queue: ref.watch(gymSyncEngineProvider.notifier),
  );
});

/// The local-first repository, for the few callers that need its cache-only
/// read as well as the interface.
final localFirstGymRepositoryProvider = Provider<LocalFirstGymRepository?>((
  ref,
) {
  final repository = ref.watch(gymRepositoryProvider);
  return repository is LocalFirstGymRepository ? repository : null;
});
