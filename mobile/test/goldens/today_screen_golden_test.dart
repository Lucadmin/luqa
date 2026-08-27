import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_luqa.dart';

void main() {
  testWidgets('Today screen light', (tester) async {
    await pumpLuqa(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('today_light.png'),
    );
  });

  testWidgets('Today screen dark', (tester) async {
    await pumpLuqa(tester, themeMode: ThemeMode.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('today_dark.png'),
    );
  });

  testWidgets('Log time sheet light', (tester) async {
    await pumpLuqa(tester);
    await tester.tap(find.byKey(const ValueKey('log-time-button')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('log_time_light.png'),
    );
  });

  testWidgets('Log time sheet dark', (tester) async {
    await pumpLuqa(tester, themeMode: ThemeMode.dark);
    await tester.tap(find.byKey(const ValueKey('log-time-button')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('log_time_dark.png'),
    );
  });
}
