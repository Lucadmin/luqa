import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/habits/application/habits_sync_engine.dart';
import 'package:luqa/features/habits/data/habits_local_store.dart';
import 'package:luqa/features/habits/data/habits_outbox.dart';
import 'package:luqa/features/habits/data/habits_repository.dart';
import 'package:luqa/features/habits/data/habits_sync_service.dart';
import 'package:luqa/features/habits/data/local_first_habits_repository.dart';
import 'package:luqa/features/habits/data/remote_habits_repository.dart';

/// Everything device-local is filed under the signed-in user, so switching
/// accounts on one phone never shows or sends the other's habits.
final _namespaceProvider = Provider<String?>(
  (ref) => ref.watch(authControllerProvider).value?.user?.id,
);

/// The network. The sync engine talks to this directly; screens do not.
final remoteHabitsRepositoryProvider = Provider<HabitsRepository>(
  (ref) => RemoteHabitsRepository(ref.watch(luqaApiProvider)),
);

/// This device's own habit rows. Null while signed out: there is no account to
/// file them under.
final habitsLocalStoreProvider = Provider<HabitsLocalStore?>((ref) {
  final userId = ref.watch(_namespaceProvider);
  return userId == null ? null : HabitsLocalStore(namespace: userId);
});

final habitsSyncServiceProvider = Provider<HabitsSyncService?>((ref) {
  final store = ref.watch(habitsLocalStoreProvider);
  if (store == null) return null;
  return HabitsSyncService(client: ref.watch(luqaApiProvider), store: store);
});

final habitsOutboxProvider = Provider<Outbox<HabitMutation>>((ref) {
  final userId = ref.watch(_namespaceProvider);
  // Queueing a write with nobody to send it as would strand it for ever.
  if (userId == null) return const NullOutbox();
  return SqliteHabitsOutbox(namespace: userId);
});

/// Where an abandoned write is recorded so the user can still be told about
/// it — including after a relaunch, since a queue often drains on the resume
/// that precedes the phone going back in a pocket.
final habitsDiscardLogProvider = Provider<DiscardLog>((ref) {
  final userId = ref.watch(_namespaceProvider);
  if (userId == null) return const NullDiscardLog();
  return SqliteDiscardLog(key: 'habits', namespace: userId);
});

/// What screens use. Writes land here and return immediately.
final habitsRepositoryProvider = Provider<HabitsRepository>((ref) {
  final store = ref.watch(habitsLocalStoreProvider);
  final sync = ref.watch(habitsSyncServiceProvider);
  if (store == null || sync == null) {
    return ref.watch(remoteHabitsRepositoryProvider);
  }
  return LocalFirstHabitsRepository(
    store: store,
    sync: sync,
    queue: ref.watch(habitsSyncEngineProvider.notifier),
  );
});

/// The local-first repository, for the callers that need its pull and the
/// account boundaries it learned from the last sync as well as the interface.
final localFirstHabitsRepositoryProvider =
    Provider<LocalFirstHabitsRepository?>((ref) {
      final repository = ref.watch(habitsRepositoryProvider);
      return repository is LocalFirstHabitsRepository ? repository : null;
    });
