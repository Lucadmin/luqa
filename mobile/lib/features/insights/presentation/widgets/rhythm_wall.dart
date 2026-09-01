import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/insights/domain/insights_models.dart';
import 'package:luqa/features/insights/presentation/insights_formatters.dart';
import 'package:luqa/features/today/domain/timeline_geometry.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';

/// Identifies one column of the wall, for the tests that tap a specific day.
ValueKey<String> rhythmColumnKey(DateTime day) => ValueKey<String>(
  'rhythm-column-${day.year}-${day.month.toString().padLeft(2, '0')}-'
  '${day.day.toString().padLeft(2, '0')}',
);

/// The shape of a stretch of life, one column per day.
///
/// Totals say how much; this says when. Every column runs from the day start
/// hour to the day start hour — the same logical day the rest of the app
/// counts by, and the same vertical time axis the Today timeline uses, so a
/// block sits where the eye already expects it. Sleep is drawn behind tracked
/// time in the shell's own ink, because it is measured rather than logged and
/// has no business borrowing an identity colour.
///
/// Read across, the wall shows the thing no total can: that Tuesdays start an
/// hour later, that the evenings went missing in March, that the nights drift
/// at the weekend and come back on Monday.
class RhythmWall extends StatelessWidget {
  const RhythmWall({
    required this.days,
    required this.selected,
    required this.onSelect,
    required this.now,
    this.height = 236,
    super.key,
  });

  final List<RhythmDay> days;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;
  final DateTime now;
  final double height;

  /// Hours worth naming on the axis. The day start itself is named in the
  /// caption instead, where there is room to say what it means.
  static const _markedHours = [6, 12, 18, 0];

  static const _gutter = 26.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = theme.colorScheme.onSurface;

    // Wide columns can carry a rounded corner and their own date; hairline
    // ones cannot, and pretending otherwise turns a texture into mush.
    final gap = switch (days.length) {
      <= 7 => 4.0,
      <= 28 => 2.0,
      _ => 1.0,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _gutter,
                height: height,
                child: _HourGutter(
                  hours: _markedHours,
                  startHour: dayStartHour,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    for (var index = 0; index < days.length; index++) ...[
                      if (index > 0) SizedBox(width: gap),
                      Expanded(
                        child: _Column(
                          key: rhythmColumnKey(days[index].day),
                          day: days[index],
                          selected: days[index].day == selected,
                          onTap: () => onSelect(days[index].day),
                          now: now,
                          ground: palette.raised,
                          rule: palette.border,
                          sleep: ink.withValues(alpha: isDark ? 0.13 : 0.09),
                          uncategorised: palette.muted.withValues(alpha: 0.55),
                          selection: ink,
                          marker: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LuqaSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(left: _gutter),
          child: _Axis(days: days, gap: gap, selected: selected),
        ),
      ],
    );
  }
}

class _HourGutter extends StatelessWidget {
  const _HourGutter({
    required this.hours,
    required this.startHour,
    required this.style,
  });

