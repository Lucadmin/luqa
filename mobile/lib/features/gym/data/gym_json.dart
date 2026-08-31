import 'package:luqa/features/gym/data/gym_repository.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

/// Codecs shared by the write queue and the read cache, so a workout written
/// by one is readable by the other.

Map<String, Object?> gymSetToJson(GymSet value) => {
  'weight': value.weight,
  'reps': value.reps,
  'note': value.note,
};

GymSet gymSetFromJson(Map<String, Object?> value) => GymSet(
  weight: (value['weight'] as num?)?.toDouble(),
  reps: value['reps'] as int?,
  note: value['note'] as String?,
);

Map<String, Object?> gymSessionToJson(GymSession value) => {
  'id': value.id,
  'dateKey': value.dateKey,
  'locationId': value.locationId,
  'notes': value.notes,
  'createdAt': value.createdAt.toUtc().toIso8601String(),
  'exercises': [
    for (final exercise in value.exercises)
      {
        'id': exercise.id,
        'exerciseId': exercise.exerciseId,
        'name': exercise.name,
        'order': exercise.order,
        'raw': exercise.raw,
        'notes': exercise.notes,
        'sets': [for (final set in exercise.sets) gymSetToJson(set)],
      },
  ],
};

GymSession gymSessionFromJson(Map<String, Object?> value) => GymSession(
  id: value['id']! as String,
  dateKey: value['dateKey']! as String,
  locationId: value['locationId'] as String?,
  notes: value['notes']! as String,
  createdAt: DateTime.parse(value['createdAt']! as String).toLocal(),
  exercises: [
    for (final item in value['exercises']! as List<Object?>)
      GymSessionExercise(
        id: (item! as Map<String, Object?>)['id']! as String,
        exerciseId: (item as Map<String, Object?>)['exerciseId']! as String,
        name: item['name']! as String,
        order: item['order']! as int,
        raw: item['raw']! as String,
        notes: item['notes']! as String,
        sets: [
          for (final set in item['sets']! as List<Object?>)
            gymSetFromJson(set! as Map<String, Object?>),
        ],
      ),
  ],
);

Map<String, Object?> gymWriteToJson(GymSessionWrite value) => {
  'dateKey': value.dateKey,
  'locationId': value.locationId,
  'notes': value.notes,
  'exercises': [
    for (final exercise in value.exercises)
      {
        'exerciseId': exercise.exerciseId,
        'name': exercise.name,
        'notes': exercise.notes,
        'sets': [
          for (final set in exercise.sets)
            {'weight': set.weight, 'reps': set.reps, 'note': set.note},
        ],
      },
  ],
};

GymSessionWrite gymWriteFromJson(Map<String, Object?> value) => GymSessionWrite(
  dateKey: value['dateKey']! as String,
  locationId: value['locationId'] as String?,
  notes: value['notes']! as String,
  exercises: [
    for (final item in value['exercises']! as List<Object?>)
      GymExerciseWrite(
        exerciseId: (item! as Map<String, Object?>)['exerciseId'] as String?,
        name: (item as Map<String, Object?>)['name']! as String,
        notes: item['notes']! as String,
        sets: [
          for (final set in item['sets']! as List<Object?>)
            GymSetWrite(
              weight: ((set! as Map<String, Object?>)['weight'] as num?)
                  ?.toDouble(),
              reps: (set as Map<String, Object?>)['reps'] as int?,
              note: set['note'] as String?,
            ),
        ],
      ),
  ],
);

Map<String, Object?> gymLocationToJson(GymLocation value) => {
  'id': value.id,
  'code': value.code,
  'name': value.name,
  'colorValue': value.colorValue,
  'order': value.order,
  'archived': value.archived,
};

GymLocation gymLocationFromJson(Map<String, Object?> value) => GymLocation(
  id: value['id']! as String,
  code: value['code']! as String,
  name: value['name']! as String,
  colorValue: value['colorValue']! as int,
  order: value['order']! as int,
  archived: value['archived']! as bool,
);

Map<String, Object?> gymExerciseToJson(GymExercise value) => {
  'id': value.id,
  'name': value.name,
  'notes': value.notes,
  'archived': value.archived,
  'sessionCount': value.sessionCount,
  'lastPerformed': value.lastPerformed,
  'locationIds': value.locationIds,
};

GymExercise gymExerciseFromJson(Map<String, Object?> value) => GymExercise(
  id: value['id']! as String,
  name: value['name']! as String,
  notes: value['notes']! as String,
  archived: value['archived']! as bool,
  sessionCount: value['sessionCount']! as int,
  lastPerformed: value['lastPerformed'] as String?,
  locationIds: [
    for (final id in value['locationIds']! as List<Object?>) id! as String,
  ],
);

Map<String, Object?> gymReferenceToJson(GymExerciseReference value) => {
  'exerciseId': value.exerciseId,
  'sessionId': value.sessionId,
  'dateKey': value.dateKey,
  'locationId': value.locationId,
  'raw': value.raw,
  'notes': value.notes,
  'sets': [for (final set in value.sets) gymSetToJson(set)],
};

GymExerciseReference gymReferenceFromJson(Map<String, Object?> value) =>
    GymExerciseReference(
      exerciseId: value['exerciseId']! as String,
      sessionId: value['sessionId']! as String,
      dateKey: value['dateKey']! as String,
      locationId: value['locationId'] as String?,
      raw: value['raw']! as String,
      notes: value['notes']! as String,
      sets: [
        for (final set in value['sets']! as List<Object?>)
          gymSetFromJson(set! as Map<String, Object?>),
      ],
    );

Map<String, Object?> gymOverviewToJson(GymOverview value) => {
  'locations': [
    for (final location in value.locations) gymLocationToJson(location),
  ],
  'exercises': [
    for (final exercise in value.exercises) gymExerciseToJson(exercise),
  ],
  'recentReferences': [
    for (final reference in value.recentReferences)
      gymReferenceToJson(reference),
  ],
  'sessions': [for (final session in value.sessions) gymSessionToJson(session)],
  'totalSessions': value.totalSessions,
};

GymOverview gymOverviewFromJson(Map<String, Object?> value) => GymOverview(
  locations: [
    for (final item in value['locations']! as List<Object?>)
      gymLocationFromJson(item! as Map<String, Object?>),
  ],
  exercises: [
    for (final item in value['exercises']! as List<Object?>)
      gymExerciseFromJson(item! as Map<String, Object?>),
  ],
  recentReferences: [
    for (final item in value['recentReferences']! as List<Object?>)
      gymReferenceFromJson(item! as Map<String, Object?>),
  ],
  sessions: [
    for (final item in value['sessions']! as List<Object?>)
      gymSessionFromJson(item! as Map<String, Object?>),
  ],
  totalSessions: value['totalSessions']! as int,
);
