import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/gym/data/gym_repository.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';
import 'package:luqa_api/api.dart' as api;

class RemoteGymRepository implements GymRepository {
  const RemoteGymRepository(this.client);

  final LuqaApi client;

  @override
  Future<GymOverview> loadOverview({int limit = 30}) async =>
      _overviewFromApi(await client.getGymOverview(limit: limit));

  @override
  Future<GymSession> createSession({
    String? id,
    required String dateKey,
    required String? locationId,
  }) async => gymSessionFromApi(
    await client.createGymSession(
      api.CreateGymSessionRequest(
        id: id == null ? const api.Optional.absent() : api.Optional.present(id),
        date: api.Optional.present(dateKey),
        locationId: api.Optional.present(locationId),
        exercises: const api.Optional.absent(),
      ),
    ),
  );

  @override
  Future<GymSession> loadSession(String id) async =>
      gymSessionFromApi(await client.getGymSession(id));

  @override
  Future<GymSession> saveSession(String id, GymSessionWrite write) async {
    final request = api.UpdateGymSessionRequest(
      date: api.Optional.present(write.dateKey),
      locationId: api.Optional.present(write.locationId),
      notes: api.Optional.present(write.notes),
      exercises: api.Optional.present([
        for (final exercise in write.exercises)
          api.GymSessionExerciseInput(
            exerciseId: exercise.exerciseId == null
                ? const api.Optional.absent()
                : api.Optional.present(exercise.exerciseId),
            name: exercise.exerciseId == null
                ? api.Optional.present(exercise.name)
                : const api.Optional.absent(),
            notes: api.Optional.present(exercise.notes),
            sets: api.Optional.present([
              for (final set in exercise.sets)
                api.GymSetInput(
                  weight: api.Optional.present(set.weight),
                  reps: api.Optional.present(set.reps),
                  note: api.Optional.present(set.note),
                ),
            ]),
          ),
      ]),
    );
    return gymSessionFromApi(await client.updateGymSession(id, request));
  }

  @override
  Future<GymSession> endSession(String id, DateTime? endedAt) async =>
      gymSessionFromApi(
        await client.updateGymSession(
          id,
          api.UpdateGymSessionRequest(
            // The Dart generator defaults optional arrays to a present empty
            // list. A finish-only PATCH must not therefore become
            // `exercises: []`, which is an intentional full replacement on
            // the server.
            exercises: const api.Optional.absent(),
            endedAt: api.Optional.present(endedAt),
          ),
        ),
      );

  @override
  Future<void> deleteSession(String id) => client.deleteGymSession(id);

  @override
  Future<GymSessionPage> loadSessions({String? cursor, int limit = 20}) async {
    final response = await client.listGymSessions(cursor: cursor, limit: limit);
    return GymSessionPage(
      sessions: response.sessions
          .map(gymSessionFromApi)
          .toList(growable: false),
      nextCursor: response.nextCursor,
    );
  }

  @override
  Future<GymExerciseHistory> loadExerciseHistory(
    String exerciseId, {
    String? locationId,
    String? beforeSessionId,
  }) async => _historyFromApi(
    await client.getGymExerciseHistory(
      exerciseId,
      locationId: locationId,
      beforeSessionId: beforeSessionId,
    ),
  );

  @override
  Future<GymExerciseUpdate> updateExercise({
    required String id,
    String? name,
    String? notes,
    bool? archived,
  }) async {
    final response = await client.updateGymExercise(
      id,
      api.UpdateGymExerciseRequest(
        name: name == null
            ? const api.Optional.absent()
            : api.Optional.present(name),
        notes: notes == null
            ? const api.Optional.absent()
            : api.Optional.present(notes),
        archived: archived == null
            ? const api.Optional.absent()
            : api.Optional.present(archived),
      ),
    );
    return GymExerciseUpdate(
      exercise: gymExerciseFromApi(response.exercise),
      mergedInto: response.mergedInto,
    );
  }

  @override
  Future<GymExerciseRemoval> deleteExercise(String id) async {
    final response = await client.deleteGymExercise(id);
    return GymExerciseRemoval(
      deleted: response.deleted,
      archived: response.archived,
    );
  }

  @override
  Future<GymExercise> mergeExercise({
    required String sourceExerciseId,
    required String targetExerciseId,
  }) async => gymExerciseFromApi(
    await client.mergeGymExercise(sourceExerciseId, targetExerciseId),
  );

