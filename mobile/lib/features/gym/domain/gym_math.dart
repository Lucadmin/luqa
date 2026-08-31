import 'package:luqa/features/gym/domain/gym_models.dart';

/// What a set is worth.
///
/// Ported from the server so the phone can plot a progress graph without
/// asking. Every function here has a twin in `src/lib/gym.ts`, and they have
/// to stay in step: a personal record that appears on one and not the other is
/// worse than no badge at all.

/// Epley one-rep-max estimate. The fairest way to compare a heavy triple
/// against a lighter set of twelve, which is what the progress graph needs.
double? estimateOneRepMax(double? weight, int? reps) {
  if (weight == null || reps == null || reps <= 0) return null;
  return weight * (1 + reps / 30);
}

/// The heaviest thing actually lifted, whatever the reps.
double? topWeight(List<GymSet> sets) {
  double? best;
  for (final set in sets) {
    final weight = set.weight;
    if (weight == null) continue;
    if (best == null || weight > best) best = weight;
  }
  return best;
}

/// The best estimated one-rep max across the sets.
double? bestOneRepMax(List<GymSet> sets) {
  double? best;
  for (final set in sets) {
    final estimate = estimateOneRepMax(set.weight, set.reps);
    if (estimate == null) continue;
    if (best == null || estimate > best) best = estimate;
  }
  return best;
}

int totalReps(List<GymSet> sets) =>
    sets.fold(0, (sum, set) => sum + (set.reps ?? 0));

/// Weight moved across the exercise. Bodyweight sets contribute nothing.
double totalVolume(List<GymSet> sets) => sets.fold(
  0,
  (sum, set) => set.weight != null && set.reps != null
      ? sum + set.weight! * set.reps!
      : sum,
);

/// Marks the sessions that beat everything before them.
///
/// The first session on record is a baseline rather than a record — a badge on
/// the very first entry says nothing about progress.
List<GymExercisePoint> markPersonalRecords(List<GymExercisePoint> oldestFirst) {
  var ceiling = 0.0;
  final marked = <GymExercisePoint>[];
  for (final point in oldestFirst) {
    final best = point.bestOneRepMax;
    var isRecord = false;
    if (best != null && best > ceiling) {
      isRecord = ceiling > 0;
      ceiling = best;
    }
    marked.add(
      GymExercisePoint(
        sessionId: point.sessionId,
        dateKey: point.dateKey,
        locationId: point.locationId,
        raw: point.raw,
        notes: point.notes,
        sets: point.sets,
        topWeight: point.topWeight,
        bestOneRepMax: point.bestOneRepMax,
        totalReps: point.totalReps,
        volume: point.volume,
        isPersonalRecord: isRecord,
      ),
    );
  }
  return marked;
}

/// "70-8 72.5-6" — the line the editor writes and history reads back.
String formatSetLine(List<GymSet> sets) => sets
    .map((set) {
      final reps = set.reps == null ? '' : '${set.reps}${set.note ?? ''}';
      if (set.weight == null) return reps.isEmpty ? '—' : reps;
      final weight = formatGymNumber(set.weight!);
      return reps.isEmpty ? weight : '$weight-$reps';
    })
    .join(' ');

