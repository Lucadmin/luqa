import 'package:flutter/material.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/design_system/luqa_tokens.dart';

/// Tells the user about a change of theirs that could not be saved.
///
/// This is the one place in Luqa where the app admits it lost something. The
/// server understood the write and refused it, so retrying is not on offer and
/// pretending otherwise would be a lie; what the user needs is to know *what*
/// went missing, in enough detail to enter it again.
///
/// It is not a snackbar. A snackbar is gone in four seconds whether or not
/// anybody read it, and this is the last trace of work the user did.
class DiscardedWritesNotice extends StatelessWidget {
  const DiscardedWritesNotice({
    required this.discarded,
    required this.onAcknowledge,
    super.key,
  });

  final List<DiscardedWrite> discarded;

  /// Dismissing is the only action there is — the write itself is long gone.
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    if (discarded.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    final first = discarded.first;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: const ValueKey('discarded-writes'),
        padding: const EdgeInsets.all(LuqaSpacing.md),
        decoration: BoxDecoration(
          color: error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(LuqaRadii.surface),
          border: Border.all(color: error.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded, size: 18, color: error),
                const SizedBox(width: LuqaSpacing.sm),
                Expanded(
                  child: Text(
                    discarded.length == 1
                        ? "Couldn't save ${first.description}"
                        : "Couldn't save ${discarded.length} of your changes",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: LuqaSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // One reason reads as an explanation; five read as a log.
                  // Beyond the first, the names are what matter — they are
                  // what has to be entered again.
                  if (discarded.length == 1)
                    Text(
                      first.reason,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    for (final entry in discarded.take(4))
                      Text(
                        '· ${entry.description}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  if (discarded.length > 4)
                    Text(
                      '· and ${discarded.length - 4} more',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: LuqaSpacing.xs),
                  Text(
                    'You will need to enter it again.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const ValueKey('discarded-writes-dismiss'),
                      onPressed: onAcknowledge,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: LuqaSpacing.sm,
                        ),
                      ),
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
