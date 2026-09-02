import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

import '../../helpers/fake_gym_repository.dart';
import '../../helpers/pump_luqa.dart';

void main() {
  testWidgets('keeps same-gym history visible and autosaves entered sets', (
    tester,
  ) async {
    final gym = FakeGymRepository.sample();
    await pumpLuqa(tester, gymRepository: gym);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue workout'));
    await tester.pumpAndSettle();

    expect(find.text('Lat pulldown'), findsOneWidget);
    expect(find.text('Last time · 72.5×10 · 72.5×9 · 70×11'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('weight-0')), '75');
    await tester.enterText(find.byKey(const ValueKey('reps-0')), '10');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(gym.saves, 1);
    // "Saved" is a promise about the phone, which is the one the app can keep
    // in a gym. Reaching the server is reported as "Saved · syncing".
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('switching gyms refreshes references without clearing input', (
    tester,
  ) async {
    final gym = FakeGymRepository.sample();
    await pumpLuqa(tester, gymRepository: gym);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue workout'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('weight-0')), '75');
    await tester.tap(find.text('Luqa Gym'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('McFit Mitte'));
    await tester.pumpAndSettle();

    final weight = tester.widget<TextField>(
      find.byKey(const ValueKey('weight-0')),
    );
    expect(weight.controller!.text, '75');
    expect(find.text('Last time · 65×12 · 65×10'), findsOneWidget);
  });

  testWidgets('leaving immediately flushes the workout draft', (tester) async {
    final gym = FakeGymRepository.sample();
    await pumpLuqa(tester, gymRepository: gym);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue workout'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('weight-0')), '80');
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(gym.saves, 1);
    expect(find.text('Continue workout'), findsOneWidget);
  });

  testWidgets('workout remains usable at two hundred percent text size', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpLuqa(tester, gymRepository: FakeGymRepository.sample());

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue workout'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('weight-0')), findsOneWidget);
    expect(find.text('Add exercise'), findsOneWidget);
  });

  testWidgets('merges a duplicate exercise into the chosen exercise', (
    tester,
  ) async {
    final gym = FakeGymRepository.sample();
    gym.overview = gym.overview.copyWith(
      exercises: [
        ...gym.overview.exercises,
        const GymExercise(
          id: 'lat-puldown',
          name: 'Lat puldown',
          notes: 'Seat 4',
          archived: false,
          sessionCount: 2,
          lastPerformed: '2026-08-21',
          locationIds: ['luqa-gym'],
        ),
      ],
    );
    await pumpLuqa(tester, gymRepository: gym);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exercises'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('exercise-menu-lat-puldown')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Merge into another…'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('merge-target-lat-pulldown')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Merge exercises?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-exercise-merge')));
    await tester.pumpAndSettle();

    expect(gym.overview.exerciseById('lat-puldown'), isNull);
    expect(gym.overview.exerciseById('lat-pulldown')!.sessionCount, 7);
    expect(find.text('Lat puldown'), findsNothing);
  });

  testWidgets('renames an exercise everywhere it appears', (tester) async {
    final gym = FakeGymRepository.sample();
    await pumpLuqa(tester, gymRepository: gym);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exercises'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('exercise-menu-lat-pulldown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename…'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('rename-exercise-field')),
      'Latzug',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-exercise-rename')));
    await tester.pumpAndSettle();

    expect(gym.overview.exerciseById('lat-pulldown')!.name, 'Latzug');
    expect(find.text('Latzug'), findsOneWidget);
  });

  testWidgets('a rename onto a name already in use is refused, not merged', (
    tester,
  ) async {
    final gym = FakeGymRepository.sample();
    gym.overview = gym.overview.copyWith(
      exercises: [
        ...gym.overview.exercises,
        const GymExercise(
          id: 'row',
          name: 'Seated row',
          notes: '',
          archived: false,
          sessionCount: 2,
          lastPerformed: '2026-08-21',
          locationIds: ['luqa-gym'],
        ),
      ],
    );
    await pumpLuqa(tester, gymRepository: gym);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exercises'));
    await tester.pumpAndSettle();

    // Searching hides the exercise being clashed with. A name is taken
    // whether or not the current search happens to show it.
    await tester.enterText(find.byType(TextField), 'row');
    await tester.pumpAndSettle();
    expect(find.text('Lat pulldown'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('exercise-menu-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename…'));
    await tester.pumpAndSettle();

    // Same name, differently spaced and cased — the way the server judges it.
    await tester.enterText(
      find.byKey(const ValueKey('rename-exercise-field')),
      '  lat   pulldown ',
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('already uses that name'),
      findsOneWidget,
    );
    final save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('confirm-exercise-rename')),
    );
    expect(save.onPressed, isNull);
    expect(gym.overview.exerciseById('row')!.name, 'Seated row');
  });

  testWidgets('deletes an exercise with no history outright', (tester) async {
    final gym = FakeGymRepository.sample();
    gym.overview = gym.overview.copyWith(
      exercises: [
        ...gym.overview.exercises,
        const GymExercise(
          id: 'curls',
          name: 'Preacher curls',
          notes: '',
          archived: false,
          sessionCount: 0,
          lastPerformed: null,
          locationIds: [],
        ),
      ],
    );
    await pumpLuqa(tester, gymRepository: gym);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exercises'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('exercise-menu-curls')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete “Preacher curls”?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-exercise-delete')));
    await tester.pumpAndSettle();

    expect(gym.deletedExerciseIds, ['curls']);
    expect(find.text('Preacher curls'), findsNothing);
    expect(find.text('Deleted “Preacher curls”.'), findsOneWidget);
  });

  testWidgets('deleting a logged exercise says the workouts keep it', (
    tester,
  ) async {
    final gym = FakeGymRepository.sample();
    await pumpLuqa(tester, gymRepository: gym);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exercises'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('exercise-menu-lat-pulldown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.textContaining('It is on 5 workouts'), findsOneWidget);
    expect(find.textContaining('so those keep it'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-exercise-delete')));
    await tester.pumpAndSettle();

    expect(
      find.text('Removed “Lat pulldown”. Your logged workouts still show it.'),
      findsOneWidget,
    );
  });

  testWidgets('deletes the workout that is under way', (tester) async {
    final gym = FakeGymRepository.sample();
    await pumpLuqa(tester, gymRepository: gym);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue workout'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('weight-0')), '75');
    await tester.tap(find.byTooltip('Workout options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete workout'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this workout?'), findsOneWidget);
    final savesBeforeDelete = gym.saves;
    await tester.tap(find.byKey(const ValueKey('confirm-workout-delete')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(gym.deletedSessionIds, ['current-workout']);
    // Autosave outlives this screen — it runs on a timer and again as the
    // screen closes. Not one more save may land, or the workout comes back.
    expect(gym.saves, savesBeforeDelete);
    // Back on the gym tab, with nothing under way any more.
    expect(find.text('Continue workout'), findsNothing);
    expect(find.text('Start workout'), findsOneWidget);
  });

  testWidgets('finishing a workout ends it and leaves the screen', (
    tester,
  ) async {
    final gym = FakeGymRepository.sample();
    await pumpLuqa(tester, gymRepository: gym);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue workout'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('weight-0')), '75');
    await tester.tap(find.byKey(const ValueKey('finish-workout')));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The last set was typed seconds before the button; it belongs inside the
    // workout, not after the end of it.
    expect(gym.saves, greaterThan(0));
    expect(gym.endedSessions.single.id, 'current-workout');
    expect(gym.endedSessions.single.endedAt, fixedNow);

    // The gym tab has nothing to continue, but the workout is still in history.
    expect(find.text('Continue workout'), findsNothing);
    expect(find.text('Start workout'), findsOneWidget);
    expect(gym.deletedSessionIds, isEmpty);
  });

  testWidgets('a workout left untouched for hours stops being current', (
    tester,
  ) async {
    final gym = FakeGymRepository.sample();
    // Started before lunch and never touched again: whatever happened to it,
    // it is not still happening at three in the afternoon.
    final stale = gym.overview.sessions.first.copyWith(
      updatedAt: fixedNow.subtract(const Duration(hours: 6)),
    );
    gym.overview = gym.overview.copyWith(
      sessions: [stale, ...gym.overview.sessions.skip(1)],
    );
    await pumpLuqa(tester, gymRepository: gym);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Continue workout'), findsNothing);
    expect(find.text('Start workout'), findsOneWidget);
    // Closed for real, and stamped with when the training actually stopped
    // rather than with whenever the app was next opened.
    expect(gym.endedSessions.single.id, 'current-workout');
    expect(gym.endedSessions.single.endedAt, stale.updatedAt);
  });

  testWidgets('a workout being logged past midnight is still current', (
    tester,
  ) async {
    final gym = FakeGymRepository.sample();
    // Yesterday's date, touched minutes ago — the case the old date-key rule
    // got wrong, cutting a late-night workout off at midnight.
    final overnight = GymSession(
      id: 'overnight',
      dateKey: '2026-08-26',
      locationId: 'luqa-gym',
      notes: '',
      exercises: const [],
      createdAt: fixedNow.subtract(const Duration(hours: 2)),
      updatedAt: fixedNow.subtract(const Duration(minutes: 10)),
      endedAt: null,
    );
    gym.overview = gym.overview.copyWith(
      sessions: [overnight, ...gym.overview.sessions.skip(1)],
    );
    await pumpLuqa(tester, gymRepository: gym);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Continue workout'), findsOneWidget);
    expect(gym.endedSessions, isEmpty);
  });
}
