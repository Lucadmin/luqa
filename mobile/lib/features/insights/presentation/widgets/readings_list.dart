import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/insights/presentation/insights_readings.dart';

/// The things the wall implies, said in words.
///
/// A chart can only be read by someone already looking for something. These
/// are the sentences that would otherwise need looking for: when a day
/// usually starts, where the nights drift, how much of the span is accounted
/// for at all. Each one is a number and a plain claim about it — never a
/// score, never a judgement, and never a fact the data does not support.
class ReadingsList extends StatelessWidget {
  const ReadingsList({required this.readings, super.key});

  final List<InsightsReading> readings;

  @override
  Widget build(BuildContext context) {
    final palette = LuqaPalette.of(context);
    return Column(
      children: [
        for (var index = 0; index < readings.length; index++) ...[
          if (index > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.md),
              child: Divider(height: 1, thickness: 1, color: palette.border),
            ),
          _ReadingRow(reading: readings[index]),
        ],
      ],
    );
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({required this.reading});

  final InsightsReading reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = reading.detail;

    return Semantics(
      label: [reading.headline, reading.value, ?detail].join('. '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  reading.headline,
                  maxLines: 2,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: LuqaSpacing.md),
              Text(
                reading.value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (detail != null) ...[
            const SizedBox(height: LuqaSpacing.xs),
            Text(
              detail,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
