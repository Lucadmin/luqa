import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/features/health/application/health_sync_controller.dart';

/// Drives automatic sleep sync off the app lifecycle.
///
/// Mounted inside the signed-in branch of the app, so it starts on sign-in and
/// stops on sign-out without needing to check auth itself — a push would fail
/// without a session anyway.
///
/// Foreground-only, deliberately. Reading Health Connect from a background
/// worker needs `READ_HEALTH_DATA_IN_BACKGROUND`, which Play reviews separately.
/// For sleep it buys little: a night is written once, and syncing the moment the
/// app opens means the data is there before it can be looked at.
class HealthAutoSync extends ConsumerStatefulWidget {
  const HealthAutoSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<HealthAutoSync> createState() => _HealthAutoSyncState();
}

class _HealthAutoSyncState extends ConsumerState<HealthAutoSync>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _trigger();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    // Resume covers the case that matters: the phone wrote the night while the
    // app was backgrounded, and it is reopened in the morning. The controller
    // throttles, so a quick app switch does not re-sync.
    if (lifecycle == AppLifecycleState.resumed) _trigger();
  }

  void _trigger() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(healthSyncControllerProvider.notifier).autoSync();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
