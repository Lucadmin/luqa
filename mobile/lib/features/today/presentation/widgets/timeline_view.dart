import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/today/application/timeline_controller.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa/features/today/domain/timeline_geometry.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';
import 'package:luqa/features/today/presentation/widgets/timeline_day_pane.dart';
import 'package:luqa/features/today/presentation/widgets/timeline_metrics.dart';

/// How far the timeline reaches in each direction. Bounded rather than truly
/// endless so the scroll extent stays a number Flutter can hold precisely.
const int _daysBefore = 3650; // about ten years
const int _daysAfter = 400;
const int _totalDays = _daysBefore + _daysAfter + 1;

/// Default length of a block created by a single tap.
const int defaultBlockMinutes = 30;

/// A continuous, scrollable timeline: one pane per calendar day inside a
/// single tall scroller, with only the days on screen built. Scrolling reports
/// the day at the top of the viewport; the imperative handle scrolls the other
/// way.
class TimelineView extends StatefulWidget {
  const TimelineView({
    required this.metrics,
    required this.entries,
    required this.sleep,
    required this.categories,
    required this.draft,
    required this.now,
    required this.openedAt,
    required this.onVisibleDayChanged,
    required this.onCreateAt,
    required this.onDraftChanged,
    required this.onOpenEntry,
    required this.onReshapeEntry,
    required this.onOpenSleep,
    required this.onExpandDraft,
    required this.showEmptyHint,
    super.key,
  });

  final TimelineMetrics metrics;
  final List<TimeEntry> entries;
  final List<SleepEntry> sleep;
  final List<Category> categories;
  final TimelineDraft? draft;

  /// Ticks about once a minute; drives the now-line and running blocks.
  final DateTime now;

  /// The instant the screen opened on. Fixed, so the virtual day range never
  /// shifts under the user mid-session.
  final DateTime openedAt;

  final void Function(DateTime day) onVisibleDayChanged;
  final void Function(DateTime start, DateTime end) onCreateAt;
  final void Function(DateTime start, DateTime end) onDraftChanged;
  final void Function(TimeEntry entry) onOpenEntry;
  final void Function(TimeEntry entry) onReshapeEntry;
  final void Function(SleepEntry entry) onOpenSleep;
  final VoidCallback onExpandDraft;

  /// Nothing has ever been logged, so today's pane explains the gesture.
  final bool showEmptyHint;

  @override
  State<TimelineView> createState() => TimelineViewState();
}

class TimelineViewState extends State<TimelineView> {
  final GlobalKey _viewportKey = GlobalKey();
  ScrollController? _controller;
  late final DateTime _epochDay = addDays(
    startOfDay(widget.openedAt),
    -_daysBefore,
  );

  int? _reportedDayOffset;

  // Drag bookkeeping. Times move in content space, which is the finger's
  // movement plus whatever the auto-scroll added underneath it.
  _DragMode? _dragMode;
  double _pointerDelta = 0;
  double _dragStartOffset = 0;
  double _pointerViewportY = 0;
  DateTime? _originStart;
  DateTime? _originEnd;
  DateTime? _lastSnappedStart;
  DateTime? _lastSnappedEnd;
  Timer? _autoScroll;
  double _autoScrollPush = 0;

  /// Distance from a viewport edge at which a drag starts pulling the timeline.
  static const double _edgeZone = 92;
  static const double _maxAutoScrollStep = 14;

  double get _offset =>
      _controller?.hasClients == true ? _controller!.offset : 0;

