import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/features/auth/application/auth_controller.dart';
import 'package:luqa/features/gym/data/gym_repository.dart';
import 'package:luqa/features/gym/data/remote_gym_repository.dart';

final gymRepositoryProvider = Provider<GymRepository>((ref) {
  return RemoteGymRepository(ref.watch(luqaApiProvider));
});
