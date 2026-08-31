import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';

/// The one graphic on the money screen: how much is out there in each
/// direction, drawn to scale against each other.
///
/// A chart would be dishonest here — there is no series, only two numbers and
/// the ratio between them, which is exactly what a divided rule shows. When
/// everything is settled it becomes a flat neutral line, so "nothing
/// outstanding" is a shape, not the absence of one.
class PositionBar extends StatelessWidget {
  const PositionBar({
    required this.owedToYouCents,
    required this.youOweCents,
    super.key,
  });

  final int owedToYouCents;
  final int youOweCents;

  static const _height = 6.0;

  @override
  Widget build(BuildContext context) {
    final palette = LuqaPalette.of(context);
    final total = owedToYouCents + youOweCents;
    final radius = BorderRadius.circular(LuqaRadii.indicator);

    if (total == 0) {
      return Container(
        height: _height,
        decoration: BoxDecoration(color: palette.border, borderRadius: radius),
      );
    }

    // A direction that exists but is tiny still has to be visible, or the bar
    // says "you owe nothing" when the user owes four euros.
    final owedFlex = owedToYouCents == 0
        ? 0
        : (owedToYouCents * 1000 ~/ total).clamp(40, 960);
    final oweFlex = youOweCents == 0 ? 0 : 1000 - owedFlex;

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: _height,
        child: Row(
          children: [
            if (owedFlex > 0)
              Expanded(
                flex: owedFlex,
                child: ColoredBox(color: palette.credit),
              ),
            if (owedFlex > 0 && oweFlex > 0) const SizedBox(width: 2),
            if (oweFlex > 0)
              Expanded(flex: oweFlex, child: ColoredBox(color: palette.debit)),
          ],
        ),
      ),
    );
  }
}

/// One side of the position bar, named and coloured together — the colour is
/// never asked to carry the meaning on its own.
class PositionLegend extends StatelessWidget {
  const PositionLegend({
    required this.label,
    required this.amount,
    required this.color,
    this.alignEnd = false,
    super.key,
  });

  final String label;
  final String amount;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              // Nudged down so the mark sits on the first line of a label that
              // has wrapped, rather than floating beside the middle of two.
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(LuqaRadii.indicator),
                ),
              ),
            ),
            const SizedBox(width: LuqaSpacing.sm),
            // Reflows at large text sizes rather than clipping the word that
            // carries the meaning.
            Flexible(
              child: Text(
                label,
                textAlign: alignEnd ? TextAlign.end : TextAlign.start,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: LuqaSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            amount,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