  @override
  void dispose() {
    _autoScroll?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A block that has just appeared must not be left under the composer,
    // which takes its space out of the viewport as it opens.
    if (widget.draft != null && oldWidget.draft == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ensureDraftVisible());
    }
  }

  // Geometry -----------------------------------------------------------------

  double _yForInstant(DateTime instant) =>
      (dayNumber(instant) - dayNumber(_epochDay)) * widget.metrics.dayHeight +
      widget.metrics.yForMinutes(minutesSinceMidnight(instant));

  /// The logical day shown at a scroll position: before the day-start cutoff
  /// the clock says today, but the day still belongs to the evening before.
  int _logicalDayOffsetAt(double y) {
    final minutes = widget.metrics.minutesForY(y);
    final offset = (minutes / minutesPerDay).floor();
    final intoDay = minutes - offset * minutesPerDay;
    return intoDay < dayStartHour * 60 ? offset - 1 : offset;
  }

  double _clampOffset(double y) {
    final position = _controller?.positions.isNotEmpty == true
        ? _controller!.position
        : null;
    if (position == null) return math.max(0, y);
    return y.clamp(
      position.minScrollExtent,
      math.max(position.minScrollExtent, position.maxScrollExtent),
    );
  }

  // Imperative handle --------------------------------------------------------

  /// Bring an instant into view, animating for short hops and cutting for
  /// long ones, where an animation would only be a blur.
  void _scrollTo(double target, {bool animate = true}) {
    final controller = _controller;
    if (controller == null || !controller.hasClients) return;
    final clamped = _clampOffset(target);
    final distance = (clamped - controller.offset).abs();
    if (!animate ||
        distance > widget.metrics.dayHeight * 3 ||
        MediaQuery.disableAnimationsOf(context)) {
      controller.jumpTo(clamped);
      return;
    }
    controller.animateTo(
      clamped,
      duration: LuqaMotion.emphasis,
      curve: LuqaMotion.curve,
    );
  }

  double get _viewportHeight {
    final controller = _controller;
    if (controller == null || controller.positions.isEmpty) return 0;
    return controller.position.viewportDimension;
  }

  void shiftDays(int days) =>
      _scrollTo(_offset + days * widget.metrics.dayHeight);

  void goToDay(DateTime day) {
    final current = _logicalDayOffsetAt(_offset);
    final target = dayNumber(startOfDay(day)) - dayNumber(_epochDay);
    shiftDays(target - current);
  }

  void goToNow() {
    _scrollTo(_yForInstant(widget.now) - _viewportHeight / 2);
  }

  /// Nudge the timeline just enough that the draft clears the composer.
  void ensureDraftVisible() {
    final draft = widget.draft;
    final controller = _controller;
    if (draft == null || controller == null || !controller.hasClients) return;

    const margin = 20.0;
    final top = _yForInstant(draft.start) - controller.offset;
    final bottom = _yForInstant(draft.end) - controller.offset;
    final limit = _viewportHeight;

    if (bottom > limit - margin) {
      _scrollTo(controller.offset + (bottom - limit + margin));
    } else if (top < margin) {
      _scrollTo(controller.offset - (margin - top));
    }
  }

  // Scroll reporting ---------------------------------------------------------

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    final offset = notification.metrics.pixels;
    final dayOffset = _logicalDayOffsetAt(offset);
    if (dayOffset != _reportedDayOffset) {
      _reportedDayOffset = dayOffset;
      widget.onVisibleDayChanged(addDays(_epochDay, dayOffset));
    }
    return false;
  }

  // Creating and dragging ----------------------------------------------------

  void _handleTapAt(DateTime day, double localY) {
    final minutes = snap(
      widget.metrics.minutesForY(localY),
    ).clamp(0, minutesPerDay - snapMinutes);
    final draft = widget.draft;
    final start = minutesToDate(day, minutes);

    if (draft != null) {
      // A second tap relocates the block being composed rather than throwing
      // it away, so a mis-tap costs one tap instead of starting over.
      unawaited(HapticFeedback.selectionClick());
      widget.onDraftChanged(start, start.add(draft.duration));
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    widget.onCreateAt(
      start,
      start.add(const Duration(minutes: defaultBlockMinutes)),
    );
  }

  void _beginDrag(_DragMode mode, DragStartDetails details) {
    final draft = widget.draft;
    if (draft == null) return;
    setState(() => _dragMode = mode);
    _pointerDelta = 0;
    _dragStartOffset = _offset;
    _originStart = draft.start;
    _originEnd = draft.end;
    _lastSnappedStart = draft.start;
    _lastSnappedEnd = draft.end;
    _pointerViewportY = _toViewport(details.globalPosition);
    unawaited(HapticFeedback.selectionClick());
  }

  double _toViewport(Offset global) {
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return 0;
    return box.globalToLocal(global).dy;
  }

  void _updateDrag(DragUpdateDetails details) {
    if (_dragMode == null) return;
    _pointerDelta += details.delta.dy;
    _pointerViewportY = _toViewport(details.globalPosition);
    _applyDrag();
    _tickAutoScroll();
  }

  void _applyDrag() {
    final mode = _dragMode;
    final origin = _originStart;
    final originEnd = _originEnd;
    if (mode == null || origin == null || originEnd == null) return;

    // Whatever the auto-scroll moved underneath the finger counts as part of
    // the drag, otherwise the block would lag behind the timeline.
    final contentDelta = _pointerDelta + (_offset - _dragStartOffset);
    final deltaMinutes = snap(widget.metrics.minutesForY(contentDelta));

    var start = origin;
    var end = originEnd;
    switch (mode) {
      case _DragMode.move:
        start = origin.add(Duration(minutes: deltaMinutes));
        end = originEnd.add(Duration(minutes: deltaMinutes));
      case _DragMode.resizeStart:
        start = origin.add(Duration(minutes: deltaMinutes));
        if (!start.isBefore(
          end.subtract(const Duration(minutes: snapMinutes)),
        )) {
          start = end.subtract(const Duration(minutes: snapMinutes));
        }
      case _DragMode.resizeEnd:
        end = originEnd.add(Duration(minutes: deltaMinutes));
        if (!end.isAfter(start.add(const Duration(minutes: snapMinutes)))) {
          end = start.add(const Duration(minutes: snapMinutes));
        }
    }

    if (start != _lastSnappedStart || end != _lastSnappedEnd) {
      // One tick per five-minute step, so the block can be sized by feel
      // without watching the numbers.
      _lastSnappedStart = start;
      _lastSnappedEnd = end;
      unawaited(HapticFeedback.selectionClick());
      widget.onDraftChanged(start, end);
    }
  }

  void _tickAutoScroll() {
    final limit = _viewportHeight;
    final aboveEdge = _edgeZone - _pointerViewportY;
    final belowEdge = _pointerViewportY - (limit - _edgeZone);
    final push = aboveEdge > 0
        ? -aboveEdge / _edgeZone
        : belowEdge > 0
        ? belowEdge / _edgeZone
        : 0.0;

    _autoScrollPush = push;
    if (push == 0 || _dragMode == null) {
      _autoScroll?.cancel();
      _autoScroll = null;
      return;
    }
    // The timer reads the push from the field, so the speed keeps ramping as
    // the finger moves further into the edge zone.
    _autoScroll ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      final controller = _controller;
      if (_dragMode == null || controller == null || !controller.hasClients) {
        _autoScroll?.cancel();
        _autoScroll = null;
        return;
      }
      final step = _autoScrollPush.clamp(-1.0, 1.0) * _maxAutoScrollStep;
      final next = _clampOffset(controller.offset + step);
      if (next == controller.offset) return;
      controller.jumpTo(next);
      _applyDrag();
    });
  }

  void _endDrag() {
    _autoScroll?.cancel();
    _autoScroll = null;
    if (_dragMode != null) unawaited(HapticFeedback.selectionClick());
    if (mounted) setState(() => _dragMode = null);
  }

  // Build --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final categoryById = {
      for (final category in widget.categories) category.id: category,
    };
    final byDay = _groupByDay();

    return LayoutBuilder(
      key: _viewportKey,
      builder: (context, constraints) {
        // The controller needs the viewport height to open centred on the
        // current moment, and that height is only known here. Creating it on
        // the first build avoids a visible jump on the frame after.
        _controller ??= ScrollController(
          // Now sits below centre: the hours being logged are the ones just
          // gone, so the past deserves more of the opening screen.
          initialScrollOffset: math.max(
            0,
            _yForInstant(widget.openedAt) - constraints.maxHeight * 0.62,
          ),
        );

        return NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: Stack(
            children: [
              ListView.builder(
                controller: _controller,
                itemExtent: widget.metrics.dayHeight,
                itemCount: _totalDays,
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                itemBuilder: (context, index) {
                  final day = addDays(_epochDay, index);
                  final key = dayNumber(day);
                  return _TappablePane(
                    onTapAt: (localY) => _handleTapAt(day, localY),
                    child: TimelineDayPane(
                      day: day,
                      metrics: widget.metrics,
                      entries: byDay[key]?.entries ?? const [],
                      sleep: byDay[key]?.sleep ?? const [],
                      categories: categoryById,
                      now: widget.now,
                      hiddenEntryId: widget.draft?.entryId,
                      onOpenEntry: widget.onOpenEntry,
                      onReshapeEntry: widget.onReshapeEntry,
                      onOpenSleep: widget.onOpenSleep,
                      onFillGap: widget.onCreateAt,
                      showEmptyHint:
                          widget.showEmptyHint && key == dayNumber(widget.now),
                    ),
                  );
                },
              ),
              if (widget.draft != null)
                _DraftLayer(
                  draft: widget.draft!,
                  metrics: widget.metrics,
                  category: categoryById[widget.draft!.categoryId],
                  scroll: _controller!,
                  activeDrag: _dragMode,
                  topFor: _yForInstant,
                  onBeginDrag: _beginDrag,
                  onUpdateDrag: _updateDrag,
                  onEndDrag: _endDrag,
                  onTap: widget.onExpandDraft,
                ),
            ],
          ),
        );
      },
    );
  }

  /// Split the loaded window into per-day buckets once per build. Anything
  /// crossing midnight lands in both days and is clipped by each.
  Map<int, _DayBucket> _groupByDay() {
    final byDay = <int, _DayBucket>{};

    void add(int key, {TimeEntry? entry, SleepEntry? session}) {
      final bucket = byDay.putIfAbsent(key, _DayBucket.new);
      if (entry != null) bucket.entries.add(entry);
      if (session != null) bucket.sleep.add(session);
    }

    for (final entry in widget.entries) {
      final first = dayNumber(entry.start);
      final last = dayNumber(entry.endOrNow(widget.now));
      for (var key = first; key <= last; key++) {
        add(key, entry: entry);
      }
    }
    for (final session in widget.sleep) {
      final first = dayNumber(session.start);
      final last = dayNumber(session.end);
      for (var key = first; key <= last; key++) {
        add(key, session: session);
      }
    }
    return byDay;
  }
}

