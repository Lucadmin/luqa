import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/core/network/network_failure.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa_api/api.dart' as api;

class SyncState {
  const SyncState({
    this.pending = 0,
    this.isSyncing = false,
    this.error,
    this.rounds = 0,
    this.discarded = const [],
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

  /// Writes this device gave up on, newest first.
  ///
  /// Deliberately not folded into [error]: that describes a queue that is
  /// stuck right now and clears itself the moment it unsticks, which is
  /// exactly the wrong lifetime for "something you entered is gone". These
  /// stay until the user acknowledges them.
  final List<DiscardedWrite> discarded;

  bool get hasPendingWork => pending > 0;

  bool get hasDiscardedWork => discarded.isNotEmpty;

  SyncState copyWith({
    int? pending,
    bool? isSyncing,
    String? error,
    bool clearError = false,
    int? rounds,
    List<DiscardedWrite>? discarded,
  }) => SyncState(
    pending: pending ?? this.pending,
    isSyncing: isSyncing ?? this.isSyncing,
    error: clearError ? null : error ?? this.error,
    rounds: rounds ?? this.rounds,
    discarded: discarded ?? this.discarded,
  );
}

/// The half of a sync engine that is the same whatever is being synced:
/// holding a durable queue, draining it head-first, and knowing the difference
/// between a network that is down and a server that said no.
///
/// A feature mixes this into its own [Notifier] and supplies the three things
/// that are actually domain knowledge — how to fold a new mutation into the
/// queue, how to send one, and which outbox to keep it in.
mixin SyncQueue<T extends PendingMutation> on Notifier<SyncState>
    implements MutationQueue<T> {
  /// Retry schedule for a queue the network is refusing. It settles at a few
  /// minutes: nothing is lost by waiting, and a phone with no signal must not
  /// spend its battery finding that out.
  static const backoff = [
    Duration(seconds: 2),
    Duration(seconds: 8),
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 5),
  ];

  Outbox<T>? _outbox;
  DiscardLog? _discardLog;
  List<T> _queue = const [];
  List<DiscardedWrite> _discarded = const [];
  Future<void>? _ready;
  Future<void>? _draining;
  Timer? _retry;
  int _failures = 0;

  /// Called from the subclass's `build`. Rebuilding — which is what signing in
  /// or out does — starts again against the new user's queue.
  void adoptOutbox(Outbox<T> outbox, DiscardLog discardLog) {
    _retry?.cancel();
    _outbox = outbox;
    _discardLog = discardLog;
    _queue = const [];
    _discarded = const [];
    _failures = 0;
    _ready = _restore();
    ref.onDispose(() => _retry?.cancel());
  }

  /// Puts [mutation] into [queue], folding it into whatever is already there
  /// for the same row.
  List<T> fold(List<T> queue, T mutation);

  /// Performs one mutation against the server. Throwing means it did not land.
  Future<void> send(T mutation);

  @override
  Future<void> get ready => _ready ??= _restore();

  @override
  List<T> get pending => _queue;

  /// Lets [send] rewrite what is still queued — needed when the server answers
  /// a create with an id other than the one this device made up.
  Future<void> rewriteQueue(List<T> Function(List<T> queue) rewrite) async {
    _queue = rewrite(_queue);
    await _outbox?.write(_queue);
  }

  @override
  Future<void> enqueue(T mutation, {bool sendNow = true}) async {
    await ready;
    if (!ref.mounted) return;
    _queue = fold(_queue, mutation);
    // The count is the user-visible fact, so it moves before the write to disk
    // rather than after it.
    state = state.copyWith(pending: _queue.length, clearError: true);
    await _outbox?.write(_queue);
    // A fresh write deserves an immediate attempt, whatever the backoff was
    // waiting for.
    _failures = 0;
    _retry?.cancel();
    if (sendNow) unawaited(sync());
  }

  /// Drains the queue, oldest first. Safe to call at any time: two callers
  /// never drain at once.
  ///
  /// A drain already in flight is awaited rather than duplicated — but if it
  /// finishes with work still queued, one more attempt is made. Otherwise a
  /// retry that arrives while a doomed request is still timing out would be
  /// answered by that request's failure and never actually retry anything.
  @override
  Future<void> sync() async {
    final running = _draining;
    if (running != null) {
      await running;
      // Only start a follow-up when nothing else already has: with several
      // callers waiting on one drain, exactly one of them takes the next turn.
      if (!ref.mounted || _queue.isEmpty || _draining != null) return;
    }
    final future = _drain();
    _draining = future;
    await future.whenComplete(() {
      if (identical(_draining, future)) _draining = null;
    });
  }

  Future<void> _restore() async {
    final outbox = _outbox;
    if (outbox == null) return;
    List<T> stored;
    List<DiscardedWrite> abandoned;
    try {
      stored = await outbox.read();
    } on Object {
      // An unreadable queue is bad, but refusing to start is worse: the app
      // still works, it just has nothing older to send.
      stored = const [];
    }
    try {
      abandoned = await _discardLog?.read() ?? const [];
    } on Object {
      abandoned = const [];
    }
    if (!ref.mounted) return;
    _queue = stored;
    _discarded = abandoned;
    // A write abandoned on the drain that followed the last resume has to
    // still be reportable on the next launch — the phone can go back in a
    // pocket the moment the queue empties.
    if (stored.isEmpty && abandoned.isEmpty) return;
    state = state.copyWith(pending: _queue.length, discarded: _discarded);
    if (stored.isEmpty) return;
    unawaited(sync());
  }

  Future<void> _drain() async {
    await ready;
    // Signing out disposes the engine while a request may still be in flight.
    // Everything below therefore checks before publishing state; the queue on
    // disk is already correct either way.
    if (!ref.mounted || _queue.isEmpty) return;
    state = state.copyWith(isSyncing: true);
    var reachedServer = false;

    try {
      // Strictly head-first: a save must never overtake the create it refers
      // to, so one refusal holds everything behind it.
      while (_queue.isNotEmpty) {
        final head = _queue.first;
        try {
          await send(head);
          if (!ref.mounted) return;
          reachedServer = true;
          await _drop(head);
          _failures = 0;
        } on Object catch (error) {
          if (!ref.mounted) return;
          if (isPermanent(error)) {
            // Repeating this will fail the same way for ever. Dropping it lets
            // the writes behind it through; anything that depended on it fails
            // next and is dropped in turn, which is how the queue heals.
            //
            // The user's change is gone, though, so it is recorded rather than
            // merely logged. Putting it in `error` here would be worse than
            // saying nothing: the drain clears that field as soon as the queue
            // empties, which is moments later.
            reachedServer = true;
            await _drop(head);
            if (!ref.mounted) return;
            await _recordDiscard(head, error);
            if (!ref.mounted) return;
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

  /// Keeps an abandoned write where the user can be told about it.
  Future<void> _recordDiscard(T mutation, Object error) async {
    final entry = DiscardedWrite(
      description: mutation.describe(),
      reason: describeNetworkFailure(error, whileDoing: 'saving it'),
      discardedAt: DateTime.now(),
    );
    _discarded = [entry, ..._discarded];
    if (ref.mounted) state = state.copyWith(discarded: _discarded);
    await _discardLog?.write(_discarded);
  }

  /// The user has seen the notice. Forgetting it is the only thing left to do
  /// — the write itself is long gone.
  Future<void> acknowledgeDiscarded() async {
    _discarded = const [];
    if (ref.mounted) state = state.copyWith(discarded: _discarded);
    await _discardLog?.write(const []);
  }

  Future<void> _drop(T mutation) async {
    _queue = [
      for (final pending in _queue)
        if (!identical(pending, mutation)) pending,
    ];
    if (ref.mounted) state = state.copyWith(pending: _queue.length);
    await _outbox?.write(_queue);
  }

  void _scheduleRetry(Object error) {
    // A dead session is not something a timer fixes; the next sign-in kicks
    // the queue instead.
    if (error is SessionExpiredException) return;
    final delay = backoff[_failures.clamp(0, backoff.length - 1)];
    _failures++;
    _retry?.cancel();
    _retry = Timer(delay, () {
      if (ref.mounted) unawaited(sync());
    });
  }

  /// True when repeating the request cannot change the answer: the server
  /// understood it and said no. Transport failures, timeouts and server faults
  /// are all worth another try.
  static bool isPermanent(Object error) {
    if (error is! api.ApiException) return false;
    // The generated client reports transport failures as a synthetic 400 with
    // the real cause attached, which is the opposite of a considered refusal.
    if (error.innerException != null) return false;
    if (error.code == 408 || error.code == 429) return false;
    return error.code >= 400 && error.code < 500;
  }
}
