import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';

/// A single sync-state vocabulary for top-level destinations.
class LuqaSyncStatus extends StatelessWidget {
  const LuqaSyncStatus({
    required this.onRetry,
    this.pendingWrites = 0,
    this.isOffline = false,
    this.isRefreshing = false,
    this.controlKey,
    super.key,
  });

  final int pendingWrites;
  final bool isOffline;
  final bool isRefreshing;
  final VoidCallback onRetry;
  final Key? controlKey;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    if (pendingWrites > 0) {
      return Semantics(
        liveRegion: true,
        child: IconButton(
          key: controlKey,
          tooltip: pendingWrites == 1
              ? '1 change waiting to sync. Tap to retry'
              : '$pendingWrites changes waiting to sync. Tap to retry',
          onPressed: onRetry,
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_upload_outlined, size: 16, color: muted),
              const SizedBox(width: LuqaSpacing.xs),
              Text(
                '$pendingWrites',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      );
    }

    if (isOffline) {
      return IconButton(
        key: controlKey,
        tooltip: 'Offline. Tap to retry',
        onPressed: onRetry,
        icon: Icon(Icons.cloud_off_outlined, size: 16, color: muted),
      );
    }

    if (isRefreshing) {
      return Semantics(
        liveRegion: true,
        label: 'Refreshing',
        child: SizedBox.square(
          key: controlKey,
          dimension: 48,
          child: Center(
            child: SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 1.8, color: muted),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
