import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/core/network/network_failure.dart';
import 'package:luqa/features/today/data/outbox.dart';
import 'package:luqa/features/today/data/remote_today_repository.dart';
import 'package:luqa/features/today/data/today_providers.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa_api/api.dart' as api;

class SyncState {
  const SyncState({
    this.pending = 0,
    this.isSyncing = false,
    this.error,
    this.rounds = 0,
  });

  /// Writes made on this device that the server has not acknowledged.
  final int pending;

  final bool isSyncing;

  /// Set only when the queue is stuck for a reason worth naming. A single
  /// failed attempt that will be retried says nothing.
  final String? error;

  /// Bumped whenever a drain reaches the server. Screens watch it to pull the
  /// canonical rows back down once their local copies have landed.
  final int rounds;

  bool get hasPendingWork => pending > 0;

  SyncState copyWith({
    int? pending,
    bool? isSyncing,
    String? error,
    bool clearError = false,
    int? rounds,
  }) => SyncState(
    pending: pending ?? this.pending,
    isSyncing: isSyncing ?? this.isSyncing,
    error: clearError ? null : error ?? this.error,
    rounds: rounds ?? this.rounds,
  );
}

/// Sends what the device has already done.
///
/// It is deliberately not tied to a screen: a block logged on the way into a
/// tunnel has to reach the server even if the timeline was closed long ago, so
/// this provider is never auto-disposed.
final syncEngineProvider = NotifierProvider<SyncEngine, SyncState>(
  SyncEngine.new,
);

class SyncEngine extends Notifier<SyncState> implements MutationQueue {
  /// Retry schedule for a queue the network is refusing. It settles at a few
  /// minutes: nothing is lost by waiting, and a phone with no signal must not
  /// spend its battery finding that out.
  static const _backoff = [
    Duration(seconds: 2),
    Duration(seconds: 8),
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 5),
  ];

  // Reassigned rather than final: signing in or out rebuilds this notifier in
  // place, and it has to pick up the new user's queue.
  late Outbox _outbox;

  /// Read at the moment of sending rather than held: an engine whose queue is
  /// empty should never cause a network stack to be built at all.
  RemoteTodayRepository get _remote => ref.read(remoteTodayRepositoryProvider);

  List<PendingMutation> _queue = const [];
  Future<void>? _ready;
  Future<void>? _draining;
  Timer? _retry;
  int _failures = 0;

  @override
  SyncState build() {
    _outbox = ref.watch(outboxProvider);
    ref.onDispose(() => _retry?.cancel());
    _retry?.cancel();
    _queue = const [];
    _failures = 0;
    _ready = _restore();
    return const SyncState();
  }

  @override
  Future<void> get ready => _ready ??= _restore();

  @override
  List<PendingMutation> get pending => _queue;

  Future<void> _restore() async {
    List<PendingMutation> stored;
    try {
      stored = await _outbox.read();
    } on Object {
      // An unreadable queue is bad, but refusing to start is worse: the app
      // still works, it just has nothing older to send.
      stored = const [];
    }
    if (!ref.mounted) return;
    _queue = stored;
    if (stored.isEmpty) return;
    state = state.copyWith(pending: _queue.length);
    unawaited(sync());
  }

  @override
  Future<void> enqueue(PendingMutation mutation) async {
    await ready;
    if (!ref.mounted) return;
    _queue = foldInto(_queue, mutation);
    // The count is the user-visible fact, so it moves before the write to disk
    // rather than after it.
    state = state.copyWith(pending: _queue.length, clearError: true);
    await _outbox.write(_queue);
    // A fresh write deserves an immediate attempt, whatever the backoff was
    // waiting for.
    _failures = 0;
    _retry?.cancel();
    unawaited(sync());
  }

  /// Drains the queue, oldest first. Safe to call at any time: a drain already
  /// in flight is returned rather than started twice.
  Future<void> sync() {
    final running = _draining;
    if (running != null) return running;
    final future = _drain();
    _draining = future;
    return future.whenComplete(() {
      if (identical(_draining, future)) _draining = null;
    });
  }

  Future<void> _drain() async {
    await ready;
    // Signing out disposes this engine while a request may still be in flight.
    // Everything below therefore checks before publishing state; the queue on
    // disk is already correct either way.
    if (!ref.mounted || _queue.isEmpty) return;
    state = state.copyWith(isSyncing: true);
    var reachedServer = false;

    try {
      // Strictly head-first: a delete must never overtake the create it
      // refers to, so one refusal holds everything behind it.
      while (_queue.isNotEmpty) {
        final head = _queue.first;
        try {
          await _send(head);
          if (!ref.mounted) return;
          reachedServer = true;
          await _drop(head);
          _failures = 0;
        } on Object catch (error) {
          if (!ref.mounted) return;
          if (_isPermanent(error)) {
            // Repeating this will fail the same way for ever. Dropping it lets
            // the writes behind it through; anything that depended on it fails
            // next and is dropped in turn, which is how the queue heals.
            reachedServer = true;
            await _drop(head);
            if (!ref.mounted) return;
            state = state.copyWith(
              error: describeNetworkFailure(error, whileDoing: 'syncing'),
            );
            continue;
          }
          _scheduleRetry(error);
          return;
        }
      }
      state = state.copyWith(clearError: true);
    } finally {
      if (ref.mounted) {
        state = state.copyWith(
          isSyncing: false,
          pending: _queue.length,
          rounds: reachedServer ? state.rounds + 1 : state.rounds,
        );
      }
    }
  }

  Future<void> _send(PendingMutation mutation) async {
    switch (mutation) {
      case CreateEntry(:final entry):
        await _remote.addEntry(
          NewTimeEntry(
            id: entry.id,
            description: entry.description,
            categoryId: entry.categoryId,
            start: entry.start,
            end: entry.end,
          ),
        );
      case UpdateEntry(:final entryId, :final patch):
        await _remote.updateEntryById(entryId, patch);
      case DeleteEntry(:final entryId):
        await _remote.deleteEntry(entryId);
      case CreateCategory(:final category):
        final saved = await _remote.addCategoryWithId(category);
        // The server may have matched an existing category by name. Everything
        // still queued behind this points at the id we made up.
        if (saved.id != category.id) {
          _queue = remapCategoryId(_queue, category.id, saved.id);
          await _outbox.write(_queue);
        }
    }
  }

  Future<void> _drop(PendingMutation mutation) async {
    _queue = [
      for (final pending in _queue)
        if (!identical(pending, mutation)) pending,
    ];
    if (ref.mounted) state = state.copyWith(pending: _queue.length);
    await _outbox.write(_queue);
  }

  void _scheduleRetry(Object error) {
    // A dead session is not something a timer fixes; the next sign-in kicks
    // the queue instead.
    if (error is SessionExpiredException) return;
    final delay = _backoff[_failures.clamp(0, _backoff.length - 1)];
    _failures++;
    _retry?.cancel();
    _retry = Timer(delay, () {
      if (ref.mounted) unawaited(sync());
    });
  }

  /// True when repeating the request cannot change the answer: the server
  /// understood it and said no. Transport failures, timeouts and server faults
  /// are all worth another try.
  static bool _isPermanent(Object error) {
    if (error is! api.ApiException) return false;
    // The generated client reports transport failures as a synthetic 400 with
    // the real cause attached, which is the opposite of a considered refusal.
    if (error.innerException != null) return false;
    if (error.code == 408 || error.code == 429) return false;
    return error.code >= 400 && error.code < 500;
  }
}
