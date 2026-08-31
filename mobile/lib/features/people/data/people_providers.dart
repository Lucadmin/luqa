import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/people/data/people_repository.dart';
import 'package:luqa/features/money/application/money_sync_engine.dart';
import 'package:luqa/features/money/data/money_providers.dart';
import 'package:luqa/features/people/data/local_first_people_repository.dart';
import 'package:luqa/features/people/data/people_sync_service.dart';
import 'package:luqa/features/people/data/remote_people_repository.dart';

/// The network. The sync engine talks to this directly; screens do not.
final remotePeopleRepositoryProvider = Provider<PeopleRepository>(
  (ref) => RemotePeopleRepository(ref.watch(luqaApiProvider)),
);

final peopleSyncServiceProvider = Provider<PeopleSyncService?>((ref) {
  final store = ref.watch(moneyLocalStoreProvider);
  if (store == null) return null;
  return PeopleSyncService(client: ref.watch(luqaApiProvider), store: store);
});

/// What the People screens read and write.
///
/// Local-first when there is an account to file rows under, and the network
/// directly when there is not — signed out, there is nothing to cache and
/// nowhere to cache it.
///
/// The store and the queue are Money's. There is one `person` row and one
/// queue carrying both people and the bills that reference them, because a
/// person create and an expense create have to replay in the order they
/// happened.
final peopleRepositoryProvider = Provider<PeopleRepository>((ref) {
  final store = ref.watch(moneyLocalStoreProvider);
  final sync = ref.watch(peopleSyncServiceProvider);
  if (store == null || sync == null) {
    return ref.watch(remotePeopleRepositoryProvider);
  }
  return LocalFirstPeopleRepository(
    store: store,
    sync: sync,
    queue: ref.watch(moneySyncEngineProvider.notifier),
  );
});
