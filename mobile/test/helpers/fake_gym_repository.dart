import 'dart:async';

import 'package:luqa/features/gym/data/gym_repository.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

class FakeGymRepository implements GymRepository {
  FakeGymRepository({required this.overview, required this.histories});

  factory FakeGymRepository.sample() {
    const luqaGym = GymLocation(
      id: 'luqa-gym',
      code: 'LQA',
      name: 'Luqa Gym',
      colorValue: 0xFFC2410C,
      order: 0,
      archived: false,
    );
    const mcFit = GymLocation(
      id: 'mcfit',
      code: 'MFM',
      name: 'McFit Mitte',
      colorValue: 0xFF0F766E,
      order: 1,
      archived: false,
    );
    const exercise = GymExercise(
      id: 'lat-pulldown',
      name: 'Lat pulldown',
      notes: '',
      archived: false,
      sessionCount: 5,
      lastPerformed: '2026-08-25',
      locationIds: ['luqa-gym', 'mcfit'],
    );
    const luqaSets = [
      GymSet(weight: 72.5, reps: 10, note: null),
      GymSet(weight: 72.5, reps: 9, note: null),
      GymSet(weight: 70, reps: 11, note: null),
    ];
    const mcFitSets = [
      GymSet(weight: 65, reps: 12, note: null),
      GymSet(weight: 65, reps: 10, note: null),
    ];
    final current = GymSession(
      id: 'current-workout',
      dateKey: '2026-08-27',
      locationId: luqaGym.id,
      notes: '',
      exercises: const [
        GymSessionExercise(
          id: 'current-lat',
          exerciseId: 'lat-pulldown',
          name: 'Lat pulldown',
          order: 0,
          raw: '',
          notes: '',
          sets: [],
        ),
      ],
      createdAt: DateTime(2026, 8, 27, 15),
    );
    final previous = GymSession(
      id: 'previous-workout',
      dateKey: '2026-08-25',
      locationId: luqaGym.id,
      notes: '',
      exercises: const [
        GymSessionExercise(
          id: 'previous-lat',
          exerciseId: 'lat-pulldown',
          name: 'Lat pulldown',
          order: 0,
          raw: '72.5-10 72.5-9 70-11',
          notes: '',
          sets: luqaSets,
        ),
      ],
      createdAt: DateTime(2026, 8, 25, 15),
    );
    return FakeGymRepository(
      overview: GymOverview(
        locations: const [luqaGym, mcFit],
        exercises: const [exercise],
        recentReferences: const [
          GymExerciseReference(
            exerciseId: 'lat-pulldown',
            sessionId: 'previous-workout',
            dateKey: '2026-08-25',
            locationId: 'luqa-gym',
            raw: '72.5-10 72.5-9 70-11',
            notes: '',
            sets: luqaSets,
          ),
          GymExerciseReference(
            exerciseId: 'lat-pulldown',
            sessionId: 'mcfit-workout',
            dateKey: '2026-08-20',
            locationId: 'mcfit',
            raw: '65-12 65-10',
            notes: '',
            sets: mcFitSets,
          ),
        ],
        sessions: [current, previous],
        totalSessions: 2,
      ),
      histories: {
        'lat-pulldown:luqa-gym': GymExerciseHistory(
          exercise: exercise,
          points: const [
            GymExercisePoint(
              sessionId: 'previous-workout',
              dateKey: '2026-08-25',
              locationId: 'luqa-gym',
              raw: '72.5-10 72.5-9 70-11',
              notes: '',
              sets: luqaSets,
              topWeight: 72.5,
              bestOneRepMax: 96.67,
              totalReps: 30,
              volume: 2165,
              isPersonalRecord: false,
            ),
          ],
          bestEver: 96.67,
          heaviest: 72.5,
        ),
        'lat-pulldown:mcfit': GymExerciseHistory(
          exercise: exercise,
          points: const [
            GymExercisePoint(
              sessionId: 'mcfit-workout',
              dateKey: '2026-08-20',
              locationId: 'mcfit',
              raw: '65-12 65-10',
              notes: '',
              sets: mcFitSets,
              topWeight: 65,
              bestOneRepMax: 91,
              totalReps: 22,
              volume: 1430,
              isPersonalRecord: false,
            ),
          ],
          bestEver: 91,
          heaviest: 65,
        ),
      },
    );
  }

  GymOverview overview;
  final Map<String, GymExerciseHistory> histories;
  int saves = 0;
  Object? saveError;
  Completer<void>? saveStarted;
  Future<void>? saveGate;

