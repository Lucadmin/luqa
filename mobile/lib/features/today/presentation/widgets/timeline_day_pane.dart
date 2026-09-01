import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa/features/today/domain/timeline_geometry.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';
import 'package:luqa/features/today/presentation/widgets/timeline_metrics.dart';

/// One calendar day, midnight to midnight, drawn at its own offset inside the
/// continuous timeline. Anything crossing midnight is clipped here and picked
/// up by the neighbouring pane, so the two halves read as one block.
class TimelineDayPane extends StatelessWidget {
  const TimelineDayPane({
    required this.day,
    required this.metrics,
    required this.entries,
    required this.sleep,
    required this.categories,
    required this.names,
    required this.now,
    required this.hiddenEntryId,
    required this.onOpenEntry,
    required this.onReshapeEntry,
    required this.onOpenSleep,
    required this.onFillGap,
    required this.showEmptyHint,
    super.key,
  });

  final DateTime day;
  final TimelineMetrics metrics;
  final List<TimeEntry> entries;
  final List<SleepEntry> sleep;
  final Map<String, Category> categories;

  /// Turns the ids on a block into the names it shows. Passed in rather than
  /// read here so the pane stays a pure function of what it is given — the
  /// same reason categories are.
  final String Function(List<String> personIds) names;

  final DateTime now;

  /// The entry currently floating in the draft layer, so it is not drawn twice.
  final String? hiddenEntryId;

  final void Function(TimeEntry entry) onOpenEntry;
  final void Function(TimeEntry entry) onReshapeEntry;
  final void Function(SleepEntry entry) onOpenSleep;
  final void Function(DateTime start, DateTime end) onFillGap;

  /// First run: the grid says what it is for, once, on today.
  final bool showEmptyHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final dayStart = startOfDay(day);
    final isToday = dayNumber(day) == dayNumber(now);
    final nowMinutes = now.difference(dayStart).inSeconds / 60;

    final laidOut = layOutEntries(entries, dayStart, now);
    final sleepBands = layOutSleep(sleep, dayStart);
    final gaps = computeGaps(entries, sleep, dayStart, now, isToday: isToday);

    return SizedBox(
      height: metrics.dayHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _DayBoundary(day: day, isToday: isToday, metrics: metrics),
          for (var hour = 1; hour < 24; hour++)
            _HourRule(hour: hour, metrics: metrics),
          for (final band in sleepBands)
            _SleepBand(
              band: band,
              metrics: metrics,
              onTap: () => onOpenSleep(band.entry),
            ),
          for (final gap in gaps)
            _GapAffordance(
              gap: gap,
              metrics: metrics,
              onFill: () => onFillGap(
                minutesToDate(day, gap.startMin),
                minutesToDate(day, gap.endMin),
              ),
            ),
          for (final item in laidOut)
            if (item.entry.id != hiddenEntryId)
              _EntryBlock(
                item: item,
                metrics: metrics,
                category: categories[item.entry.categoryId],
                names: names,
                onTap: () => onOpenEntry(item.entry),
                onLongPress: item.running
                    ? null
                    : () => onReshapeEntry(item.entry),
              ),
          if (showEmptyHint)
            Positioned(
              left: TimelineMetrics.gutter + 12,
              right: TimelineMetrics.trailingInset + 12,
              top: metrics.yForMinutes(11 * 60),
              child: IgnorePointer(
                child: Text(
                  'Tap anywhere on the grid to log a block of time',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          if (isToday && nowMinutes >= 0 && nowMinutes <= minutesPerDay)
            _NowLine(
              minutes: nowMinutes,
              metrics: metrics,
              color: theme.colorScheme.primary,
              onColor: theme.colorScheme.onPrimary,
            ),
          // A hairline down the gutter edge keeps the labels reading as a
          // column rather than as text floating over the grid.
          Positioned(
            left: TimelineMetrics.gutter - 1,
            top: 0,
            bottom: 0,
            width: 1,
            child: ColoredBox(color: palette.border.withValues(alpha: 0.45)),
          ),
        ],
      ),
    );
  }
}

class _DayBoundary extends StatelessWidget {
  const _DayBoundary({
    required this.day,
    required this.isToday,
    required this.metrics,
  });

