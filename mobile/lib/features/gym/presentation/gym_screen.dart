import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/gym/application/gym_overview_controller.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';
import 'package:luqa/features/gym/presentation/gym_picker_sheet.dart';
import 'package:luqa/features/gym/presentation/widgets/gym_session_row.dart';

class GymScreen extends ConsumerWidget {
  const GymScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gymOverviewControllerProvider);
    final controller = ref.read(gymOverviewControllerProvider.notifier);
    final overview = state.overview;
    final now = ref.watch(gymNowProvider);

    if (state.isLoading && overview == null) {
      return const SafeArea(child: _GymSkeleton());
    }
    if (overview == null) {
      return SafeArea(
        child: _GymLoadError(
          message: state.error ?? 'Could not load gym data.',
          onRetry: controller.load,
        ),
      );
    }

    final current = state.currentSession(now);
    final recent = overview.sessions
        .where((session) => session.id != current?.id)
        .take(3)
        .toList(growable: false);

    Future<void> startWorkout() async {
      final activeLocations = overview.locations
          .where((location) => !location.archived)
          .toList(growable: false);
      final previousLocation = overview.sessions
          .map((session) => session.locationId)
          .whereType<String>()
          .cast<String?>()
          .firstOrNull;
      final defaultLocation =
          previousLocation ??
          (activeLocations.isEmpty ? null : activeLocations.first.id);
      final selection = await showGymPickerSheet(
        context,
        locations: overview.locations,
        selectedId: defaultLocation,
      );
      if (selection == null || !context.mounted) return;
      if (selection.manage) {
        context.push('/gym/locations');
        return;
      }
      final session = await controller.startWorkout(
        locationId: selection.locationId,
      );
      if (session != null && context.mounted) {
        context.push('/gym/workouts/${session.id}');
      }
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LuqaSpacing.lg,
                LuqaSpacing.xl,
                LuqaSpacing.lg,
                LuqaSpacing.section,
              ),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Gym',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      // What is waiting to go out matters more than what is
                      // coming in: it is the user's own training, and the one
                      // thing they might want to stay on this screen for.
                      if (state.pendingWrites > 0)
                        _PendingChip(
                          count: state.pendingWrites,
                          onRetry: controller.refresh,
                        ),
                      IconButton(
                        tooltip: 'Manage gyms',
                        onPressed: () => context.push('/gym/locations'),
                        icon: const Icon(Icons.location_on_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: LuqaSpacing.xxl),
                  if (current != null)
                    _CurrentWorkout(
                      session: current,
                      location: overview.locationById(current.locationId),
                      onTap: () => context.push('/gym/workouts/${current.id}'),
                    )
                  else
                    _StartWorkout(onTap: startWorkout),
                  if (state.error != null) ...[
                    const SizedBox(height: LuqaSpacing.md),
                    _InlineError(
                      message: state.error!,
                      onRetry: controller.refresh,
                    ),
                  ],
                  const SizedBox(height: LuqaSpacing.section),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recent workouts',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: overview.sessions.isEmpty
                            ? null
                            : () => context.push('/gym/history'),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: LuqaSpacing.sm),
                  if (recent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: LuqaSpacing.xl,
                      ),
                      child: Text(
                        current == null
                            ? 'Your workouts will collect here.'
                            : 'This is your first recorded workout.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    for (var index = 0; index < recent.length; index += 1) ...[
                      GymSessionRow(
                        session: recent[index],
                        location: overview.locationById(
                          recent[index].locationId,
                        ),
                        now: now,
                        onTap: () =>
                            context.push('/gym/workouts/${recent[index].id}'),
                      ),
                      if (index < recent.length - 1) const Divider(),
                    ],
                  const SizedBox(height: LuqaSpacing.section),
                  _LibraryLink(
                    title: 'Exercises',
                    detail:
                        '${overview.exercises.where((item) => !item.archived).length} in your history',
                    onTap: () => context.push('/gym/exercises'),
                  ),
                  const Divider(),
                  _LibraryLink(
                    title: 'Gyms',
                    detail:
                        '${overview.locations.where((item) => !item.archived).length} locations',
                    onTap: () => context.push('/gym/locations'),
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

class _PendingChip extends StatelessWidget {
  const _PendingChip({required this.count, required this.onRetry});

  final int count;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      liveRegion: true,
      child: IconButton(
        key: const ValueKey('gym-pending-writes'),
        tooltip: count == 1
            ? '1 change waiting to sync. Tap to retry'
            : '$count changes waiting to sync. Tap to retry',
        onPressed: onRetry,
        visualDensity: VisualDensity.compact,
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 16, color: muted),
            const SizedBox(width: 3),
            Text(
              '$count',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentWorkout extends StatelessWidget {
  const _CurrentWorkout({
    required this.session,
    required this.location,
    required this.onTap,
  });

  final GymSession session;
  final GymLocation? location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.onSurface,
      borderRadius: BorderRadius.circular(LuqaRadii.control),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LuqaRadii.control),
        child: Padding(
          padding: const EdgeInsets.all(LuqaSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue workout',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    const SizedBox(height: LuqaSpacing.sm),
                    Text(
                      [
                        if (location != null) location!.name,
                        '${session.exercises.length} exercises',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.surface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: Theme.of(context).colorScheme.surface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartWorkout extends StatelessWidget {
  const _StartWorkout({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // No busy state: the workout exists on the phone the moment this is
    // tapped, and the screen for it opens straight away.
    return SizedBox(
      height: 64,
      child: FilledButton(
        onPressed: onTap,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('Start workout'), Icon(Icons.arrow_forward_rounded)],
        ),
      ),
    );
  }
}

class _LibraryLink extends StatelessWidget {
  const _LibraryLink({
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  Text(
                    detail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.cloud_off_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: LuqaSpacing.sm),
        Expanded(child: Text(message)),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _GymSkeleton extends StatelessWidget {
  const _GymSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = LuqaPalette.of(context).raised;
    Widget block(double height, {double? width}) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(LuqaRadii.compact),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(LuqaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(32, width: 100),
          const SizedBox(height: LuqaSpacing.xxl),
          block(64),
          const SizedBox(height: LuqaSpacing.section),
          block(24, width: 170),
          const SizedBox(height: LuqaSpacing.lg),
          block(68),
          const SizedBox(height: LuqaSpacing.sm),
          block(68),
        ],
      ),
    );
  }
}

class _GymLoadError extends StatelessWidget {
  const _GymLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(LuqaSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 32),
          const SizedBox(height: LuqaSpacing.lg),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: LuqaSpacing.lg),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
