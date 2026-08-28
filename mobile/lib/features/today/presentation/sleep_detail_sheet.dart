import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';

/// Sleep arrives from the platform health store, so this reads it back rather
/// than offering to edit it. Corrections belong where the data is recorded.
Future<void> showSleepDetailSheet(BuildContext context, SleepEntry entry) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
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
    final stages = <(String, int?)>[
      ('Deep', entry.deepMinutes),
      ('REM', entry.remMinutes),
      ('Light', entry.lightMinutes),
      ('Awake', entry.awakeMinutes),
    ].where((stage) => (stage.$2 ?? 0) > 0).toList(growable: false);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
            Text(
              compactDuration(entry.asleep),
              style: theme.textTheme.displaySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: LuqaSpacing.xs),
            Text(
              '${clock(entry.start)} to ${clock(entry.end)} · '
              '${entry.attribution}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (stages.isNotEmpty) ...[
              const SizedBox(height: LuqaSpacing.xl),
              for (final stage in stages)
                Padding(
                  padding: const EdgeInsets.only(bottom: LuqaSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(stage.$1, style: theme.textTheme.bodyLarge),
                      ),
                      Text(
                        compactDuration(Duration(minutes: stage.$2!)),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