  @override
  Future<GymOverview> loadOverview({int limit = 30}) async => overview;

  @override
  Future<GymSession> loadSession(String id) async =>
      overview.sessions.firstWhere((session) => session.id == id);

  @override
  Future<GymSession> createSession({
    String? id,
    required String dateKey,
    required String? locationId,
  }) async {
    final session = GymSession(
      id: id ?? 'new-workout',
      dateKey: dateKey,
      locationId: locationId,
      notes: '',
      exercises: const [],
      createdAt: DateTime(2026, 8, 27, 16),
    );
    overview = overview.copyWith(
      sessions: [session, ...overview.sessions],
      totalSessions: overview.totalSessions + 1,
    );
    return session;
  }

  @override
  Future<GymSession> saveSession(String id, GymSessionWrite write) async {
    saves += 1;
    final started = saveStarted;
    if (started != null && !started.isCompleted) started.complete();
    final gate = saveGate;
    if (gate != null) await gate;
    final error = saveError;
    if (error != null) throw error;
    final session = GymSession(
      id: id,
      dateKey: write.dateKey,
      locationId: write.locationId,
      notes: write.notes,
      exercises: [
        for (var index = 0; index < write.exercises.length; index += 1)
          GymSessionExercise(
            id: 'saved-$index',
            exerciseId: write.exercises[index].exerciseId ?? 'created-$index',
            name: write.exercises[index].name,
            order: index,
            raw: '',
            notes: write.exercises[index].notes,
            sets: [
              for (final set in write.exercises[index].sets)
                if (set.weight != null || set.reps != null || set.note != null)
                  GymSet(weight: set.weight, reps: set.reps, note: set.note),
            ],
          ),
      ],
      createdAt: DateTime(2026, 8, 27, 15),
    );
    overview = overview.copyWith(
      sessions: [session, ...overview.sessions.where((item) => item.id != id)],
    );
    return session;
  }

  @override
  Future<GymExerciseHistory> loadExerciseHistory(
    String exerciseId, {
    String? locationId,
    String? beforeSessionId,
  }) async {
    final key = '$exerciseId:${locationId ?? 'all'}';
    final direct = histories[key];
    if (direct != null) return direct;
    final exercise = overview.exerciseById(exerciseId)!;
    return GymExerciseHistory(
      exercise: exercise,
      points: const [],
      bestEver: null,
      heaviest: null,
    );
  }

  @override
  Future<GymExercise> mergeExercise({
    required String sourceExerciseId,
    required String targetExerciseId,
  }) async {
    final source = overview.exerciseById(sourceExerciseId)!;
    final oldTarget = overview.exerciseById(targetExerciseId)!;
    final target = GymExercise(
      id: oldTarget.id,
      name: oldTarget.name,
      notes: oldTarget.notes.isEmpty ? source.notes : oldTarget.notes,
      archived: false,
      sessionCount: oldTarget.sessionCount + source.sessionCount,
      lastPerformed:
          (oldTarget.lastPerformed ?? '').compareTo(
                source.lastPerformed ?? '',
              ) >=
              0
          ? oldTarget.lastPerformed
          : source.lastPerformed,
      locationIds: {...oldTarget.locationIds, ...source.locationIds}.toList(),
    );
    overview = applyExerciseMerge(
      overview,
      sourceExerciseId: sourceExerciseId,
      target: target,
    );
    return target;
  }

  @override
  Future<GymSessionPage> loadSessions({String? cursor, int limit = 20}) async =>
      GymSessionPage(sessions: overview.sessions, nextCursor: null);

  @override
  Future<GymLocation> createLocation({
    String? id,
    required String name,
    required String code,
    required int colorValue,
  }) async {
    final location = GymLocation(
      id: id ?? 'location-${overview.locations.length}',
      code: code,
      name: name,
      colorValue: colorValue,
      order: overview.locations.length,
      archived: false,
    );
    overview = overview.copyWith(locations: [...overview.locations, location]);
    return location;
  }

  @override
  Future<GymLocation> updateLocation({
    required String id,
    String? name,
    String? code,
    int? colorValue,
    bool? archived,
  }) async {
    final old = overview.locationById(id)!;
    final updated = GymLocation(
      id: old.id,
      code: code ?? old.code,
      name: name ?? old.name,
      colorValue: colorValue ?? old.colorValue,
      order: old.order,
      archived: archived ?? old.archived,
    );
    overview = overview.copyWith(
      locations: [
        for (final location in overview.locations)
          if (location.id == id) updated else location,
      ],
    );
    return updated;
  }
}
