import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/insights/domain/insights_models.dart';
import 'package:luqa/features/insights/presentation/widgets/rhythm_wall.dart';

import '../../helpers/pump_luqa.dart';

Future<void> _openInsights(WidgetTester tester, {int historyDays = 40}) async {
  await pumpLuqa(tester, historyDays: historyDays);
  await tester.tap(find.byIcon(Icons.bar_chart_outlined));
  await tester.pumpAndSettle();
}

Finder _spanFinder(InsightsSpan span) =>
    find.byKey(ValueKey('insights-span-${span.name}'));

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    320,
    scrollable: find.byType(Scrollable),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the tab opens on this week, with the wall behind it', (
    tester,
  ) async {
    await _openInsights(tester);

    expect(find.text('Insights'), findsWidgets);
    expect(find.text('Tracked'), findsOneWidget);
    // Monday to Sunday of the week containing the fixed clock.
    expect(find.byType(RhythmWall), findsOneWidget);
    expect(find.text('24–30 Aug'), findsOneWidget);
    expect(find.byKey(rhythmColumnKey(DateTime(2026, 8, 24))), findsOneWidget);
    expect(find.byKey(rhythmColumnKey(DateTime(2026, 8, 30))), findsOneWidget);
    expect(find.byKey(rhythmColumnKey(DateTime(2026, 8, 31))), findsNothing);
    // The comparison beside the total comes from the same read as the total.
    expect(find.textContaining('against the previous week'), findsOneWidget);
  });

  testWidgets('tapping a column moves the headline onto that day', (
    tester,
  ) async {
    await _openInsights(tester);

    await tester.tap(find.byKey(rhythmColumnKey(DateTime(2026, 8, 25))));
    await tester.pumpAndSettle();

    expect(find.text('Tuesday, 25 August'), findsOneWidget);
    expect(find.text('Tracked'), findsNothing);
    // The breakdown under it follows the selection.
    expect(find.text('Where it went'), findsNothing);
    expect(find.text('Tue, 25 Aug'), findsOneWidget);

    // A second tap on the same column gives the whole span back.
    await tester.tap(find.byKey(rhythmColumnKey(DateTime(2026, 8, 25))));
    await tester.pumpAndSettle();
    expect(find.text('Tracked'), findsOneWidget);
    expect(find.text('Where it went'), findsOneWidget);
  });

  testWidgets('a day still to come is not selectable', (tester) async {
    await _openInsights(tester);

    // The fixed clock is a Thursday, so Sunday has not happened.
    await tester.tap(find.byKey(rhythmColumnKey(DateTime(2026, 8, 30))));
    await tester.pumpAndSettle();

    expect(find.text('Tracked'), findsOneWidget);
    expect(find.text('Sunday, 30 August'), findsNothing);
  });

  testWidgets('changing the span redraws the wall and returns to now', (
    tester,
  ) async {
    await _openInsights(tester);

    await tester.tap(_spanFinder(InsightsSpan.twelveWeeks));
    await tester.pumpAndSettle();

    expect(find.text('8 Jun – 30 Aug'), findsOneWidget);
    expect(find.byKey(rhythmColumnKey(DateTime(2026, 6, 8))), findsOneWidget);
    expect(find.byKey(rhythmColumnKey(DateTime(2026, 6, 7))), findsNothing);
  });

  testWidgets('stepping back offers a way home', (tester) async {
    await _openInsights(tester);

    expect(find.byKey(const ValueKey('insights-now')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('insights-previous')));
    await tester.pumpAndSettle();
    expect(find.text('17–23 Aug'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('insights-now')));
    await tester.pumpAndSettle();
    expect(find.text('24–30 Aug'), findsOneWidget);
    expect(find.byKey(const ValueKey('insights-now')), findsNothing);
  });

  testWidgets('the span reads out as patterns and habits under the wall', (
    tester,
  ) async {
    await _openInsights(tester);

    await _scrollTo(tester, find.text('Patterns'));
    expect(find.text('Patterns'), findsOneWidget);
    expect(find.text('Your day, end to end'), findsOneWidget);

    await _scrollTo(tester, find.text('Habits'));
    expect(find.text('Habits'), findsOneWidget);
  });

  testWidgets('an account with no history says so instead of charting it', (
    tester,
  ) async {
    await pumpLuqa(tester);
    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pumpAndSettle();

    // The sample day sits in this week, so the span is not empty — step back
    // to one that is.
    await tester.tap(find.byKey(const ValueKey('insights-previous')));
    await tester.pumpAndSettle();

    expect(find.text('Nothing was recorded in this stretch.'), findsOneWidget);
    expect(find.text('Where it went'), findsNothing);
  });
}
