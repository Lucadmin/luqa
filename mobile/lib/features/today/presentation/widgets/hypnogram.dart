import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';
import 'package:luqa/features/today/presentation/widgets/sleep_stage_palette.dart';

/// The shape of a night: one row per stage, each block sitting at the time it
/// happened. Position carries the stage as strongly as colour does, so the
/// chart survives being read in greyscale.
class Hypnogram extends StatelessWidget {
  const Hypnogram({required this.entry, super.key});

  final SleepEntry entry;

  static const double _rowHeight = 16;
  static const double _rowGap = 5;
  static const double _labelWidth = 46;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);

    // Only rows the provider actually scored; an empty "Deep" lane would read
    // as a night with no deep sleep rather than a device that never reports it.
    final present = [
      for (final kind in SleepStagePalette.order)
        if (entry.stages.any((stage) => stage.kind == kind)) kind,
    ];
    if (present.isEmpty) return const SizedBox.shrink();

    final span = entry.end.difference(entry.start).inSeconds;
    if (span <= 0) return const SizedBox.shrink();

    final height = present.length * _rowHeight + (present.length - 1) * _rowGap;

    return Semantics(
      label:
          'Sleep stages from ${clock(entry.start)} to ${clock(entry.end)}. '
          '${present.map((kind) => kind.label).join(', ')}.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _labelWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final kind in present) ...[
                        SizedBox(
                          height: _rowHeight,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              kind.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10.5,
                                height: 1,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        if (kind != present.last)
                          const SizedBox(height: _rowGap),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: LuqaSpacing.sm),
                Expanded(
                  child: CustomPaint(
                    size: Size(double.infinity, height),
                    painter: _HypnogramPainter(
                      entry: entry,
                      rows: present,
                      colors: {
                        for (final kind in present)
                          kind: SleepStagePalette.of(context, kind),
                      },
                      track: palette.border.withValues(alpha: 0.35),
                      rowHeight: _rowHeight,
                      rowGap: _rowGap,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: LuqaSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(
                left: _labelWidth + LuqaSpacing.sm,
              ),
              child: _TimeAxis(start: entry.start, end: entry.end),
            ),
          ],
        ),
      ),
    );
  }
}

class _HypnogramPainter extends CustomPainter {
  _HypnogramPainter({
    required this.entry,
    required this.rows,
    required this.colors,
    required this.track,
    required this.rowHeight,
    required this.rowGap,
  });

  final SleepEntry entry;
  final List<SleepStageKind> rows;
  final Map<SleepStageKind, Color> colors;
  final Color track;
  final double rowHeight;
  final double rowGap;

  @override
  void paint(Canvas canvas, Size size) {
    final span = entry.end.difference(entry.start).inSeconds;
    if (span <= 0 || size.width <= 0) return;

    // A hairline behind every lane, so a stage that happened rarely still
    // reads as "this row exists and was mostly empty".
    final trackPaint = Paint()..color = track;
    for (var index = 0; index < rows.length; index++) {
      final top = index * (rowHeight + rowGap) + rowHeight / 2 - 0.5;
      canvas.drawRect(Rect.fromLTWH(0, top, size.width, 1), trackPaint);
    }

    for (final stage in entry.stages) {
      final row = rows.indexOf(stage.kind);
      if (row == -1) continue;

      final startFraction =
          stage.start.difference(entry.start).inSeconds / span;
      final endFraction = stage.end.difference(entry.start).inSeconds / span;
      final left = (startFraction.clamp(0.0, 1.0)) * size.width;
      final right = (endFraction.clamp(0.0, 1.0)) * size.width;

      // A two-minute stage is a sliver; keep it visible rather than dropping
      // it, since brief wakings are exactly what the chart is for.
      final width = math.max(2.0, right - left);
      final top = row * (rowHeight + rowGap);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            math.min(left, size.width - width),
            top,
            width,
            rowHeight,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = colors[stage.kind]!,
      );
    }
  }

  @override
  bool shouldRepaint(_HypnogramPainter old) =>
      old.entry != entry || old.colors != colors || old.track != track;
}

/// Whole hours across the night, thinned until the labels stop colliding.
class _TimeAxis extends StatelessWidget {
  const _TimeAxis({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      fontSize: 10,
      height: 1,
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = end.difference(start).inSeconds;
        if (span <= 0) return const SizedBox.shrink();

        final ticks = <DateTime>[];
        var cursor = DateTime(
          start.year,
          start.month,
          start.day,
          start.hour + 1,
        );
        while (cursor.isBefore(end)) {
          ticks.add(cursor);
          cursor = cursor.add(const Duration(hours: 1));
        }

        // Roughly 44 dp per label keeps them from touching on a phone.
        final room = math.max(1, (constraints.maxWidth / 44).floor());
        final step = math.max(1, (ticks.length / room).ceil());
        final shown = [for (var i = 0; i < ticks.length; i += step) ticks[i]];

        return SizedBox(
          height: 12,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final tick in shown)
                Positioned(
                  left:
                      (tick.difference(start).inSeconds / span) *
                          constraints.maxWidth -
                      16,
                  width: 32,
                  child: Text(
                    clock(tick),
                    textAlign: TextAlign.center,
                    style: style,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
