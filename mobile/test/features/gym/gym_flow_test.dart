import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