  final DateTime day;
  final bool isToday;
  final TimelineMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final accent = theme.colorScheme.primary;

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: metrics.hourHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 1, child: ColoredBox(color: palette.border)),
          Padding(
            padding: const EdgeInsets.only(
              left: 6,
              top: 5,
              right: TimelineMetrics.gutter,
            ),
            child: SizedBox(
              width: TimelineMetrics.gutter - 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    shortWeekday(day).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      height: 1.1,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w700,
                      color: isToday ? accent : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    shortDate(day),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: isToday
                          ? accent.withValues(alpha: 0.8)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HourRule extends StatelessWidget {
  const _HourRule({required this.hour, required this.metrics});

  final int hour;
  final TimelineMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);

    // Hours before the day-start cutoff still belong to the evening before.
    // Drawing them fainter says so without adding another line of chrome.
    final preCutoff = hour < dayStartHour;
    final ruleColor = palette.border.withValues(alpha: preCutoff ? 0.3 : 0.6);
    final labelColor = theme.colorScheme.onSurfaceVariant.withValues(
      alpha: preCutoff ? 0.45 : 0.85,
    );

    return Positioned(
      left: 0,
      right: 0,
      top: metrics.yForMinutes(hour * 60),
      height: 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: TimelineMetrics.gutter - 10,
            child: Transform.translate(
              offset: const Offset(0, -6),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                textAlign: TextAlign.right,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  height: 1,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          Expanded(child: ColoredBox(color: ruleColor)),
        ],
      ),
    );
  }
}

class _SleepBand extends StatelessWidget {
  const _SleepBand({
    required this.band,
    required this.metrics,
    required this.onTap,
  });

  final LaidOutSleep band;
  final TimelineMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = palette.blue;
    final height = math.max(
      18.0,
      metrics.yForMinutes(band.endMin - band.startMin) - 2,
    );
    final radius = Radius.circular(LuqaRadii.control);

