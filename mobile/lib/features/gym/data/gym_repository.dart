import 'package:luqa/features/gym/domain/gym_models.dart';

class GymSetWrite {
  const GymSetWrite({required this.weight, required this.reps, this.note});

  final double? weight;
  final int? reps;
  final String? note;
}

class GymExerciseWrite {
  const GymExerciseWrite({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.notes,
  });

  final String? exerciseId;
  final String name;
  final List<GymSetWrite> sets;
  final String notes;
}

class GymSessionWrite {
  const GymSessionWrite({
    required this.dateKey,
    required this.locationId,
    required this.notes,
    required this.exercises,
  });

  final String dateKey;
  final String? locationId;
  final String notes;
  final List<GymExerciseWrite> exercises;
}

abstract interface class GymRepository {
  Future<GymOverview> loadOverview({int limit = 30});

  /// [id] is the identity the device already gave the workout. Sending it
  /// makes the create idempotent, so a retry after a lost response cannot
  /// leave two empty workouts in the same day.
  Future<GymSession> createSession({
    String? id,
    required String dateKey,
    required String? locationId,
  });

  Future<GymSession> loadSession(String id);

  Future<GymSession> saveSession(String id, GymSessionWrite write);

  Future<GymSessionPage> loadSessions({String? cursor, int limit = 20});

  Future<GymExerciseHistory> loadExerciseHistory(
    String exerciseId, {
    String? locationId,
    String? beforeSessionId,
  });

  /// Moves every logged performance from [sourceExerciseId] to
  /// [targetExerciseId]. The target name is kept and the source disappears.
  Future<GymExercise> mergeExercise({
    required String sourceExerciseId,
    required String targetExerciseId,
  });

  Future<GymLocation> createLocation({
    String? id,
    required String name,
    required String code,
    required int colorValue,
  });

  Future<GymLocation> updateLocation({
    required String id,
    String? name,
    String? code,
    int? colorValue,
    bool? archived,
  });
}
