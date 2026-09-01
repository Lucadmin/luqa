import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/core/network/network_failure.dart';
import 'package:luqa/features/insights/domain/insights_math.dart';
import 'package:luqa/features/insights/domain/insights_models.dart';
import 'package:luqa/features/today/application/sync_engine.dart';
import 'package:luqa/features/today/application/timeline_controller.dart';
import 'package:luqa/features/today/data/today_providers.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/timeline_geometry.dart';

final insightsControllerProvider =
    NotifierProvider.autoDispose<InsightsController, InsightsState>(
      InsightsController.new,
    );

class InsightsState {
  const InsightsState({
    required this.span,
    required this.offset,
    this.report,
    this.selectedDay,
    this.isLoading = true,
    this.isRefreshing = false,
    this.isOffline = false,
    this.error,
  });

  final InsightsSpan span;

  /// Whole spans into the past. Zero is the span containing today.
  final int offset;

  final InsightsReport? report;

  /// The column the headline is currently reading, or null for the whole span.
  final DateTime? selectedDay;

  final bool isLoading;
  final bool isRefreshing;

  /// The device's own rows answered, but the server could not be reached. The
  /// numbers on screen are real, just not necessarily the newest ones.
  final bool isOffline;

  final String? error;

  bool get isCurrent => offset == 0;

  /// The selected column, dropped silently if the span moved out from under it.
  RhythmDay? get selection {
    final day = selectedDay;
    if (day == null) return null;
    return report?.dayFor(day);
  }

  InsightsState copyWith({
    InsightsSpan? span,
    int? offset,
    InsightsReport? report,
    DateTime? selectedDay,
    bool clearSelection = false,
    bool? isLoading,
    bool? isRefreshing,
    bool? isOffline,
    String? error,
    bool clearError = false,
  }) => InsightsState(
    span: span ?? this.span,
    offset: offset ?? this.offset,
    report: report ?? this.report,
    selectedDay: clearSelection ? null : selectedDay ?? this.selectedDay,
    isLoading: isLoading ?? this.isLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isOffline: isOffline ?? this.isOffline,
    error: clearError ? null : error ?? this.error,
  );
}

/// Insights is a reading of rows this device already holds.
///
/// Nothing here asks the network a question of its own: the sync that keeps
/// the timeline correct keeps these numbers correct too, so a span can be
/// changed, stepped back through and compared with no signal at all — which is
/// the difference between reflecting on a year and waiting for one to load.
class InsightsController extends Notifier<InsightsState> {
  int _generation = 0;

  TodayRepository get _repository => ref.read(todayRepositoryProvider);

  @override
  InsightsState build() {
    // A drained write queue means the server has told this device something it
    // did not know. The wall is a picture of exactly those rows.
    ref.listen(syncEngineProvider, (previous, next) {
      if (!ref.mounted) return;
      if (previous != null && next.rounds > previous.rounds) {
        unawaited(_load());
      }
    });

    Future<void>.microtask(() => _load(pull: true));
    return const InsightsState(span: InsightsSpan.week, offset: 0);
  }

  Future<void> _load({bool pull = false}) async {
    final generation = ++_generation;
    final now = ref.read(currentTimeProvider);
    // The week start and the day cutoff are the account's, and both still
    // come from the same constants the timeline uses rather than from the
    // settings the sync already carries. Insights follows the timeline here on
    // purpose: two answers to "when does a day begin" would be worse than one
    // that is wrong for an account that has changed it.
    final range = insightsRange(
      span: state.span,
      now: now,
      offset: state.offset,
    );

    // One read covering this span and the one before it, so every comparison
    // on screen comes from a single consistent set of rows.
    final windowFrom = _atDayStart(addDays(range.from, -state.span.days));
    final windowTo = _atDayStart(range.to);

    try {
      final categories = await _repository.loadCategories();
      final window = await _repository.loadWindow(windowFrom, windowTo);
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        report: buildInsightsReport(
          span: state.span,
          from: range.from,
          to: range.to,
          entries: window.entries,
          sleep: window.sleep,
          categories: categories,
          now: now,
        ),
        isLoading: false,
        isOffline: false,
        clearError: true,
      );
    } on Object catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: describeNetworkFailure(
          error,
          whileDoing: 'reading your history',
        ),
      );
      return;
    }

    if (!pull) return;

    // Catching up happens behind a screen that is already correct. Not
    // reaching the server is a status rather than an error: it only means
    // nothing newer arrived.
    final local = ref.read(localFirstTodayRepositoryProvider);
    if (local == null) {
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(isRefreshing: false);
      }
      return;
    }
    try {
      await local.pull();
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(isRefreshing: false, isOffline: false);
      await _load();
    } on Object {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(isRefreshing: false, isOffline: true);
    }
  }

  DateTime _atDayStart(DateTime day) =>
      DateTime(day.year, day.month, day.day, dayStartHour);

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, isOffline: false);
    await _load(pull: true);
  }

  /// Changing the span keeps you looking at the present rather than at
  /// whatever twelve-week block the week you were on happened to sit in.
  Future<void> setSpan(InsightsSpan span) async {
    if (span == state.span) return;
    state = state.copyWith(span: span, offset: 0, clearSelection: true);
    await _load();
  }

  Future<void> step(int spans) async {
    // Forward stops at the span containing today; there is nothing to report
    // about next month.
    final next = (state.offset + spans).clamp(-1000, 0);
    if (next == state.offset) return;
    state = state.copyWith(offset: next, clearSelection: true);
    await _load();
  }

  Future<void> toNow() async {
    if (state.offset == 0) return;
    state = state.copyWith(offset: 0, clearSelection: true);
    await _load();
  }

  /// Tapping the selected column again clears it, so the headline goes back to
  /// the whole span without needing a second control to say so.
  void select(DateTime? day) {
    if (day == null || state.selectedDay == day) {
      state = state.copyWith(clearSelection: true);
      return;
    }
    state = state.copyWith(selectedDay: day);
  }
}
