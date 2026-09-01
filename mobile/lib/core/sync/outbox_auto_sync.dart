import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/features/gym/application/gym_sync_engine.dart';
import 'package:luqa/features/habits/application/habits_sync_engine.dart';
import 'package:luqa/features/money/application/money_sync_engine.dart';
import 'package:luqa/features/today/application/sync_engine.dart';

/// Gives every queue of local writes a chance to drain whenever the app comes
/// back to the foreground.
///
/// The engine retries on its own timer, but that timer backs off to minutes
/// once a network is refusing — exactly the state a phone is in while it has no
/// signal. Coming back into the foreground is the strongest hint available that
/// the situation may have changed, and it costs one request to find out.
///
/// Mounted in the signed-in branch of the app, so it also fires on sign-in,
/// which is when a queue stranded by an expired session can finally move.
class OutboxAutoSync extends ConsumerStatefulWidget {
  const OutboxAutoSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<OutboxAutoSync> createState() => _OutboxAutoSyncState();
}

class _OutboxAutoSyncState extends ConsumerState<OutboxAutoSync>
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
    if (lifecycle == AppLifecycleState.resumed) _trigger();
  }

  void _trigger() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(syncEngineProvider.notifier).sync();
      ref.read(gymSyncEngineProvider.notifier).sync();
      ref.read(moneySyncEngineProvider.notifier).sync();
      ref.read(habitsSyncEngineProvider.notifier).sync();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