class _DayBucket {
  final List<TimeEntry> entries = [];
  final List<SleepEntry> sleep = [];
}

enum _DragMode { move, resizeStart, resizeEnd }

/// The empty grid behind everything else. It only ever claims taps, so a
/// vertical swipe still belongs to the scroller.
class _TappablePane extends StatelessWidget {
  const _TappablePane({required this.onTapAt, required this.child});

  final void Function(double localY) onTapAt;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            // The gutter is a ruler, not a canvas.
            if (details.localPosition.dx < TimelineMetrics.gutter) return;
            onTapAt(details.localPosition.dy);
          },
          child: const SizedBox.expand(),
        ),
      ),
      child,
    ],
  );
}

/// The block being composed, floating above the grid. It is positioned from
/// the scroll offset rather than living inside a pane, so it can cross
/// midnight and be dragged while the timeline scrolls underneath it.
class _DraftLayer extends StatelessWidget {
  const _DraftLayer({
    required this.draft,
    required this.metrics,
    required this.category,
    required this.scroll,
    required this.activeDrag,
    required this.topFor,
    required this.onBeginDrag,
    required this.onUpdateDrag,
    required this.onEndDrag,
    required this.onTap,
  });

  final TimelineDraft draft;
  final TimelineMetrics metrics;
  final Category? category;
  final ScrollController scroll;

