import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/today/application/sync_engine.dart';
import 'package:luqa/features/today/data/local_first_today_repository.dart';
import 'package:luqa/features/today/data/outbox.dart';
import 'package:luqa/features/today/data/remote_today_repository.dart';
import 'package:luqa/features/today/data/today_repository.dart';

/// Everything device-local is filed under the signed-in user, so switching
/// accounts on one phone never shows or sends the other's rows.
final _namespaceProvider = Provider<String?>(
  (ref) => ref.watch(authControllerProvider).value?.user?.id,
);

/// The network, and the read cache that lets a cold start paint before it
/// answers. The sync engine talks to this directly; screens do not.
final remoteTodayRepositoryProvider = Provider<RemoteTodayRepository>((ref) {
  final userId = ref.watch(_namespaceProvider);
  return RemoteTodayRepository(
    client: ref.watch(luqaApiProvider),
    cache: SharedPreferencesTimelineCache(namespace: userId ?? 'signed-out'),
  );
});

final outboxProvider = Provider<Outbox<TimelineMutation>>((ref) {
  final userId = ref.watch(_namespaceProvider);
  // Queueing a write with nobody to send it as would strand it for ever.
  if (userId == null) return const NullOutbox();
  return SharedPreferencesOutbox(
    key: 'timeline',
    namespace: userId,
    decode: TimelineMutation.fromJson,
  );
});

/// Where an abandoned write is recorded so the user can still be told about
/// it — including after a relaunch, since a queue often drains on the resume
/// that precedes the phone going back in a pocket.
final discardLogProvider = Provider<DiscardLog>((ref) {
  final userId = ref.watch(_namespaceProvider);
  if (userId == null) return const NullDiscardLog();
  return SharedPreferencesDiscardLog(key: 'timeline', namespace: userId);
});

/// What screens use. Writes land here and return immediately.
final todayRepositoryProvider = Provider<TodayRepository>((ref) {
  return LocalFirstTodayRepository(
    remote: ref.watch(remoteTodayRepositoryProvider),
    queue: ref.watch(syncEngineProvider.notifier),
  );
});
