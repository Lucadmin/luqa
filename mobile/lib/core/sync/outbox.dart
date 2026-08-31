import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  /// What this write was, in the user's own terms — "the €42 dinner with
  /// Mira", "Tuesday's workout".
  ///
  /// Only ever shown when the write has to be abandoned, which is the one
  /// moment the user needs to know what they will have to enter again. A
  /// subject id tells them nothing.
  String describe();

  Map<String, Object?> toJson();
}

/// A write this device gave up on.
///
/// Distinct from a queue that is merely stuck: the server understood this one
/// and refused it, so no amount of retrying will land it and the user's change
/// is gone. That is a fact about the past, and unlike a stuck queue it does
/// not stop being true when the network comes back — so it is kept until the
/// user has actually been told.
@immutable
class DiscardedWrite {
  const DiscardedWrite({
    required this.description,
    required this.reason,
    required this.discardedAt,
  });

  /// What the user did, from [PendingMutation.describe].
  final String description;

  /// Why it can never land, as the server explained it.
  final String reason;

  final DateTime discardedAt;

  Map<String, Object?> toJson() => {
    'description': description,
    'reason': reason,
    'discardedAt': discardedAt.toUtc().toIso8601String(),
  };

  static DiscardedWrite? fromJson(Map<String, Object?> json) {
    final discardedAt = DateTime.tryParse(json['discardedAt'] as String? ?? '');
    final description = json['description'];
    final reason = json['reason'];
    if (discardedAt == null || description is! String || reason is! String) {
      return null;
    }
    return DiscardedWrite(
      description: description,
      reason: reason,
      discardedAt: discardedAt.toLocal(),
    );
  }
}

/// Durable home for the writes that were abandoned.
///
/// Durable because a queue very often drains on the resume that follows a
/// spell offline, and the phone can be put straight back in a pocket. A notice
/// that only lives in memory would be the second time that change vanished
/// without anybody being told.
abstract interface class DiscardLog {
  Future<List<DiscardedWrite>> read();

  Future<void> write(List<DiscardedWrite> entries);
}

class SharedPreferencesDiscardLog implements DiscardLog {
  SharedPreferencesDiscardLog({
    required String key,
    required String namespace,
    SharedPreferencesAsync? preferences,
  }) : _store = _JsonListStore(
         key:
             'luqa.discarded.$key.v1.'
             '${base64Url.encode(utf8.encode(namespace))}',
         preferences: preferences,
       );

  /// Enough to explain what went missing; a log nobody is reading is not worth
  /// growing without bound.
  static const _limit = 20;

  final _JsonListStore _store;

  @override
  Future<List<DiscardedWrite>> read() async => [
    for (final item in await _store.read()) ?DiscardedWrite.fromJson(item),
  ];

  @override
  Future<void> write(List<DiscardedWrite> entries) => _store.write([
    for (final entry in entries.take(_limit)) entry.toJson(),
  ]);
}

/// A log that keeps nothing, for signed-out and test contexts.
class NullDiscardLog implements DiscardLog {
  const NullDiscardLog();

  @override
  Future<List<DiscardedWrite>> read() async => const [];

  @override
  Future<void> write(List<DiscardedWrite> entries) async {}
}

/// Durable home for a queue.
abstract interface class Outbox<T extends PendingMutation> {
  Future<List<T>> read();

  Future<void> write(List<T> queue);
}

/// A namespaced list of JSON objects on disk, which is all either durable
/// store here actually needs.
class _JsonListStore {
  _JsonListStore({required String key, SharedPreferencesAsync? preferences})
    // ignore: prefer_initializing_formals
    : _key = key,
      _injected = preferences;

  final String _key;
  final SharedPreferencesAsync? _injected;

  // Deferred: building the store is not the same as needing the platform
  // channel, and a provider that merely exists must not require one.
  late final SharedPreferencesAsync _preferences =
      _injected ?? SharedPreferencesAsync();

  Future<List<Map<String, Object?>>> read() async {
    final encoded = await _preferences.getString(_key);
    if (encoded == null) return const [];
    try {
      return [
        for (final item in jsonDecode(encoded) as List<Object?>)
          item! as Map<String, Object?>,
      ];
    } on Object {
      // Unreadable: dropping it loses records, but keeping it would block
      // every future write behind something nothing can parse.
      await _preferences.remove(_key);
      return const [];
    }
  }

  Future<void> write(List<Map<String, Object?>> items) async {
    if (items.isEmpty) {
      await _preferences.remove(_key);
      return;
    }
    await _preferences.setString(_key, jsonEncode(items));
  }
}

class SharedPreferencesOutbox<T extends PendingMutation> implements Outbox<T> {
  SharedPreferencesOutbox({
    required String key,
    required String namespace,
    required T? Function(Map<String, Object?> json) decode,
    SharedPreferencesAsync? preferences,
    // ignore: prefer_initializing_formals
  }) : _decode = decode,
       _store = _JsonListStore(
         key:
             'luqa.outbox.$key.v1.'
             '${base64Url.encode(utf8.encode(namespace))}',
         preferences: preferences,
       );

  final T? Function(Map<String, Object?> json) _decode;
  final _JsonListStore _store;

  @override
  Future<List<T>> read() async => [
    for (final item in await _store.read()) ?_decode(item),
  ];

  @override
  Future<void> write(List<T> queue) =>
      _store.write([for (final pending in queue) pending.toJson()]);
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
