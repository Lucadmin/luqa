import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/gym/application/gym_overview_controller.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(_redraw);
  }

  @override
  void dispose() {
    _search
      ..removeListener(_redraw)
      ..dispose();
    super.dispose();
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gymOverviewControllerProvider);
    final overview = state.overview;
    final query = _search.text.trim().toLowerCase();
    final exercises =
        overview?.exercises
            .where(
              (exercise) =>
                  !exercise.archived &&
                  (query.isEmpty ||
                      exercise.name.toLowerCase().contains(query)),
            )
            .toList(growable: false) ??
        const <GymExercise>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      body: overview == null
          ? Center(
              child: state.isLoading
                  ? const CircularProgressIndicator()
                  : FilledButton(
                      onPressed: ref
                          .read(gymOverviewControllerProvider.notifier)
                          .load,
                      child: const Text('Try again'),
                    ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    LuqaSpacing.lg,
                    LuqaSpacing.sm,
                    LuqaSpacing.lg,
                    LuqaSpacing.lg,
                  ),
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      hintText: 'Search exercises',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                Expanded(
                  child: exercises.isEmpty
                      ? Center(
                          child: Text(
                            query.isEmpty
                                ? 'Exercises appear as you add them to workouts.'
                                : 'No exercise matches “${_search.text.trim()}”.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: LuqaSpacing.lg,
                          ),
                          itemCount: exercises.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final exercise = exercises[index];
                            final reference = _latestReference(
                              overview,
                              exercise.id,
                            );
                            final location = overview.locationById(
                              reference?.locationId,
                            );
                            return InkWell(
                              onTap: () {
                                final query = reference?.locationId == null
                                    ? ''
                                    : '?locationId=${Uri.encodeQueryComponent(reference!.locationId!)}';
                                context.push(
                                  '/gym/exercises/${exercise.id}/history$query',
                                );
                              },
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 68,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            exercise.name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge,
                                          ),
                                          const SizedBox(
                                            height: LuqaSpacing.xs,
                                          ),
                                          Text(
                                            reference == null
                                                ? 'No history yet'
                                                : [
                                                    if (location != null)
                                                      location.name,
                                                    reference.raw,
                                                  ].join(' · '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontFeatures: const [
                                                    FontFeature.tabularFigures(),
                                                  ],
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
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

GymExerciseReference? _latestReference(
  GymOverview overview,
  String exerciseId,
) {
  GymExerciseReference? latest;
  for (final reference in overview.recentReferences) {
    if (reference.exerciseId != exerciseId) continue;
    if (latest == null || reference.dateKey.compareTo(latest.dateKey) > 0) {
      latest = reference;
    }
  }
  return latest;
}
