import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/gym/application/workout_controller.dart';
import 'package:luqa/features/gym/data/gym_providers.dart';

import '../../helpers/fake_gym_repository.dart';

void main() {
  test('failed autosave keeps the local workout draft intact', () async {
    final repository = FakeGymRepository.sample();
    final container = ProviderContainer(
      overrides: [gymRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final provider = workoutControllerProvider('current-workout');
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    final controller = container.read(provider.notifier);
    await Future<void>.delayed(Duration.zero);
    await controller.load();
    repository.saveError = StateError('offline');

    controller.updateSet(0, weight: '75', reps: '10');
    await controller.flush();

    final state = container.read(provider);
    expect(state.activeExercise!.sets.first.weight, '75');
    expect(state.activeExercise!.sets.first.reps, '10');
    expect(state.hasUnsavedChanges, isTrue);
    expect(state.saveError, isNotNull);
  });

  test(
    'an edit made while a save is in flight is not replaced by its response',
    () async {
      final repository = FakeGymRepository.sample();
      final started = Completer<void>();
      final release = Completer<void>();
      repository.saveStarted = started;
      repository.saveGate = release.future;
      final container = ProviderContainer(
        overrides: [gymRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final provider = workoutControllerProvider('current-workout');
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      final controller = container.read(provider.notifier);
      await Future<void>.delayed(Duration.zero);
      await controller.load();

      controller.updateSet(0, weight: '75');
      final saving = controller.flush();
      await started.future;
      controller.updateSet(0, weight: '77.5');
      release.complete();
      await saving;

      expect(
        container.read(provider).activeExercise!.sets.first.weight,
        '77.5',
      );
      expect(container.read(provider).hasUnsavedChanges, isFalse);
      expect(repository.saves, 2);
    },
  );
}
