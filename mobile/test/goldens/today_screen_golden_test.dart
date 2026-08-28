import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_luqa.dart';

void main() {
  testWidgets('Timeline light', (tester) async {
    await pumpLuqa(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('today_light.png'),
    );
  });

  testWidgets('Timeline dark', (tester) async {
    await pumpLuqa(tester, themeMode: ThemeMode.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('today_dark.png'),
    );
  });

  testWidgets('Composing a block on the grid', (tester) async {
    await pumpLuqa(tester);
    await tapTimelineAt(tester, const Offset(200, 560));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('draft_composer_light.png'),
    );
  });
}
