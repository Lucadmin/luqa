import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_luqa.dart';

/// Light and dark are separately tuned schemes with equal product status, so
/// each is pinned on its own rather than one being checked and the other
/// assumed to follow.
Future<void> _openPeople(
  WidgetTester tester, {
  required ThemeMode themeMode,
}) async {
  await pumpLuqa(tester, themeMode: themeMode);
  await tester.tap(find.byIcon(Icons.group_outlined));
  await tester.pumpAndSettle();
}

Future<void> _openPerson(
  WidgetTester tester, {
  required ThemeMode themeMode,
}) async {
  await _openPeople(tester, themeMode: themeMode);
  final row = find.byKey(const ValueKey('person-mira'));
  await tester.scrollUntilVisible(row, 120);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('People roster light', (tester) async {
    await _openPeople(tester, themeMode: ThemeMode.light);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('people_roster_light.png'),
    );
  });

  testWidgets('People roster dark', (tester) async {
    await _openPeople(tester, themeMode: ThemeMode.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('people_roster_dark.png'),
    );
  });

  testWidgets('Person detail light', (tester) async {
    await _openPerson(tester, themeMode: ThemeMode.light);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('people_person_light.png'),
    );
  });

  testWidgets('Person detail dark', (tester) async {
    await _openPerson(tester, themeMode: ThemeMode.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('people_person_dark.png'),
    );
  });
}
