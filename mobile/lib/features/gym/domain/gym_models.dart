class GymLocation {
  const GymLocation({
    required this.id,
    required this.code,
    required this.name,
    required this.colorValue,
    required this.order,
    required this.archived,
  });

  final String id;
  final String code;
  final String name;
  final int colorValue;
  final int order;
  final bool archived;
}

class GymSet {
  const GymSet({required this.weight, required this.reps, required this.note});

  final double? weight;
  final int? reps;
  final String? note;
}

class GymSessionExercise {
  const GymSessionExercise({
    required this.id,
    required this.exerciseId,
    required this.name,
    required this.order,
    required this.raw,
    required this.notes,
    required this.sets,
  });

  final String id;
  final String exerciseId;
  final String name;
  final int order;
  final String raw;
  final String notes;
  final List<GymSet> sets;
}

class GymSession {
  const GymSession({
    required this.id,
    required this.dateKey,
    required this.locationId,
    required this.notes,
    required this.exercises,
    required this.createdAt,
  });

  final String id;
  final String dateKey;
  final String? locationId;
  final String notes;
  final List<GymSessionExercise> exercises;
  final DateTime createdAt;

  int get completedSetCount => exercises.fold(
    0,
    (sum, exercise) =>
        sum +
        exercise.sets
            .where((set) => set.weight != null || set.reps != null)
            .length,
  );
}

class GymExercise {
  const GymExercise({
    required this.id,
    required this.name,
    required this.notes,
    required this.archived,
    required this.sessionCount,
    required this.lastPerformed,
    required this.locationIds,
  });

  final String id;
  final String name;
  final String notes;
  final bool archived;
  final int sessionCount;
  final String? lastPerformed;
  final List<String> locationIds;
}

class GymExerciseReference {
  const GymExerciseReference({
    required this.exerciseId,
    required this.sessionId,
    required this.dateKey,
    required this.locationId,
    required this.raw,
    required this.notes,
    required this.sets,
  });

  final String exerciseId;
  final String sessionId;
  final String dateKey;
  final String? locationId;
  final String raw;
  final String notes;
  final List<GymSet> sets;
}

class GymOverview {
  const GymOverview({
    required this.locations,
    required this.exercises,
    required this.recentReferences,
    required this.sessions,
    required this.totalSessions,
  });

  final List<GymLocation> locations;
  final List<GymExercise> exercises;
  final List<GymExerciseReference> recentReferences;
  final List<GymSession> sessions;
  final int totalSessions;

  GymLocation? locationById(String? id) {
    if (id == null) return null;
    for (final location in locations) {
      if (location.id == id) return location;
    }
    return null;
  }

  GymExercise? exerciseById(String id) {
    for (final exercise in exercises) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  GymExerciseReference? referenceFor(String exerciseId, String? locationId) {
    for (final reference in recentReferences) {
      if (reference.exerciseId == exerciseId &&
          reference.locationId == locationId) {
        return reference;
      }
    }
    return null;
  }

  GymOverview copyWith({
    List<GymLocation>? locations,
    List<GymExercise>? exercises,
    List<GymExerciseReference>? recentReferences,
    List<GymSession>? sessions,
    int? totalSessions,
  }) => GymOverview(
    locations: locations ?? this.locations,
    exercises: exercises ?? this.exercises,
    recentReferences: recentReferences ?? this.recentReferences,
    sessions: sessions ?? this.sessions,
    totalSessions: totalSessions ?? this.totalSessions,
  );
}

class GymExercisePoint {
  const GymExercisePoint({
    required this.sessionId,
    required this.dateKey,
    required this.locationId,
    required this.raw,
    required this.notes,
    required this.sets,
    required this.topWeight,
    required this.bestOneRepMax,
    required this.totalReps,
    required this.volume,
    required this.isPersonalRecord,
  });

