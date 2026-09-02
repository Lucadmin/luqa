import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

/// One line on the chart: everything logged for an exercise at one gym, or —
/// when the gyms are read as a single story — everything logged anywhere.
class ExerciseProgressSeries {
  ExerciseProgressSeries({
    required this.label,
    required this.color,
    required this.points,
    this.dotColors,
  }) : assert(
         dotColors == null || dotColors.length == points.length,
         'A dot colour per point, or none at all.',
       );

  final String label;
  final Color color;
  final List<GymExercisePoint> points;

  /// Dot colours parallel to [points], for the combined line: the line is one
  /// colour, but each workout keeps its gym's, so a jump can still be placed.
  final List<Color>? dotColors;
}

/// The progress lines for one exercise.
///
/// Unlike the sparkline in the workout sheet, a point sits at its date rather
/// than at its index. Two gyms only compare honestly when a lift from March
/// sits above a lift from March; index spacing would line up the third workout
/// at one gym with the third at the other however many months apart they were.
class ExerciseProgressChart extends StatelessWidget {
  const ExerciseProgressChart({
    required this.series,
    this.height = 148,
    super.key,
  });

  final List<ExerciseProgressSeries> series;
  final double height;

  @override
  Widget build(BuildContext context) {
    final plotted = <_Series>[];
    for (final entry in series) {
      final spots = <_Spot>[];
      for (var index = 0; index < entry.points.length; index += 1) {
        final point = entry.points[index];
        final value = point.bestOneRepMax;
        final date = DateTime.tryParse(point.dateKey);
        if (value == null || date == null) continue;
        spots.add((
          at: date.millisecondsSinceEpoch.toDouble(),
          value: value,
          dot: entry.dotColors?[index] ?? entry.color,
        ));
      }
      if (spots.isEmpty) continue;
      spots.sort((a, b) => a.at.compareTo(b.at));
      plotted.add((color: entry.color, spots: spots));
    }

    final total = plotted.fold(0, (sum, item) => sum + item.spots.length);
    if (total < 2) {
      return SizedBox(
        height: height,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            total == 0
                ? 'Your progress line starts here.'
                : 'One more workout will start the line.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: plotted.length == 1
          ? 'Progress over $total workouts'
          : 'Progress over $total workouts across ${plotted.length} gyms',
      image: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _ProgressChartPainter(
            series: plotted,
            rule: LuqaPalette.of(context).border,
          ),
        ),
      ),
    );
  }
}

typedef _Spot = ({double at, double value, Color dot});
typedef _Series = ({Color color, List<_Spot> spots});

class _ProgressChartPainter extends CustomPainter {
  const _ProgressChartPainter({required this.series, required this.rule});

  final List<_Series> series;
  final Color rule;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 4.0;
    final spots = [for (final entry in series) ...entry.spots];
    final minValue = spots.map((spot) => spot.value).reduce(math.min);
    final maxValue = spots.map((spot) => spot.value).reduce(math.max);
    final spread = math.max(maxValue - minValue, maxValue.abs() * 0.08);
    final range = spread > 0 ? spread : 1.0;
    final firstAt = spots.map((spot) => spot.at).reduce(math.min);
    final lastAt = spots.map((spot) => spot.at).reduce(math.max);
    final span = lastAt - firstAt;

    // Everything on one day has no time axis to spread along, so it sits in
    // the middle rather than pinned to the left edge.
    double dx(double at) => span <= 0
        ? size.width / 2
        : inset + (at - firstAt) / span * (size.width - inset * 2);
    double dy(double value) =>
        size.height -
        inset -
        (value - minValue) / range * (size.height - inset * 2);

    final rulePaint = Paint()
      ..color = rule.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
      rulePaint,
    );

    // Lines first, then every dot, so a crossing never buries a workout.
    for (final entry in series) {
      if (entry.spots.length < 2) continue;
      final path = Path();
      for (var index = 0; index < entry.spots.length; index += 1) {
        final spot = entry.spots[index];
        final offset = Offset(dx(spot.at), dy(spot.value));
        if (index == 0) {
          path.moveTo(offset.dx, offset.dy);
        } else {
          path.lineTo(offset.dx, offset.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = entry.color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    for (final entry in series) {
      for (final spot in entry.spots) {
        canvas.drawCircle(
          Offset(dx(spot.at), dy(spot.value)),
          2.5,
          Paint()..color = spot.dot,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressChartPainter oldDelegate) {
    if (oldDelegate.rule != rule ||
        oldDelegate.series.length != series.length) {
      return true;
    }
    for (var index = 0; index < series.length; index += 1) {
      final before = oldDelegate.series[index];
      final now = series[index];
      if (before.color != now.color || !listEquals(before.spots, now.spots)) {
        return true;
      }
    }
    return false;
  }
}
