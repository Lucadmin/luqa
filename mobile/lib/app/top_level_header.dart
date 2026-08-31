import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';

/// The shared chrome for Luqa's top-level destinations.
///
/// Each destination keeps its own focal content, while this frame keeps the
/// page inset, account entry point, and touch target stable between tabs.
class LuqaTopLevelHeader extends ConsumerWidget {
  const LuqaTopLevelHeader({
    required this.primary,
    this.contextualActions = const [],
    this.supporting,
    this.status,
    super.key,
  });

  final Widget primary;
  final List<Widget> contextualActions;
  final Widget? supporting;
  final Widget? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial =
        ref.watch(authControllerProvider).value?.user?.initial ?? 'L';
    final statusInPrimary = supporting == null && status != null;
    final hasContextualCluster =
        contextualActions.isNotEmpty || statusInPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LuqaSpacing.lg,
        LuqaSpacing.xl,
        LuqaSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Expanded(child: primary),
                if (statusInPrimary) status!,
                ...contextualActions,
                if (hasContextualCluster) const SizedBox(width: LuqaSpacing.sm),
                IconButton(
                  key: const ValueKey('top-level-account'),
                  tooltip: 'Account settings',
                  onPressed: () => context.push('/settings'),
                  padding: const EdgeInsets.all(LuqaSpacing.xs),
                  icon: DecoratedBox(
                    decoration: BoxDecoration(
                      color: LuqaPalette.of(context).raised,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 40,
                      child: Center(
                        child: Text(
                          initial,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (supporting != null) ...[
            const SizedBox(height: LuqaSpacing.xs),
            Row(
              children: [
                Expanded(child: supporting!),
                ?status,
              ],
            ),
          ],
        ],
      ),
    );
  }
}
