import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/health/application/health_sync_controller.dart';
import 'package:luqa/features/health/data/health_connect_reader.dart';

/// Health Connect status and sync control, for the Settings screen.
class HealthConnectTile extends ConsumerStatefulWidget {
  const HealthConnectTile({super.key});

  @override
  ConsumerState<HealthConnectTile> createState() => _HealthConnectTileState();
}

class _HealthConnectTileState extends ConsumerState<HealthConnectTile> {
  @override
  void initState() {
    super.initState();
    // Permission can be revoked in Health Connect while the app is backgrounded,
    // so the status is read on open rather than cached across launches.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(healthSyncControllerProvider.notifier).refreshStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthSyncControllerProvider);
    final controller = ref.read(healthSyncControllerProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          minTileHeight: 56,
          leading: const Icon(Icons.bedtime_outlined),
          title: const Text('Health Connect'),
          subtitle: Text(_subtitle(state)),
          trailing: state.isBusy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: LuqaSpacing.xs),
            child: Text(
              state.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        if (state.lastResult != null && state.error == null)
          Padding(
            padding: const EdgeInsets.only(top: LuqaSpacing.xs),
            child: Text(state.lastResult!, style: theme.textTheme.bodySmall),
          ),
        Padding(
          padding: const EdgeInsets.only(top: LuqaSpacing.sm),
          child: Wrap(
            spacing: LuqaSpacing.sm,
            children: _actions(state, controller),
          ),
        ),
      ],
    );
  }

  List<Widget> _actions(HealthSyncState state, HealthSyncController controller) {
    if (state.availability == HealthAvailability.unsupportedPlatform) {
      return const [];
    }
    if (state.availability == HealthAvailability.notInstalled ||
        state.availability == HealthAvailability.updateRequired) {
      return [
        FilledButton.tonal(
          onPressed: state.isBusy ? null : controller.openInstall,
          child: Text(
            state.availability == HealthAvailability.updateRequired
                ? 'Update Health Connect'
                : 'Install Health Connect',
          ),
        ),
      ];
    }
    if (!state.permissionGranted) {
      return [
        FilledButton(
          onPressed: state.isBusy ? null : controller.requestPermission,
          child: const Text('Allow sleep access'),
        ),
      ];
    }
    return [
      FilledButton.tonal(
        onPressed: state.isBusy ? null : () => controller.sync(),
        child: const Text('Sync now'),
      ),
      TextButton(
        onPressed: state.isBusy ? null : () => controller.sync(full: true),
        child: const Text('Re-import 30 days'),
      ),
    ];
  }

  String _subtitle(HealthSyncState state) {
    switch (state.availability) {
      case null:
        return 'Checking availability…';
      case HealthAvailability.unsupportedPlatform:
        return 'Android only. iOS will sync through Apple Health later.';
      case HealthAvailability.notInstalled:
        return 'Not installed. Health Connect carries Samsung Health sleep.';
      case HealthAvailability.updateRequired:
        return 'Installed but out of date.';
      case HealthAvailability.available:
        if (!state.permissionGranted) {
          return 'Connected app, but sleep access has not been granted yet.';
        }
        final last = state.lastSyncedAt;
        return last == null
            ? 'Ready. Syncs automatically when you open Luqa.'
            : 'Syncs automatically · last synced ${_relative(last)}.';
    }
  }

  String _relative(DateTime time) {
    final elapsed = DateTime.now().difference(time);
    if (elapsed.inMinutes < 1) return 'just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    return '${elapsed.inDays}d ago';
  }
}
