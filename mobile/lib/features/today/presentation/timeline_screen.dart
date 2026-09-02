import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/app/top_level_header.dart';
import 'package:luqa/design_system/discarded_writes_notice.dart';
import 'package:luqa/design_system/luqa_sync_status.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/habits/application/habits_controller.dart';
import 'package:luqa/features/habits/presentation/widgets/habits_strip.dart';
import 'package:luqa/features/today/application/people_names.dart';
import 'package:luqa/features/today/application/timeline_controller.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa/features/today/domain/timeline_geometry.dart';
import 'package:luqa/features/today/presentation/category_picker_sheet.dart';
import 'package:luqa/features/today/presentation/entry_editor_sheet.dart';
import 'package:luqa/features/today/presentation/sleep_detail_sheet.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';
import 'package:luqa/features/today/presentation/widgets/draft_composer.dart';
import 'package:luqa/features/today/presentation/widgets/now_bar.dart';
import 'package:luqa/features/today/presentation/widgets/timeline_metrics.dart';
import 'package:luqa/features/today/presentation/widgets/timeline_view.dart';

/// Time tracking: a continuous timeline of the days behind and ahead, with
/// everything needed to record a block without leaving the grid it lands on.
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  final GlobalKey<TimelineViewState> _timeline = GlobalKey<TimelineViewState>();
  static const _metrics = TimelineMetrics();

  late final DateTime _openedAt = ref.read(currentTimeProvider);
  late DateTime _now = _openedAt;
  Timer? _clock;
  String? _pendingTimerCategoryId;

  @override
  void initState() {
    super.initState();
    // One clock for the whole screen, aligned to the next minute so the
    // now-line moves when the displayed time actually changes.
    final toNextMinute = Duration(
      seconds: 60 - _now.second,
      milliseconds: -_now.millisecond,
    );
    _clock = Timer(toNextMinute, () {
      _tick();
      _clock = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
    });
    // The habits controller outlives this screen, so the day the strip was
    // scrolled to last time would otherwise still be showing above a timeline
    // that has gone back to today.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _habits.viewStripDay(ref.read(timelineControllerProvider).visibleDay);
    });
  }

  void _tick() {
    if (mounted) setState(() => _now = DateTime.now());
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  TimelineController get _controller =>
      ref.read(timelineControllerProvider.notifier);

  HabitsController get _habits => ref.read(habitsControllerProvider.notifier);

  // Day navigation -----------------------------------------------------------

  Future<void> _jumpToDate(DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(_now.year - 10),
      lastDate: DateTime(_now.year + 2),
      helpText: 'Jump to a day',
    );
    if (picked == null) return;
    _timeline.currentState?.goToDay(picked);
  }

  // Entries ------------------------------------------------------------------

  Future<void> _openEntry(TimeEntry entry) async {
    if (entry.isRunning) {
      // A running block has no end to edit yet; stopping it is the only
      // meaningful action, and the timer bar above already offers that.
      _showMessage('Stop the timer to edit this entry.');
      return;
    }
    _controller.cancelDraft();
    final result = await showEntryEditorSheet(
      context,
      title: 'Edit entry',
      description: entry.description,
      categoryId: entry.categoryId,
      start: entry.start,
      end: entry.end!,
      canDelete: true,
      personIds: entry.personIds,
    );
    if (result == null || !mounted) return;

    if (result.delete) {
      await _deleteEntry(entry.id);
      return;
    }
    await _controller.editEntry(
      entry.id,
      EntryPatch(
        description: result.description,
        categoryId: result.categoryId,
        clearCategory: result.categoryId == null,
        start: result.start,
        end: result.end,
        personIds: result.personIds,
      ),
    );
  }

  Future<void> _deleteEntry(String id) async {
    final removed = await _controller.deleteEntry(id);
    if (removed == null || !mounted) return;
    unawaited(HapticFeedback.mediumImpact());
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Entry deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _controller.restoreEntry(removed),
          ),
        ),
      );
  }

  void _reshape(TimeEntry entry) {
    unawaited(HapticFeedback.mediumImpact());
    _controller.beginReshaping(entry);
  }

  /// Opens the draft's full form, so times can be typed rather than dragged.
  Future<void> _expandDraft(TimelineDraft draft) async {
    final result = await showEntryEditorSheet(
      context,
      title: draft.isNew ? 'New entry' : 'Edit entry',
      description: draft.description,
      categoryId: draft.categoryId,
      start: draft.start,
      end: draft.end,
      canDelete: !draft.isNew,
      personIds: draft.personIds,
    );
    if (result == null || !mounted) return;

    if (result.delete) {
      await _deleteEntry(draft.entryId!);
      return;
    }
    _controller
      ..describeDraft(result.description)
      ..categoriseDraft(result.categoryId)
      ..tagDraft(result.personIds)
      ..moveDraft(result.start!, result.end!);
    await _controller.commitDraft();
  }

  Future<void> _openSleep(SleepEntry entry) =>
      showSleepDetailSheet(context, entry);

  // Timer --------------------------------------------------------------------

  Future<void> _startTimer(String description) async {
    final started = await _controller.startTimer(
      description: description,
      categoryId: _pendingTimerCategoryId,
    );
    if (!started || !mounted) return;
    setState(() => _pendingTimerCategoryId = null);
    _timeline.currentState?.goToNow();
  }

  /// Composes a block covering the time since the last thing logged today,
  /// which is what "I forgot to track that" almost always means.
  void _logRecent() {
    final state = ref.read(timelineControllerProvider);
    final now = DateTime.now();
    final end = minutesToDate(now, snap(minutesSinceMidnight(now)));

    DateTime? lastEnd;
    for (final entry in state.entries) {
      final entryEnd = entry.end;
      if (entryEnd == null || !entryEnd.isBefore(end)) continue;
      if (lastEnd == null || entryEnd.isAfter(lastEnd)) lastEnd = entryEnd;
    }

    final since = lastEnd == null ? null : end.difference(lastEnd);
    // A gap of half a day is not something anyone means to log in one block.
    final plausible =
        since != null &&
        since > Duration.zero &&
        since <= const Duration(hours: 4);
    _controller.beginDraft(
      plausible ? lastEnd! : end.subtract(const Duration(minutes: 30)),
      end,
    );
    _timeline.currentState?.goToNow();
  }

  Future<void> _pickTimerCategory() async {
    final selection = await showCategoryPickerSheet(
      context,
      selectedId: _pendingTimerCategoryId,
    );
    if (selection == null || !mounted) return;
    setState(() => _pendingTimerCategoryId = selection.categoryId);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineControllerProvider);
    final draft = state.draft;

    // Surface a failed save without stealing the screen; the composer shows
    // its own copy while it is open.
    ref.listen(timelineControllerProvider, (previous, next) {
      final message = next.error;
      if (message == null || message == previous?.error) return;
      if (next.draft == null) _showMessage(message);
    });

    // The habits row above the grid belongs to the day the grid is showing, and
    // a category-linked habit's progress *is* the blocks on it. Both are wired
    // here rather than inside HabitsController, because the timeline controller
    // is autoDispose and the habits controller is not: a listen from there
    // would keep the timeline alive for the life of the app. This screen
    // already watches both.
    ref.listen(
      timelineControllerProvider.select((state) => state.visibleDay),
      (_, day) => _habits.viewStripDay(day),
    );
    ref.listen(
      timelineControllerProvider.select((state) => state.entries),
      (_, entries) => unawaited(_habits.syncTrackedTime(entries)),
    );

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _Header(
            day: state.visibleDay,
            now: _now,
            tracked: state.trackedOn(state.visibleDay, _now),
            sleep: state.sleepOn(state.visibleDay),
            isRefreshing: state.isRefreshing,
            isOffline: state.isOffline,
            pendingWrites: state.pendingWrites,
            onPreviousDay: () => _timeline.currentState?.shiftDays(-1),
            onNextDay: () => _timeline.currentState?.shiftDays(1),
            onPickDate: () => _jumpToDate(state.visibleDay),
            onGoToNow: () => _timeline.currentState?.goToNow(),
            onRetry: _controller.refresh,
          ),
          if (state.discarded.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuqaSpacing.lg,
                vertical: LuqaSpacing.xs,
              ),
              child: DiscardedWritesNotice(
                discarded: state.discarded,
                onAcknowledge: _controller.acknowledgeDiscarded,
              ),
            ),
          if (draft == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LuqaSpacing.lg,
                LuqaSpacing.xs,
                LuqaSpacing.lg,
                LuqaSpacing.md,
              ),
              child: NowBar(
                running: state.runningEntry,
                runningCategory: state.categoryById(
                  state.runningEntry?.categoryId,
                ),
                pendingCategory: state.categoryById(_pendingTimerCategoryId),
                onStart: _startTimer,
                onStop: () => _controller.stopTimer(),
                onOpenRunning: () => _timeline.currentState?.goToNow(),
                onPickCategory: _pickTimerCategory,
                onLogRecent: _logRecent,
              ),
            ),
          // Today's habits, between what is running now and the day itself:
          // the check-ins belong in the flow of logging the day, not on a
          // screen you have to remember to visit. Hidden while a block is
          // being composed, for the same reason the timer bar is — the draft
          // owns the screen until it is saved.
          if (draft == null)
            Padding(
              padding: const EdgeInsets.only(bottom: LuqaSpacing.md),
              child: HabitsStrip(now: _now),
            ),
          Divider(height: 1, color: LuqaPalette.of(context).border),
          Expanded(
            child: state.isLoading
                ? const _TimelineSkeleton()
                : state.error != null && state.entries.isEmpty
                ? _TimelineLoadError(
                    message: state.error!,
                    onRetry: _controller.refresh,
                  )
                : TimelineView(
                    key: _timeline,
                    metrics: _metrics,
                    entries: state.entries,
                    sleep: state.sleep,
                    categories: state.categories,
              names: ref.watch(personNamesProvider),
                    draft: draft,
                    now: _now,
                    openedAt: _openedAt,
                    onVisibleDayChanged: _controller.setVisibleDay,
                    onCreateAt: _controller.beginDraft,
                    onDraftChanged: _controller.moveDraft,
                    onOpenEntry: _openEntry,
                    onReshapeEntry: _reshape,
                    onOpenSleep: _openSleep,
                    showEmptyHint: state.entries.isEmpty,
                    onExpandDraft: () {
                      final current = ref
                          .read(timelineControllerProvider)
                          .draft;
                      if (current != null) _expandDraft(current);
                    },
                  ),
          ),
          if (draft != null)
            DraftComposer(
              draft: draft,
              categories: state.categories,
              recents: state.recentActivities,
              error: state.error,
              onEditTimes: () => _expandDraft(draft),
              onDelete: draft.isNew ? null : () => _deleteEntry(draft.entryId!),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.day,
    required this.now,
    required this.tracked,
    required this.sleep,
    required this.isRefreshing,
    required this.isOffline,
    required this.pendingWrites,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onPickDate,
    required this.onGoToNow,
    required this.onRetry,
  });

  final DateTime day;
  final DateTime now;
  final Duration tracked;
  final Duration sleep;
  final bool isRefreshing;
  final bool isOffline;
  final int pendingWrites;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onPickDate;
  final VoidCallback onGoToNow;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = dayNumber(day) == dayNumber(startOfLogicalDay(now));

    final hasSyncStatus = pendingWrites > 0 || isOffline || isRefreshing;

    return LuqaTopLevelHeader(
      primary: Row(
        children: [
          _NavArrow(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Previous day',
            onPressed: onPreviousDay,
          ),
          Flexible(
            child: Semantics(
              button: true,
              label: 'Showing ${fullDate(day)}. Jump to a day',
              child: InkWell(
                onTap: onPickDate,
                borderRadius: BorderRadius.circular(LuqaRadii.control),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LuqaSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            relativeDayLabel(day, now),
                            key: const ValueKey('visible-day-label'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _NavArrow(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Next day',
            onPressed: onNextDay,
          ),
        ],
      ),
      contextualActions: [
        if (!isToday)
          _NavArrow(
            icon: Icons.my_location_rounded,
            tooltip: 'Back to now',
            onPressed: onGoToNow,
          ),
      ],
      supporting: _DaySummary(tracked: tracked, sleep: sleep),
      status: hasSyncStatus
          ? LuqaSyncStatus(
              pendingWrites: pendingWrites,
              isOffline: isOffline,
              isRefreshing: isRefreshing,
              onRetry: onRetry,
              controlKey: const ValueKey('pending-writes-chip'),
            )
          : null,
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 22),
  );
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.tracked, required this.sleep});

  final Duration tracked;
  final Duration sleep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final quiet = theme.textTheme.labelMedium!.copyWith(
      color: muted,
      fontWeight: FontWeight.w500,
    );
    final numeric = quiet.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    // One rich line rather than a row of widgets, so a long total or a large
    // text scale ellipsises instead of overflowing.
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: compactDuration(tracked), style: numeric),
          const TextSpan(text: ' tracked'),
          if (sleep > Duration.zero) ...[
            const TextSpan(text: '  ·  '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: LuqaSpacing.xs),
                child: Icon(Icons.bedtime_outlined, size: 13, color: muted),
              ),
            ),
            TextSpan(text: compactDuration(sleep), style: numeric),
            const TextSpan(text: ' sleep'),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: quiet,
    );
  }
}

class _TimelineSkeleton extends StatelessWidget {
  const _TimelineSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = LuqaPalette.of(context);
    // A list rather than a column: these are fixed heights standing in for the
    // day's blocks, and on a short window they add up to more than the space
    // left for them. Overflowing there would be a stripe of black-and-yellow
    // where the timeline is about to appear.
    return ExcludeSemantics(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(TimelineMetrics.gutter, 8, 16, 0),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final height in [96.0, 52.0, 148.0, 68.0, 120.0]) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.raised,
                borderRadius: BorderRadius.circular(LuqaRadii.control),
              ),
              child: SizedBox(height: height, width: double.infinity),
            ),
            const SizedBox(height: LuqaSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _TimelineLoadError extends StatelessWidget {
  const _TimelineLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LuqaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: LuqaSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: LuqaSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
