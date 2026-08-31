import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_luqa.dart';

void main() {
  testWidgets('Merged settings light', (tester) async {
    await pumpLuqa(
      tester,
      themeMode: ThemeMode.light,
      initialLocation: '/settings',
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('settings_light.png'),
    );
  });

  testWidgets('Merged settings dark', (tester) async {
    await pumpLuqa(
      tester,
      themeMode: ThemeMode.dark,
      initialLocation: '/settings',
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('settings_dark.png'),
    );
  });
}
