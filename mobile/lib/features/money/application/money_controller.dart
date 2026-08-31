import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/network/network_failure.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/money/application/money_sync_engine.dart';
import 'package:luqa/features/money/data/money_providers.dart';
import 'package:luqa/features/money/data/money_repository.dart';
import 'package:luqa/features/money/domain/money_models.dart';

/// "Now" as the money tab sees it, so tests can pin the day a bill defaults to.
final moneyNowProvider = Provider<DateTime>((ref) => DateTime.now());

final moneyControllerProvider =
    NotifierProvider<MoneyController, MoneyState>(MoneyController.new);

class MoneyState {
  const MoneyState({
    this.overview,
    this.expenses = const [],
    this.nextCursor,
    this.isLoading = true,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.pendingWrites = 0,
    this.discarded = const [],
    this.error,
    this.feedError,
  });

  final MoneyOverview? overview;

  /// The bill feed, newest first, as far as it has been loaded.
  final List<Expense> expenses;

  /// Null once the whole history is on screen.
  final String? nextCursor;

  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;

  /// Bills, people and paybacks recorded here that the server has not
  /// acknowledged yet. Nothing waits on them; the count exists so the screen
  /// can say so quietly.
  final int pendingWrites;

  /// Changes the server refused outright, which this device has given up on.
  /// The user has to be told; there is nothing to retry.
  final List<DiscardedWrite> discarded;

  /// Set only when there is nothing to show at all.
  final String? error;

  /// The feed failed but the balances did not — worth a retry line under the
  /// list rather than an error page over the whole tab.
  final String? feedError;

  bool get hasMore => nextCursor != null;

  MoneyState copyWith({
    MoneyOverview? overview,
    List<Expense>? expenses,
    String? nextCursor,
    bool clearCursor = false,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    int? pendingWrites,
    List<DiscardedWrite>? discarded,
    String? error,
    bool clearError = false,
    String? feedError,
    bool clearFeedError = false,
  }) => MoneyState(
    overview: overview ?? this.overview,
    expenses: expenses ?? this.expenses,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    isLoading: isLoading ?? this.isLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    pendingWrites: pendingWrites ?? this.pendingWrites,
    discarded: discarded ?? this.discarded,
    error: clearError ? null : error ?? this.error,
    feedError: clearFeedError ? null : feedError ?? this.feedError,
  );
}

class MoneyController extends Notifier<MoneyState> {
  late MoneyRepository _repository;
  int _generation = 0;

  @override
  MoneyState build() {
    _repository = ref.watch(moneyRepositoryProvider);

    // Local work is already on screen; this is about what came back. Once a
    // round of the queue reaches the server, its rows are canonical there, so
    // pull them down and drop the local overlay.
    ref.listen(moneySyncEngineProvider, (previous, next) {
      if (!ref.mounted) return;
      if (next.pending != state.pendingWrites ||
          next.discarded != state.discarded) {
        state = state.copyWith(
          pendingWrites: next.pending,
          discarded: next.discarded,
        );
      }
      if (previous != null && next.rounds > previous.rounds) {
        unawaited(load(refresh: true));
      }
    });

    Future<void>.microtask(() => load(allowCache: true));
    return const MoneyState();
  }

  Future<void> load({bool refresh = false, bool allowCache = false}) async {
    final generation = ++_generation;
    state = state.copyWith(
      isLoading: state.overview == null,
      isRefreshing: refresh && state.overview != null,
      clearError: true,
    );

    if (allowCache) {
      // Painting the phone's copy first is what makes opening the tab feel
      // like opening a local app rather than a web page.
      try {
        final local = ref.read(localFirstMoneyRepositoryProvider);
        final cached =
            await local?.cachedOverview() ?? await local?.queuedOverview();
        final cachedExpenses = await local?.cachedExpenses();
        if (!ref.mounted || generation != _generation) return;
        if (cached != null) {
          state = state.copyWith(
            overview: cached,
            expenses: cachedExpenses ?? state.expenses,
            isLoading: false,
            isRefreshing: true,
          );
        }
      } on Object {
        // A broken read cache must never block a fresh load.
      }
    }

    MoneyOverview? overview;
    try {
      overview = await _repository.loadOverview();
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        overview: overview,
        isLoading: false,
        clearError: true,
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      // Something already on screen beats an error page: the repository only
      // throws once it has no cached copy either.
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: state.overview != null
            ? null
            : describeNetworkFailure(error, whileDoing: 'loading your money'),
        clearError: state.overview != null,
      );
      return;
    }

