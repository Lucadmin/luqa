import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/insights/domain/insights_models.dart';
import 'package:luqa/features/insights/presentation/widgets/rhythm_wall.dart';

import '../helpers/pump_luqa.dart';

/// Light and dark are separately tuned schemes with equal product status, so
/// each is pinned on its own rather than one being checked and the other
/// assumed to follow.
Future<void> _openInsights(
  WidgetTester tester, {
  required ThemeMode themeMode,
}) async {
  await pumpLuqa(tester, themeMode: themeMode, historyDays: 70);
  await tester.tap(find.byIcon(Icons.bar_chart_outlined));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Insights week, light', (tester) async {
    await _openInsights(tester, themeMode: ThemeMode.light);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('insights_week_light.png'),
    );
  });

  testWidgets('Insights week, dark', (tester) async {
    await _openInsights(tester, themeMode: ThemeMode.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('insights_week_dark.png'),
    );
  });

  testWidgets('Insights with one day selected, light', (tester) async {
    await _openInsights(tester, themeMode: ThemeMode.light);
    await tester.tap(find.byKey(rhythmColumnKey(DateTime(2026, 8, 25))));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('insights_day_light.png'),
    );
  });

  testWidgets('Insights over twelve weeks, light', (tester) async {
    await _openInsights(tester, themeMode: ThemeMode.light);
    await tester.tap(
      find.byKey(ValueKey('insights-span-${InsightsSpan.twelveWeeks.name}')),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('insights_quarter_light.png'),
    );
  });
}
