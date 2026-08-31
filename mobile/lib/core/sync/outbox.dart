import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A write that has already happened on this device and still has to reach the
/// server.
///
/// Every mutation lands in an outbox first and is answered from there
/// immediately, so nothing the user does waits on a round trip. The queue is
/// durable: a write made in a basement survives the app being killed and is
/// sent on the next launch that finds a network.
abstract interface class PendingMutation {
  /// When the user made the change, not when it was last attempted. Sorting by
  /// it keeps the replay in the order things actually happened.
  DateTime get queuedAt;

  /// The row this mutation is about, so a queue can be folded per entity.
  String get subjectId;

  Map<String, Object?> toJson();
}

/// Durable home for a queue.
abstract interface class Outbox<T extends PendingMutation> {
  Future<List<T>> read();

  Future<void> write(List<T> queue);
}

class SharedPreferencesOutbox<T extends PendingMutation> implements Outbox<T> {
  SharedPreferencesOutbox({
    required String key,
    required String namespace,
    required T? Function(Map<String, Object?> json) decode,
    SharedPreferencesAsync? preferences,
  }) : _key = 'luqa.outbox.$key.v1.${base64Url.encode(utf8.encode(namespace))}',
       // ignore: prefer_initializing_formals
       _decode = decode,
       _injected = preferences;

  final String _key;
  final T? Function(Map<String, Object?> json) _decode;
  final SharedPreferencesAsync? _injected;

  // Deferred: building the store is not the same as needing the platform
  // channel, and a provider that merely exists must not require one.
  late final SharedPreferencesAsync _preferences =
      _injected ?? SharedPreferencesAsync();

  @override
  Future<List<T>> read() async {
    final encoded = await _preferences.getString(_key);
    if (encoded == null) return const [];
    try {
      return [
        for (final item in jsonDecode(encoded) as List<Object?>)
          ?_decode(item! as Map<String, Object?>),
      ];
    } on Object {
      // Unreadable queue: dropping it loses writes, but keeping it would block
      // every future write behind a record nothing can replay.
      await _preferences.remove(_key);
      return const [];
    }
  }

  @override
  Future<void> write(List<T> queue) async {
    if (queue.isEmpty) {
      await _preferences.remove(_key);
      return;
    }
    await _preferences.setString(
      _key,
      jsonEncode([for (final pending in queue) pending.toJson()]),
    );
  }
}

/// An outbox that keeps nothing. Signed-out and test contexts use it so a
/// write is simply attempted once and forgotten.
class NullOutbox<T extends PendingMutation> implements Outbox<T> {
  const NullOutbox();

  @override
  Future<List<T>> read() async => const [];

  @override
  Future<void> write(List<T> queue) async {}
}

/// The queue, as a repository sees it. The sync engine implements it, so every
/// read and write of the outbox goes through one owner and two writers can
/// never interleave a read-modify-write.
abstract interface class MutationQueue<T extends PendingMutation> {
  /// Completes once the durable queue has been read back after a cold start.
  Future<void> get ready;

  List<T> get pending;

  Future<void> enqueue(T mutation);
}
