import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:luqa/core/storage/legacy_preferences.dart';
import 'package:luqa/core/storage/luqa_store.dart';

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

/// Durable home for a queue.
abstract interface class Outbox<T extends PendingMutation> {
  Future<List<T>> read();

  Future<void> write(List<T> queue);
}

/// The rows of one durable list, which is all either store here actually
/// needs from the database.
///
/// Rows rather than one blob is the whole gain: a record that will not parse
/// is skipped on its own, where an unreadable JSON array took the entire
/// queue with it, and a rewrite is a transaction rather than a file that can
/// be caught half-written.
class _RecordList {
  _RecordList({
    required this.namespace,
    required this.collection,
    LuqaStore? store,
  }) : _store = store ?? LuqaStore.shared;

  final String namespace;
  final String collection;
  final LuqaStore _store;

  /// Anything an earlier build left in shared preferences, moved across before
  /// the first read can conclude the queue is empty.
  late final Future<void> _migrated = LegacyPreferences.migrate(
    _store,
    namespace,
  );

  Future<List<Map<String, Object?>>> read() async {
    await _migrated;
    final rows = await _store.readRecords(
      namespace: namespace,
      collection: collection,
    );
    final items = <Map<String, Object?>>[];
    for (final row in rows) {
      try {
        items.add(jsonDecode(row)! as Map<String, Object?>);
      } on Object {
        // One unreadable row is one lost write, not a lost queue.
        continue;
      }
    }
    return items;
  }

  Future<void> write(List<Map<String, Object?>> items) async {
    await _migrated;
    await _store.replaceRecords(
      namespace: namespace,
      collection: collection,
      values: [for (final item in items) jsonEncode(item)],
    );
  }
}

class SqliteDiscardLog implements DiscardLog {
  SqliteDiscardLog({
    required String key,
    required String namespace,
    LuqaStore? store,
  }) : _records = _RecordList(
         namespace: namespace,
         collection: 'discarded.$key',
         store: store,
       );

  /// Enough to explain what went missing; a log nobody is reading is not worth
  /// growing without bound.
  static const _limit = 20;

  final _RecordList _records;

  @override
  Future<List<DiscardedWrite>> read() async => [
    for (final item in await _records.read()) ?DiscardedWrite.fromJson(item),
  ];

  @override
  Future<void> write(List<DiscardedWrite> entries) => _records.write([
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

class SqliteOutbox<T extends PendingMutation> implements Outbox<T> {
  SqliteOutbox({
    required String key,
    required String namespace,
    required T? Function(Map<String, Object?> json) decode,
    LuqaStore? store,
    // ignore: prefer_initializing_formals
  }) : _decode = decode,
       _records = _RecordList(
         namespace: namespace,
         collection: 'outbox.$key',
         store: store,
       );

  final T? Function(Map<String, Object?> json) _decode;
  final _RecordList _records;

  @override
  Future<List<T>> read() async => [
    for (final item in await _records.read()) ?_decode(item),
  ];

  @override
  Future<void> write(List<T> queue) =>
      _records.write([for (final pending in queue) pending.toJson()]);
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

  /// Records a mutation and, unless told otherwise, starts sending.
  ///
  /// [sendNow] is how a caller says "there is more to this write than the
  /// queue entry". A repository writes the row itself straight after
  /// queueing, and that write yields — long enough for a drain to send this
  /// mutation and rewrite the queue behind it. A caller that is mid-write has
  /// to be allowed to finish before any of that happens.
  Future<void> enqueue(T mutation, {bool sendNow = true});

  /// Sends whatever is queued. Safe to call at any time; two callers never
  /// drain at once.
  Future<void> sync();
}