  @override
  Future<GymLocation> createLocation({
    String? id,
    required String name,
    required String code,
    required int colorValue,
  }) async => gymLocationFromApi(
    await client.createGymLocation(
      api.CreateGymLocationRequest(
        id: id == null ? const api.Optional.absent() : api.Optional.present(id),
        code: code,
        name: name,
        color: api.Optional.present(_hexColor(colorValue)),
      ),
    ),
  );

  @override
  Future<GymLocation> updateLocation({
    required String id,
    String? name,
    String? code,
    int? colorValue,
    bool? archived,
  }) async => gymLocationFromApi(
    await client.updateGymLocation(
      id,
      api.UpdateGymLocationRequest(
        name: name == null
            ? const api.Optional.absent()
            : api.Optional.present(name),
        code: code == null
            ? const api.Optional.absent()
            : api.Optional.present(code),
        color: colorValue == null
            ? const api.Optional.absent()
            : api.Optional.present(_hexColor(colorValue)),
        archived: archived == null
            ? const api.Optional.absent()
            : api.Optional.present(archived),
      ),
    ),
  );
}

GymOverview _overviewFromApi(api.GymOverview value) => GymOverview(
  locations: value.locations.map(gymLocationFromApi).toList(growable: false),
  exercises: value.exercises.map(gymExerciseFromApi).toList(growable: false),
  recentReferences: value.recentReferences
      .map(_referenceFromApi)
      .toList(growable: false),
  sessions: value.sessions.map(gymSessionFromApi).toList(growable: false),
  totalSessions: value.totalSessions,
);

GymLocation gymLocationFromApi(api.GymLocation value) => GymLocation(
  id: value.id,
  code: value.code,
  name: value.name,
  colorValue: _colorValue(value.color),
  order: value.order,
  archived: value.archived,
);

GymSet _setFromApi(api.GymSet value) => GymSet(
  weight: value.weight?.toDouble(),
  reps: value.reps,
  note: value.note,
);

GymSessionExercise _sessionExerciseFromApi(api.GymSessionExercise value) =>
    GymSessionExercise(
      id: value.id,
      exerciseId: value.exerciseId,
      name: value.name,
      order: value.order,
      raw: value.raw,
      notes: value.notes,
      sets: value.sets.map(_setFromApi).toList(growable: false),
    );

GymSession gymSessionFromApi(api.GymSession value) => GymSession(
  id: value.id,
  dateKey: value.date,
  locationId: value.locationId,
  notes: value.notes,
  exercises: value.exercises
      .map(_sessionExerciseFromApi)
      .toList(growable: false),
  createdAt: value.createdAt.toLocal(),
  updatedAt: value.updatedAt.toLocal(),
  endedAt: value.endedAt?.toLocal(),
);

GymExercise gymExerciseFromApi(api.GymExercise value) => GymExercise(
  id: value.id,
  name: value.name,
  notes: value.notes,
  archived: value.archived,
  sessionCount: value.sessionCount,
  lastPerformed: value.lastPerformed,
  locationIds: value.locationIds,
);

GymExerciseReference _referenceFromApi(api.GymExerciseReference value) =>
    GymExerciseReference(
      exerciseId: value.exerciseId,
      sessionId: value.sessionId,
      dateKey: value.date,
      locationId: value.locationId,
      raw: value.raw,
      notes: value.notes,
      sets: value.sets.map(_setFromApi).toList(growable: false),
    );

GymExercisePoint _pointFromApi(api.GymExercisePoint value) => GymExercisePoint(
  sessionId: value.sessionId,
  dateKey: value.date,
  locationId: value.locationId,
  raw: value.raw,
  notes: value.notes,
  sets: value.sets.map(_setFromApi).toList(growable: false),
  topWeight: value.topWeight?.toDouble(),
  bestOneRepMax: value.best1RM?.toDouble(),
  totalReps: value.totalReps,
  volume: value.volume.toDouble(),
  isPersonalRecord: value.isPr,
);

GymExerciseHistory _historyFromApi(api.GymExerciseHistory value) =>
    GymExerciseHistory(
      exercise: gymExerciseFromApi(value.exercise),
      points: value.points.map(_pointFromApi).toList(growable: false),
      bestEver: value.bestEver?.toDouble(),
      heaviest: value.heaviest?.toDouble(),
    );

String _hexColor(int value) =>
    '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

int _colorValue(String value) {
  final hex = value.startsWith('#') ? value.substring(1) : value;
  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? 0xFF6543E8 : 0xFF000000 | parsed;
}