    return Positioned(
      left: TimelineMetrics.gutter + 2,
      right: TimelineMetrics.trailingInset,
      top: metrics.yForMinutes(band.startMin),
      height: height,
      child: Semantics(
        button: true,
        label:
            'Sleep, ${compactDuration(band.entry.asleep)}, '
            '${clock(band.entry.start)} to ${clock(band.entry.end)}',
        child: Material(
          // Sleep is measured, not logged. It reads as material behind the
          // day rather than as another block competing with tracked time.
          color: ink.withValues(alpha: isDark ? 0.13 : 0.09),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: band.clippedTop ? Radius.zero : radius,
              topRight: band.clippedTop ? Radius.zero : radius,
              bottomLeft: band.clippedBottom ? Radius.zero : radius,
              bottomRight: band.clippedBottom ? Radius.zero : radius,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bedtime_outlined, size: 13, color: ink),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        band.entry.isNap ? 'Nap' : 'Sleep',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: ink,
                        ),
                      ),
                    ),
                    if (height >= 30) ...[
                      const SizedBox(width: 8),
                      Text(
                        compactDuration(band.entry.asleep),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: ink.withValues(alpha: 0.85),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GapAffordance extends StatelessWidget {
  const _GapAffordance({
    required this.gap,
    required this.metrics,
    required this.onFill,
  });

  final TimelineGap gap;
  final TimelineMetrics metrics;
  final VoidCallback onFill;

  /// Below this a pill would be bigger than the hole it offers to fill.
  static const _minimumGapMinutes = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final height = metrics.yForMinutes(gap.minutes);
    if (gap.minutes < _minimumGapMinutes || height < 40) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: TimelineMetrics.gutter + 2,
      right: TimelineMetrics.trailingInset,
      top: metrics.yForMinutes(gap.startMin),
      height: height,
      child: Center(
        child: Semantics(
          button: true,
          label: 'Fill the untracked ${compactDuration(gap.duration)}',
          child: Material(
            color: palette.workingSurface,
            shape: StadiumBorder(
              side: BorderSide(color: palette.border.withValues(alpha: 0.8)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onFill,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Fill ${compactDuration(gap.duration)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryBlock extends StatelessWidget {
  const _EntryBlock({
    required this.item,
    required this.metrics,
    required this.category,
    required this.names,
    required this.onTap,
    required this.onLongPress,
  });

  final LaidOutEntry item;
  final TimelineMetrics metrics;
  final Category? category;
  final String Function(List<String> personIds) names;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final height = math.max(
      TimelineMetrics.minBlockHeight,
      metrics.yForMinutes(item.endMin - item.startMin) -
          (item.clippedBottom ? 0 : 2),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Overlapping entries share the width so neither is hidden behind the
        // other, the way a calendar splits a double-booked hour.
        final available =
            constraints.maxWidth -
            TimelineMetrics.gutter -
            TimelineMetrics.trailingInset;
        final laneWidth = available / item.lanes;

        return Stack(
          children: [
            Positioned(
              left: TimelineMetrics.gutter + item.lane * laneWidth + 2,
              width: laneWidth - 4,
              top: metrics.yForMinutes(item.startMin),
              height: height,
              child: TimelineEntrySurface(
                title: item.entry.description,
                people: names(item.entry.personIds),
                category: category,
                start: item.entry.start,
                end: item.entry.end,
                running: item.running,
                height: height,
                clippedTop: item.clippedTop,
                clippedBottom: item.clippedBottom,
                onTap: onTap,
                onLongPress: onLongPress,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The block itself, shared by the grid and the draft layer so a block being
/// dragged is visibly the same object as the one it came from.
class TimelineEntrySurface extends StatelessWidget {
  const TimelineEntrySurface({
    required this.title,
    required this.category,
    required this.start,
    required this.end,
    required this.running,
    required this.height,
    this.people = '',
    this.clippedTop = false,
    this.clippedBottom = false,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final String title;

  /// Who was there, already turned into names. Empty when nobody was tagged,
  /// which is most blocks.
  final String people;
  final Category? category;
  final DateTime start;
  final DateTime? end;
  final bool running;
  final double height;
  final bool clippedTop;
  final bool clippedBottom;

  /// Draft styling: stronger border and the app accent instead of the
  /// category colour, so an unsaved block never passes for a saved one.
  final bool selected;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final identity = selected
        ? theme.colorScheme.primary
        : category == null
        ? theme.colorScheme.onSurfaceVariant
        : Color(category!.colorValue);
    final radius = Radius.circular(LuqaRadii.control);
    final compact = height < TimelineMetrics.compactBlockHeight;
    final label = title.trim().isEmpty ? 'Untitled' : title.trim();
    final range = '${clock(start)} to ${end == null ? 'now' : clock(end!)}';

    return Semantics(
      button: onTap != null,
      label: people.isEmpty
          ? '$label, ${category?.name ?? 'no category'}, $range'
          : '$label with $people, ${category?.name ?? 'no category'}, $range',
      child: Material(
        color: identity.withValues(
          alpha: selected ? (isDark ? 0.30 : 0.16) : (isDark ? 0.22 : 0.13),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: clippedTop ? Radius.zero : radius,
            topRight: clippedTop ? Radius.zero : radius,
            bottomLeft: clippedBottom ? Radius.zero : radius,
            bottomRight: clippedBottom ? Radius.zero : radius,
          ),
          side: BorderSide(
            color: identity.withValues(alpha: selected ? 0.95 : 0.5),
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: TimelineMetrics.maxBlockTextScale,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 9,
                vertical: compact ? 1 : 4,
              ),
              child: Column(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (running) ...[
                        _LivePulse(color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontSize: 12.5,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (category != null) ...[
                          _CategoryDot(color: Color(category!.colorValue)),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            // No new colour and no avatars: the timeline's
                            // focal object stays the day, and who was there is
                            // supporting detail on the line that already
                            // carries the times.
                            people.isEmpty
                                ? '${clock(start)}–'
                                      '${end == null ? 'now' : clock(end!)}'
                                : '${clock(start)}–'
                                      '${end == null ? 'now' : clock(end!)}'
                                      ' · $people',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryDot extends StatelessWidget {
  const _CategoryDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: const SizedBox.square(dimension: 6),
  );
}

/// The one moving thing on a resting timeline: a slow breath on whatever is
/// running right now.
class _LivePulse extends StatefulWidget {
  const _LivePulse({required this.color});

  final Color color;

  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (!WidgetsBinding.instance.disableAnimations) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = DecoratedBox(
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      child: const SizedBox.square(dimension: 7),
    );
    if (MediaQuery.disableAnimationsOf(context)) return dot;
    return FadeTransition(
      opacity: Tween<double>(
        begin: 1,
        end: 0.35,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: dot,
    );
  }
}

class _NowLine extends StatelessWidget {
  const _NowLine({
    required this.minutes,
    required this.metrics,
    required this.color,
    required this.onColor,
  });

  final double minutes;
  final TimelineMetrics metrics;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      left: 0,
      right: 0,
      top: metrics.yForMinutes(minutes) - 9,
      height: 18,
      child: IgnorePointer(
        child: Row(
          children: [
            // The current time takes over the gutter, so the hour label it
            // covers is never read as the time.
            Container(
              width: TimelineMetrics.gutter - 8,
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(LuqaRadii.compact),
                ),
                child: Text(
                  clockFromMinutes(minutes),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: onColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Center(
                child: SizedBox(height: 1.5, child: ColoredBox(color: color)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