  final List<int> hours;
  final int startHour;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          for (final hour in hours)
            Positioned(
              top:
                  ((hour - startHour + 24) % 24) / 24 * constraints.maxHeight -
                  6,
              right: LuqaSpacing.sm,
              child: Text(hour.toString().padLeft(2, '0'), style: style),
            ),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.day,
    required this.selected,
    required this.onTap,
    required this.now,
    required this.ground,
    required this.rule,
    required this.sleep,
    required this.uncategorised,
    required this.selection,
    required this.marker,
    super.key,
  });

  final RhythmDay day;
  final bool selected;
  final VoidCallback onTap;
  final DateTime now;
  final Color ground;
  final Color rule;
  final Color sleep;
  final Color uncategorised;
  final Color selection;
  final Color marker;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: !day.isFuture,
      selected: selected,
      label: _label(),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: day.isFuture ? null : onTap,
        child: CustomPaint(
          painter: _ColumnPainter(
            day: day,
            selected: selected,
            ground: ground,
            rule: rule,
            sleep: sleep,
            uncategorised: uncategorised,
            selection: selection,
            marker: marker,
            nowMinutes: day.isToday
                ? now
                      .difference(
                        DateTime(
                          day.day.year,
                          day.day.month,
                          day.day.day,
                          dayStartHour,
                        ),
                      )
                      .inMinutes
                      .toDouble()
                : null,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  String _label() {
    final date = fullDate(day.day);
    if (day.isFuture) return '$date, still to come';
    if (day.isEmpty) return '$date, nothing recorded';
    final parts = <String>[
      if (day.trackedMinutes > 0)
        '${compactDuration(Duration(minutes: day.trackedMinutes.round()))} tracked',
      if (day.sleepMinutes > 0)
        '${compactDuration(Duration(minutes: day.sleepMinutes.round()))} of sleep',
    ];
    return '$date, ${parts.join(', ')}';
  }
}

class _ColumnPainter extends CustomPainter {
  const _ColumnPainter({
    required this.day,
    required this.selected,
    required this.ground,
    required this.rule,
    required this.sleep,
    required this.uncategorised,
    required this.selection,
    required this.marker,
    required this.nowMinutes,
  });

  final RhythmDay day;
  final bool selected;
  final Color ground;
  final Color rule;
  final Color sleep;
  final Color uncategorised;
  final Color selection;
  final Color marker;
  final double? nowMinutes;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.width < 8 ? 1 : LuqaRadii.indicator);
    final outline = RRect.fromRectAndRadius(Offset.zero & size, radius);

    canvas.drawRRect(
      outline,
      Paint()
        ..color = day.isFuture
            ? ground.withValues(alpha: ground.a * 0.45)
            : ground,
    );

    canvas.save();
    canvas.clipRRect(outline);

    // The hours worth naming, so a block can be read against the clock even
    // where the column is too narrow for anything else.
    final rulePaint = Paint()
      ..color = rule
      ..strokeWidth = 1;
    for (final hour in RhythmWall._markedHours) {
      final y = ((hour - dayStartHour + 24) % 24) / 24 * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rulePaint);
    }

    for (final band in day.asleep) {
      _fill(canvas, size, band.from, band.to, sleep, radius);
    }
    for (final segment in day.tracked) {
      _fill(
        canvas,
        size,
        segment.span.from,
        segment.span.to,
        segment.colorValue == null ? uncategorised : Color(segment.colorValue!),
        radius,
      );
    }

    final minutes = nowMinutes;
    if (minutes != null) {
      final y = (minutes / day.spanMinutes * size.height).clamp(
        0.0,
        size.height,
      );
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = marker
          ..strokeWidth = 1.5,
      );
    }

    canvas.restore();

    if (selected) {
      canvas.drawRRect(
        outline.deflate(0.75),
        Paint()
          ..color = selection
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  /// Anything with a duration gets at least a hairline. A five-minute block on
  /// a wall this tall is a third of a pixel, and rounding it away would be the
  /// wall quietly claiming the day was emptier than it was.
  void _fill(
    Canvas canvas,
    Size size,
    double from,
    double to,
    Color color,
    Radius radius,
  ) {
    final top = (from / day.spanMinutes * size.height).clamp(0.0, size.height);
    final bottom = (to / day.spanMinutes * size.height).clamp(0.0, size.height);
    final height = (bottom - top) < 1.5 ? 1.5 : bottom - top;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, top, size.width, height),
        radius,
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _ColumnPainter old) =>
      old.day != day ||
      old.selected != selected ||
      old.ground != ground ||
      old.nowMinutes != nowMinutes;
}

/// What sits under the wall: a weekday and a date where there is room, and
/// week markers where there is not.
class _Axis extends StatelessWidget {
  const _Axis({required this.days, required this.gap, required this.selected});

  final List<RhythmDay> days;
  final double gap;
  final DateTime? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final perColumn = days.length <= 7;

    return ExcludeSemantics(
      child: Row(
        children: [
          for (var index = 0; index < days.length; index++) ...[
            if (index > 0) SizedBox(width: gap),
            Expanded(
              child: perColumn
                  ? _DayTick(
                      day: days[index],
                      selected: days[index].day == selected,
                    )
                  // Every seventh column carries the date its week begins on;
                  // the rest carry nothing, which is what keeps a quarter of a
                  // year readable at all.
                  : index % 7 != 0
                  ? const SizedBox.shrink()
                  : Text(
                      shortDate(days[index].day),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      softWrap: false,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: muted,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayTick extends StatelessWidget {
  const _DayTick({required this.day, required this.selected});

  final RhythmDay day;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emphasised = selected || day.isToday;
    final color = emphasised
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;

    return Column(
      children: [
        Text(
          weekdayInitial(day.day.weekday),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            color: isWeekend(day.day) ? color.withValues(alpha: 0.6) : color,
            fontWeight: emphasised ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        Text(
          '${day.day.day}',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: color.withValues(alpha: emphasised ? 1 : 0.7),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
