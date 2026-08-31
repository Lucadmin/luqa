import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';
import 'package:luqa/features/today/presentation/widgets/hypnogram.dart';
import 'package:luqa/features/today/presentation/widgets/sleep_stage_palette.dart';

/// Sleep arrives from the platform health store, so this reads it back rather
/// than offering to edit it. Corrections belong where the data is recorded.
Future<void> showSleepDetailSheet(BuildContext context, SleepEntry entry) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
    ),
    builder: (context) => _SleepDetailSheet(entry: entry),
  );
}

class _SleepDetailSheet extends StatelessWidget {
  const _SleepDetailSheet({required this.entry});

  final SleepEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);
    final totals = entry.stageTotals;
    final scored = totals.values.fold(0, (sum, minutes) => sum + minutes);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime_outlined, size: 20, color: palette.blue),
                const SizedBox(width: LuqaSpacing.sm),
                Text(
                  entry.isNap ? 'Nap' : 'Sleep',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: LuqaSpacing.lg),

            // The one number worth reading first, at the size that says so.
            Text(
              compactDuration(entry.asleep),
              style: theme.textTheme.displaySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: LuqaSpacing.xs),
            Text(
              'asleep · ${clock(entry.start)} to ${clock(entry.end)} · '
              '${compactDuration(entry.inBed)} in bed',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            if (entry.hasStageTimeline) ...[
              const SizedBox(height: LuqaSpacing.xl),
              Hypnogram(entry: entry),
            ],

            if (scored > 0) ...[
              const SizedBox(height: LuqaSpacing.xl),
              _StageBar(totals: totals, scored: scored),
              const SizedBox(height: LuqaSpacing.md),
              _StageLegend(totals: totals, scored: scored),
            ],

            const SizedBox(height: LuqaSpacing.xl),
            _Metrics(entry: entry),

            if (!entry.hasStageTimeline && scored == 0) ...[
              const SizedBox(height: LuqaSpacing.lg),
              Text(
                '${entry.attribution} reported this night as a single block, '
                'without a stage breakdown.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: LuqaSpacing.xl),
            Text(
              [
                entry.attribution,
                if (entry.deviceModel != null) entry.deviceModel!,
                if (entry.recordingMethod != null)
                  _recordingLabel(entry.recordingMethod!),
              ].join(' · '),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _recordingLabel(String method) => switch (method.toUpperCase()) {
  'AUTOMATICALLY_RECORDED' => 'Recorded automatically',
  'ACTIVELY_RECORDED' => 'Recorded actively',
  'MANUAL_ENTRY' => 'Entered by hand',
  _ => 'Source unknown',
};

/// One bar for the whole night. A pie would make four values compete for angle
/// judgement; a single stacked bar keeps them on one shared length.
class _StageBar extends StatelessWidget {
  const _StageBar({required this.totals, required this.scored});

  final Map<SleepStageKind, int> totals;
  final int scored;

  @override
  Widget build(BuildContext context) {
    final present = [
      for (final kind in SleepStagePalette.order)
        if ((totals[kind] ?? 0) > 0) kind,
    ];

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LuqaRadii.compact),
        child: SizedBox(
          height: 12,
          child: Row(
            // Stretch, or a childless ColoredBox collapses to nothing and the
            // bar silently disappears.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final kind in present) ...[
                Expanded(
                  flex: totals[kind]!,
                  child: ColoredBox(color: SleepStagePalette.of(context, kind)),
                ),
                // A surface-coloured gap rather than a border, so segments
                // separate without a fifth colour entering the chart.
                if (kind != present.last) const SizedBox(width: 2),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Every stage is named with its own duration and share, so identity never
/// rests on colour alone.
class _StageLegend extends StatelessWidget {
  const _StageLegend({required this.totals, required this.scored});

  final Map<SleepStageKind, int> totals;
  final int scored;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final present = [
      for (final kind in SleepStagePalette.order)
        if ((totals[kind] ?? 0) > 0) kind,
    ];

    return Column(
      children: [
        for (final kind in present)
          Padding(
            padding: const EdgeInsets.only(bottom: LuqaSpacing.sm),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: SleepStagePalette.of(context, kind),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const SizedBox(width: 10, height: 10),
                ),
                const SizedBox(width: LuqaSpacing.md),
                Expanded(
                  child: Text(kind.label, style: theme.textTheme.bodyMedium),
                ),
                Text(
                  '${(totals[kind]! / scored * 100).round()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: LuqaSpacing.md),
                SizedBox(
                  width: 62,
                  child: Text(
                    compactDuration(Duration(minutes: totals[kind]!)),
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The numbers a night is judged by. Anything the provider did not report is
/// left out rather than shown as a zero, which would be a different claim.
class _Metrics extends StatelessWidget {
  const _Metrics({required this.entry});

  final SleepEntry entry;

  @override
  Widget build(BuildContext context) {
    final efficiency = entry.efficiency;
    final rows = <(String, String)>[
      if (efficiency != null) ('Efficiency', '${efficiency.round()}%'),
      if (entry.latencyMinutes != null)
        (
          'Fell asleep in',
          compactDuration(Duration(minutes: entry.latencyMinutes!)),
        ),
      if (entry.wasoMinutes != null)
        (
          'Awake after falling asleep',
          compactDuration(Duration(minutes: entry.wasoMinutes!)),
        ),
      if (entry.awakeningCount != null)
        ('Times woken', '${entry.awakeningCount}'),
      if (entry.midpoint != null) ('Midpoint', clock(entry.midpoint!)),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final palette = LuqaPalette.of(context);

    return Column(
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: LuqaSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        if (rows.isNotEmpty)
          Divider(color: palette.border.withValues(alpha: 0.6), height: 1),
      ],
    );
  }
}
