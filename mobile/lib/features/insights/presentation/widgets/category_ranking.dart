import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/insights/domain/insights_models.dart';
import 'package:luqa/features/insights/presentation/insights_formatters.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';

/// Where the time went, ranked, with what it was last time beside it.
///
/// A ring would have been the obvious chart and the wrong one: a dozen slices
/// of a circle cannot be compared by eye, cannot carry their own labels, and
/// have nowhere to put the number that actually matters here — whether this is
/// more or less than the span before.
class CategoryRanking extends StatelessWidget {
  const CategoryRanking({
    required this.standings,
    required this.total,
    this.showDelta = true,
    super.key,
  });

  final List<CategoryStanding> standings;
  final double total;

  /// Off for a single selected day, which has nothing meaningful to be
  /// compared against.
  final bool showDelta;

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty || total <= 0) {
      return Text(
        'Nothing tracked here yet.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final leader = standings.first.minutes;
    return Column(
      children: [
        for (var index = 0; index < standings.length; index++) ...[
          if (index > 0) const SizedBox(height: LuqaSpacing.md),
          _StandingRow(
            standing: standings[index],
            share: standings[index].minutes / total,
            // Bars are measured against the leader rather than the total, so
            // a span split across eight categories still has something to
            // look at instead of eight identical stubs.
            fill: standings[index].minutes / leader,
            showDelta: showDelta,
          ),
        ],
      ],
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    required this.standing,
    required this.share,
    required this.fill,
    required this.showDelta,
  });

  final CategoryStanding standing;
  final double share;
  final double fill;
  final bool showDelta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final color = standing.colorValue == null
        ? palette.muted
        : Color(standing.colorValue!);
    final duration = compactDuration(
      Duration(minutes: standing.minutes.round()),
    );
    final delta = standing.delta;
    final showsChange = showDelta && !standing.isNew && delta.abs() >= 5;

    return Semantics(
      label: [
        standing.name,
        duration,
        percent(share),
        if (showsChange) '${signedDuration(delta)} against the span before',
        if (showDelta && standing.isNew) 'new this span',
      ].join(', '),
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
                  standing.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              const SizedBox(width: LuqaSpacing.sm),
              Text(
                duration,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: LuqaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(LuqaRadii.indicator),
                  child: LinearProgressIndicator(
                    value: fill.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: palette.raised,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: LuqaSpacing.md),
              SizedBox(
                width: 108,
                child: Text(
                  showsChange
                      ? '${percent(share)}  ·  ${signedDuration(delta)}'
                      : showDelta && standing.isNew
                      ? '${percent(share)}  ·  new'
                      : percent(share),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: muted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
