import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_luqa.dart';

Future<void> _openGym(
  WidgetTester tester, {
  required ThemeMode themeMode,
}) async {
  await pumpLuqa(tester, themeMode: themeMode);
  await tester.tap(find.byIcon(Icons.fitness_center_outlined));
  await tester.pumpAndSettle();
}

Future<void> _openWorkout(
  WidgetTester tester, {
  required ThemeMode themeMode,
}) async {
  await _openGym(tester, themeMode: themeMode);
  await tester.tap(find.text('Continue workout'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Gym overview light', (tester) async {
    await _openGym(tester, themeMode: ThemeMode.light);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('gym_overview_light.png'),
    );
  });

  testWidgets('Gym overview dark', (tester) async {
    await _openGym(tester, themeMode: ThemeMode.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('gym_overview_dark.png'),
    );
  });

  testWidgets('Active workout light', (tester) async {
    await _openWorkout(tester, themeMode: ThemeMode.light);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('gym_workout_light.png'),
    );
  });

  testWidgets('Active workout dark', (tester) async {
    await _openWorkout(tester, themeMode: ThemeMode.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('gym_workout_dark.png'),
    );
  });
}
