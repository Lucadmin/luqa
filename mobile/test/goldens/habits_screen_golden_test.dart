import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_luqa.dart';

/// Light and dark are separately tuned schemes with equal product status, so
/// each is pinned on its own rather than one being checked and the other
/// assumed to follow.
Future<void> _openHabits(
  WidgetTester tester, {
  required ThemeMode themeMode,
}) async {
  await pumpLuqa(tester, themeMode: themeMode);
  await tester.tap(find.byKey(const ValueKey('habits-strip-all')));
  await tester.pumpAndSettle();
}

Future<void> _openInsights(
  WidgetTester tester, {
  required ThemeMode themeMode,
}) async {
  await _openHabits(tester, themeMode: themeMode);
  await tester.tap(find.text('Insights'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Habits day light', (tester) async {
    await _openHabits(tester, themeMode: ThemeMode.light);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('habits_day_light.png'),
    );
  });

  testWidgets('Habits day dark', (tester) async {
    await _openHabits(tester, themeMode: ThemeMode.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('habits_day_dark.png'),
    );
  });

  testWidgets('Habit insights light', (tester) async {
    await _openInsights(tester, themeMode: ThemeMode.light);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('habits_insights_light.png'),
    );
  });

  testWidgets('The habit editor, light', (tester) async {
    await _openHabits(tester, themeMode: ThemeMode.light);
    await tester.tap(find.byKey(const ValueKey('habits-new')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('habit_editor_light.png'),
    );
  });
}
