import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

class ProgressSparkline extends StatelessWidget {
  const ProgressSparkline({
    required this.points,
    this.height = 72,
    this.showEmptyLabel = true,
    super.key,
  });

  final List<GymExercisePoint> points;
  final double height;
  final bool showEmptyLabel;

  @override
  Widget build(BuildContext context) {
    final values = points
        .map((point) => point.bestOneRepMax)
        .whereType<double>()
        .toList(growable: false);
    if (values.length < 2) {
      return SizedBox(
        height: height,
        child: showEmptyLabel
            ? Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  values.isEmpty
                      ? 'Your progress line starts here.'
                      : 'One more workout will start the line.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : null,
      );
    }
    return Semantics(
      label: 'Progress over ${values.length} workouts',
      image: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _SparklinePainter(
            values: values,
            color: Theme.of(context).colorScheme.primary,
            rule: LuqaPalette.of(context).border,
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.color,
    required this.rule,
  });

  final List<double> values;
  final Color color;
  final Color rule;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 4.0;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(maxValue - minValue, maxValue.abs() * 0.08);
    final dx = (size.width - inset * 2) / (values.length - 1);

    final rulePaint = Paint()
      ..color = rule.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
      rulePaint,
    );

    final path = Path();
    final offsets = <Offset>[];
    for (var index = 0; index < values.length; index += 1) {
      final normalized = (values[index] - minValue) / range;
      final point = Offset(
        inset + dx * index,
        size.height - inset - normalized * (size.height - inset * 2),
      );
      offsets.add(point);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()..color = color;
    for (final point in offsets) {
      canvas.drawCircle(point, 2.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.rule != rule;
}