  /// Which edge, if any, the finger is on right now.
  final _DragMode? activeDrag;

  final double Function(DateTime) topFor;
  final void Function(_DragMode, DragStartDetails) onBeginDrag;
  final void Function(DragUpdateDetails) onUpdateDrag;
  final VoidCallback onEndDrag;
  final VoidCallback onTap;

  static const double _handleSize = 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: scroll,
      builder: (context, _) {
        final offset = scroll.hasClients ? scroll.offset : 0.0;
        final top = topFor(draft.start) - offset;
        final height = math.max(
          TimelineMetrics.minBlockHeight,
          metrics.yForMinutes(draft.duration.inMinutes),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: TimelineMetrics.gutter + 2,
              right: TimelineMetrics.trailingInset,
              top: top,
              height: height,
              child: _DraftBody(
                draft: draft,
                category: category,
                height: height,
                onTap: onTap,
                onDragStart: (details) => onBeginDrag(_DragMode.move, details),
                onDragUpdate: onUpdateDrag,
                onDragEnd: onEndDrag,
              ),
            ),
            _Handle(
              key: const ValueKey('draft-start-handle'),
              left: TimelineMetrics.gutter - _handleSize / 2 + 10,
              top: top - _handleSize / 2,
              color: theme.colorScheme.primary,
              onSurface: theme.colorScheme.surface,
              label: 'Move the start time',
              time: activeDrag == _DragMode.resizeStart
                  ? clock(draft.start)
                  : null,
              alignTimeAbove: true,
              onDragStart: (details) =>
                  onBeginDrag(_DragMode.resizeStart, details),
              onDragUpdate: onUpdateDrag,
              onDragEnd: onEndDrag,
            ),
            _Handle(
              key: const ValueKey('draft-end-handle'),
              right: TimelineMetrics.trailingInset - _handleSize / 2 + 10,
              top: top + height - _handleSize / 2,
              color: theme.colorScheme.primary,
              onSurface: theme.colorScheme.surface,
              label: 'Move the end time',
              time: activeDrag == _DragMode.resizeEnd ? clock(draft.end) : null,
              alignTimeAbove: false,
              onDragStart: (details) =>
                  onBeginDrag(_DragMode.resizeEnd, details),
              onDragUpdate: onUpdateDrag,
              onDragEnd: onEndDrag,
            ),
          ],
        );
      },
    );
  }
}