  final String sessionId;
  final String dateKey;
  final String? locationId;
  final String raw;
  final String notes;
  final List<GymSet> sets;
  final double? topWeight;
  final double? bestOneRepMax;
  final int totalReps;
  final double volume;
  final bool isPersonalRecord;
}

class GymExerciseHistory {
  const GymExerciseHistory({
    required this.exercise,
    required this.points,
    required this.bestEver,
    required this.heaviest,
  });

  final GymExercise exercise;
  final List<GymExercisePoint> points;
  final double? bestEver;
  final double? heaviest;

  GymExercisePoint? get lastPoint => points.isEmpty ? null : points.last;
}

/// What came back from editing an exercise.
///
/// [mergedInto] is set when the new name already belonged to another exercise
/// and the server folded the two together instead of refusing the rename. The
/// exercise that was edited no longer exists in that case; [exercise] is the
/// one that survived.
class GymExerciseUpdate {
  const GymExerciseUpdate({required this.exercise, required this.mergedInto});

  final GymExercise exercise;
  final String? mergedInto;
}

/// What came back from removing an exercise. Anything with logged history is
/// archived rather than erased, which is what [archived] reports.
class GymExerciseRemoval {
  const GymExerciseRemoval({required this.deleted, required this.archived});

  const GymExerciseRemoval.deleted() : deleted = true, archived = false;

  const GymExerciseRemoval.archived() : deleted = false, archived = true;

  final bool deleted;
  final bool archived;
}

class GymSessionPage {
  const GymSessionPage({required this.sessions, required this.nextCursor});

  final List<GymSession> sessions;
  final String? nextCursor;
}

/// Applies the server's exercise merge to an already painted or cached
/// overview. The next refresh still remains canonical; this prevents a stale
/// duplicate from flashing back while that refresh is in flight or offline.
GymOverview applyExerciseMerge(
  GymOverview overview, {
  required String sourceExerciseId,
  required GymExercise target,
}) {
  final references = <GymExerciseReference>[];
  final seenReferences = <String>{};
  for (final reference in overview.recentReferences) {
    final exerciseId = reference.exerciseId == sourceExerciseId
        ? target.id
        : reference.exerciseId;
    final key = '$exerciseId:${reference.locationId ?? 'none'}';
    if (!seenReferences.add(key)) continue;
    references.add(
      GymExerciseReference(
        exerciseId: exerciseId,
        sessionId: reference.sessionId,
        dateKey: reference.dateKey,
        locationId: reference.locationId,
        raw: reference.raw,
        notes: reference.notes,
        sets: reference.sets,
      ),
    );
  }

  return overview.copyWith(
    exercises: [
      for (final exercise in overview.exercises)
        if (exercise.id == target.id)
          target
        else if (exercise.id != sourceExerciseId)
          exercise,
    ],
    recentReferences: references,
    sessions: [
      for (final session in overview.sessions)
        GymSession(
          id: session.id,
          dateKey: session.dateKey,
          locationId: session.locationId,
          notes: session.notes,
          exercises: [
            for (final exercise in session.exercises)
              exercise.exerciseId == sourceExerciseId
                  ? GymSessionExercise(
                      id: exercise.id,
                      exerciseId: target.id,
                      name: target.name,
                      order: exercise.order,
                      raw: exercise.raw,
                      notes: exercise.notes,
                      sets: exercise.sets,
                    )
                  : exercise,
          ],
          createdAt: session.createdAt,
        ),
    ],
  );
}

String gymDateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

double? parseGymWeight(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

int? parseGymReps(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return null;
  return int.tryParse(normalized);
}

String formatGymNumber(num value) {
  final rounded = value.toDouble();
  if (rounded == rounded.roundToDouble()) return rounded.toInt().toString();
  return rounded
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String formatGymSet(GymSet set) {
  final weight = set.weight == null ? null : formatGymNumber(set.weight!);
  final reps = set.reps?.toString();
  if (weight != null && reps != null) return '$weight×$reps';
  return weight ?? reps ?? '—';
}
