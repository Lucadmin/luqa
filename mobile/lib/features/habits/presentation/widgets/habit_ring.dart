import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';

/// A circular progress ring with whatever belongs in the middle of it.
///
/// The ring is the habit's own colour and the track is the app's border, so a
/// row of them reads as one system with a dozen accents rather than a dozen
/// unrelated dials.
class HabitRing extends StatelessWidget {
  const HabitRing({
    required this.fraction,
    required this.color,
    this.size = 44,
    this.stroke = 3,
    this.child,
    super.key,
  });

  final double fraction;
  final Color color;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The arc is decoration; everything it means is in the label beside
          // it and in the semantics of the control that owns it.
          ExcludeSemantics(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: fraction.clamp(0, 1).toDouble()),
              duration: LuqaMotion.emphasis,
              curve: LuqaMotion.curve,
              builder: (context, value, _) => CustomPaint(
                size: Size.square(size),
                painter: _RingPainter(
                  fraction: value,
                  color: color,
                  track: LuqaPalette.of(context).border,
                  stroke: stroke,
                ),
              ),
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double fraction;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide - stroke) / 2;
    final centre = Offset(size.width / 2, size.height / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(centre, radius, base);

    if (fraction <= 0) return;
    final sweep = 2 * math.pi * fraction;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      // From the top, clockwise, the way progress is read.
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.track != track ||
      old.stroke != stroke;
}