class _DraftBody extends StatelessWidget {
  const _DraftBody({
    required this.draft,
    required this.category,
    required this.height,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final TimelineDraft draft;
  final Category? category;
  final double height;
  final VoidCallback onTap;
  final void Function(DragStartDetails) onDragStart;
  final void Function(DragUpdateDetails) onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onVerticalDragStart: onDragStart,
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: (_) => onDragEnd(),
      onVerticalDragCancel: onDragEnd,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LuqaRadii.control),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TimelineEntrySurface(
          title: draft.description,
          category: category,
          start: draft.start,
          end: draft.end,
          running: false,
          height: height,
          selected: true,
          onTap: onTap,
        ),
      ),
    );
  }
}

/// A grab handle sized for a fingertip, with the time it controls shown beside
/// it so the value is readable while the finger covers the block edge.
class _Handle extends StatelessWidget {
  const _Handle({
    required this.top,
    required this.color,
    required this.onSurface,
    required this.label,
    required this.time,
    required this.alignTimeAbove,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.left,
    this.right,
    super.key,
  });

  final double? left;
  final double? right;
  final double top;
  final Color color;
  final Color onSurface;
  final String label;

  /// Shown only while this edge is being dragged, where a finger covers the
  /// block's own times.
  final String? time;

  final bool alignTimeAbove;
  final void Function(DragStartDetails) onDragStart;
  final void Function(DragUpdateDetails) onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel = time;
    final chip = timeLabel == null
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(LuqaRadii.compact),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10.5,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          );

    return Positioned(
      left: left,
      right: right,
      top: top,
      width: _DraftLayer._handleSize,
      height: _DraftLayer._handleSize,
      child: Semantics(
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: onDragStart,
          onVerticalDragUpdate: onDragUpdate,
          onVerticalDragEnd: (_) => onDragEnd(),
          onVerticalDragCancel: onDragEnd,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: onSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2.5),
                ),
              ),
              if (chip != null)
                Positioned(
                  left: left != null ? null : _DraftLayer._handleSize,
                  right: left != null ? _DraftLayer._handleSize : null,
                  top: alignTimeAbove ? -2 : null,
                  bottom: alignTimeAbove ? null : -2,
                  child: chip,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