    // The feed is a second request, and it failing is a smaller event than the
    // balances failing: the headline is already correct without it.
    try {
      final page = await _repository.loadExpenses();
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        expenses: page.expenses,
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        isRefreshing: false,
        clearFeedError: true,
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        isRefreshing: false,
        feedError: describeNetworkFailure(error, whileDoing: 'loading bills'),
      );
    }
  }

  /// The user has read the notice about a change that could not be saved.
  Future<void> acknowledgeDiscarded() =>
      ref.read(moneySyncEngineProvider.notifier).acknowledgeDiscarded();

  /// One gesture, one meaning: catch up with the server. Sending first means
  /// the reload that follows cannot overwrite local work with an older copy.
  Future<void> refresh() async {
    await ref.read(moneySyncEngineProvider.notifier).sync();
    if (!ref.mounted) return;
    await load(refresh: true);
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true, clearFeedError: true);
    try {
      final page = await _repository.loadExpenses(cursor: cursor);
      if (!ref.mounted) return;
      // Ids rather than a blind append: a refresh may have landed underneath
      // this request and already carry some of what came back.
      final seen = {for (final expense in state.expenses) expense.id};
      state = state.copyWith(
        expenses: [
          ...state.expenses,
          for (final expense in page.expenses)
            if (!seen.contains(expense.id)) expense,
        ],
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        isLoadingMore: false,
      );
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        feedError: describeNetworkFailure(error, whileDoing: 'loading bills'),
      );
    }
  }

  /// Records a bill and puts it on screen immediately. Returns false only when
  /// the phone itself could not record it.
  Future<bool> saveExpense({String? id, required ExpenseWrite write}) =>
      _write('saving the expense', () async {
        final expense = id == null
            ? await _repository.createExpense(write: write)
            : await _repository.updateExpense(id, write);
        _applyExpenseLocally(expense);
      });

  Future<bool> deleteExpense(String id) =>
      _write('deleting the expense', () async {
        await _repository.deleteExpense(id);
        if (!ref.mounted) return;
        state = state.copyWith(
          expenses: [
            for (final expense in state.expenses)
              if (expense.id != id) expense,
          ],
        );
      });

  Future<bool> settleUp(SettlementWrite write) =>
      _write('recording the payback', () async {
        await _repository.createSettlement(write: write);
      });

  Future<Person?> addPerson(PersonWrite write) async {
    Person? person;
    final ok = await _write('adding the person', () async {
      person = await _repository.createPerson(write: write);
    });
    return ok ? person : null;
  }

  Future<bool> updatePerson({
    required String id,
    String? name,
    int? colorValue,
    String? emoji,
    bool clearEmoji = false,
    int? defaultPercent,
    bool clearDefaultPercent = false,
    bool? archived,
  }) => _write('saving the person', () async {
    await _repository.updatePerson(
      id: id,
      name: name,
      colorValue: colorValue,
      emoji: emoji,
      clearEmoji: clearEmoji,
      defaultPercent: defaultPercent,
      clearDefaultPercent: clearDefaultPercent,
      archived: archived,
    );
  });

  Future<bool> deletePerson(String id) =>
      _write('removing the person', () => _repository.deletePerson(id));

  Future<PersonGroup?> addGroup(GroupWrite write) async {
    PersonGroup? group;
    final ok = await _write('adding the group', () async {
      group = await _repository.createGroup(write: write);
    });
    return ok ? group : null;
  }

  Future<bool> updateGroup({
    required String id,
    String? name,
    int? colorValue,
    String? emoji,
    bool clearEmoji = false,
    List<String>? memberIds,
    bool? archived,
  }) => _write('saving the group', () async {
    await _repository.updateGroup(
      id: id,
      name: name,
      colorValue: colorValue,
      emoji: emoji,
      clearEmoji: clearEmoji,
      memberIds: memberIds,
      archived: archived,
    );
  });

  Future<bool> deleteGroup(String id) =>
      _write('removing the group', () => _repository.deleteGroup(id));

  /// Every write follows the same shape: do it locally, re-read what the
  /// device now believes, and name the failure if the phone itself refused.
  Future<bool> _write(String doing, Future<void> Function() action) async {
    try {
      await action();
      if (!ref.mounted) return true;
      await _resync();
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          error: describeNetworkFailure(error, whileDoing: doing),
        );
      }
      return false;
    }
  }

  /// Re-reads the overview from the device so the balances on screen include
  /// the write that just landed in the queue. No network is involved.
  Future<void> _resync() async {
    final local = ref.read(localFirstMoneyRepositoryProvider);
    if (local == null) return;
    final overview = await local.cachedOverview();
    if (!ref.mounted || overview == null) return;
    state = state.copyWith(overview: overview, clearError: true);
  }

  void _applyExpenseLocally(Expense expense) {
    if (!ref.mounted) return;
    final without = [
      for (final item in state.expenses)
        if (item.id != expense.id) item,
    ];
    state = state.copyWith(
      expenses: [expense, ...without]..sort((left, right) {
        final byDate = right.dateKey.compareTo(left.dateKey);
        return byDate != 0 ? byDate : right.createdAt.compareTo(left.createdAt);
      }),
    );
  }
}
