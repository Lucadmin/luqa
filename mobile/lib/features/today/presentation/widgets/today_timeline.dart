import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';

class TodayTimeline extends StatelessWidget {
  const TodayTimeline({
    required this.entries,
    required this.categories,
    super.key,
  });

  final List<TimeEntry> entries;
  final List<Category> categories;

  static const _hourHeight = 72.0;
  static const _gutter = 54.0;

  @override
  Widget build(BuildContext context) {
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    final earliest = entries.isEmpty
        ? 8
        : entries.map((entry) => entry.start.hour).reduce(math.min);
    final latest = entries.isEmpty
        ? 14
        : entries
              .map((entry) {
                final end = entry.endOrNow();
                return end.hour + (end.minute > 0 ? 1 : 0);
              })
              .reduce(math.max);
    final startHour = math.min(8, earliest);
    final endHour = math.max(14, latest);
    final height = (endHour - startHour) * _hourHeight;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          clipBehavior: Clip.none,
          children: [
            for (var hour = startHour; hour <= endHour; hour++)
              _HourRule(hour: hour, top: (hour - startHour) * _hourHeight),
            for (final entry in entries)
              _TimelineEntry(
                entry: entry,
                category: entry.categoryId == null
                    ? null
                    : categoryById[entry.categoryId],
                top: _minutesFrom(entry.start, startHour) * (_hourHeight / 60),
                height: math.max(
                  52,
                  entry.duration.inMinutes * (_hourHeight / 60) - 4,
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _minutesFrom(DateTime value, int startHour) =>
      (value.hour - startHour) * 60 + value.minute;
}

class _HourRule extends StatelessWidget {
  const _HourRule({required this.hour, required this.top});

  final int hour;
  final double top;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      left: 0,
      right: 0,
      top: top,
      child: Row(
        children: [
          SizedBox(
            width: TodayTimeline._gutter,
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(child: Divider(color: LuqaPalette.of(context).border)),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.entry,
    required this.category,
    required this.top,
    required this.height,
  });

  final TimeEntry entry;
  final Category? category;
  final double top;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final identity = category == null
        ? theme.colorScheme.onSurfaceVariant
        : Color(category!.colorValue);
    final background = identity.withValues(alpha: isDark ? 0.18 : 0.10);

    return Positioned(
      left: TodayTimeline._gutter,
      right: 0,
      top: top,
      height: height,
      child: Semantics(
        button: true,
        label:
            '${category?.name ?? 'No category'}, ${entry.description}, '
            '${clock(entry.start)} to '
            '${entry.end == null ? 'now' : clock(entry.end!)}',
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuqaRadii.control),
            side: BorderSide(color: identity.withValues(alpha: 0.48)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Entry editing is reserved in this slice.'),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuqaSpacing.md,
                vertical: LuqaSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: identity,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox.square(dimension: 8),
                      ),
                      const SizedBox(width: LuqaSpacing.sm),
                      Expanded(
                        child: Text(
                          category?.name ?? 'No category',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        '${clock(entry.start)} – '
                        '${entry.end == null ? 'Now' : clock(entry.end!)}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  if (height >= 68) ...[
                    const SizedBox(height: LuqaSpacing.xs),
                    Text(
                      entry.description.isEmpty
                          ? 'Untitled'
                          : entry.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (entry.pendingSync) ...[
                    const Spacer(),
                    Text(
                      'Waiting to sync',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
