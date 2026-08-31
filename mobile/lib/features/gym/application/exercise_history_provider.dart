import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/features/gym/data/gym_providers.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

typedef GymHistoryRequest = ({
  String exerciseId,
  String? locationId,
  String? beforeSessionId,
});

final gymExerciseHistoryProvider = FutureProvider.autoDispose
    .family<GymExerciseHistory, GymHistoryRequest>((ref, request) {
      return ref
          .watch(gymRepositoryProvider)
          .loadExerciseHistory(
            request.exerciseId,
            locationId: request.locationId,
            beforeSessionId: request.beforeSessionId,
          );
    });
