import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luqa/design_system/luqa_tokens.dart';
import 'package:luqa/features/gym/application/gym_overview_controller.dart';
import 'package:luqa/features/gym/data/gym_providers.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';
import 'package:luqa/features/gym/presentation/widgets/gym_session_row.dart';

class GymHistoryScreen extends ConsumerStatefulWidget {
  const GymHistoryScreen({super.key});

  @override
  ConsumerState<GymHistoryScreen> createState() => _GymHistoryScreenState();
}

class _GymHistoryScreenState extends ConsumerState<GymHistoryScreen> {
  List<GymSession> _sessions = const [];
  String? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadFirst);
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(gymRepositoryProvider).loadSessions();
      if (!mounted) return;
      setState(() {
        _sessions = page.sessions;
        _nextCursor = page.nextCursor;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load workout history.';
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(gymRepositoryProvider)
          .loadSessions(cursor: cursor);
      if (!mounted) return;
      setState(() {
        _sessions = [..._sessions, ...page.sessions];
        _nextCursor = page.nextCursor;
        _loadingMore = false;
      });
    } on Object {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(gymOverviewControllerProvider).overview;
    final now = ref.watch(gymNowProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Workout history')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: FilledButton(
                onPressed: _loadFirst,
                child: const Text('Try again'),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadFirst,
              child: _sessions.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(LuqaSpacing.xl),
                      children: const [Text('No workouts yet.')],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        LuqaSpacing.lg,
                        LuqaSpacing.sm,
                        LuqaSpacing.lg,
                        LuqaSpacing.section,
                      ),
                      itemCount: _sessions.length + 1,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        if (index == _sessions.length) {
                          if (_nextCursor == null) {
                            return const SizedBox(height: LuqaSpacing.xl);
                          }
                          return SizedBox(
                            height: 64,
                            child: Center(
                              child: TextButton(
                                onPressed: _loadingMore ? null : _loadMore,
                                child: Text(
                                  _loadingMore ? 'Loading…' : 'Load more',
                                ),
                              ),
                            ),
                          );
                        }
                        final session = _sessions[index];
                        return GymSessionRow(
                          session: session,
                          location: overview?.locationById(session.locationId),
                          now: now,
                          onTap: () =>
                              context.push('/gym/workouts/${session.id}'),
                        );
                      },
                    ),
            ),
    );
  }
}
