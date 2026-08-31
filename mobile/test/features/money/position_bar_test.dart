import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/design_system/luqa_theme.dart';
import 'package:luqa/features/money/presentation/widgets/position_bar.dart';

Future<Size> _pump(
  WidgetTester tester, {
  required int owed,
  required int owe,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: LuqaTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: PositionBar(owedToYouCents: owed, youOweCents: owe),
          ),
        ),
      ),
    ),
  );
  return tester.getSize(find.byType(PositionBar));
}

/// Only the bar's own segments — the scaffold paints a ColoredBox of its own.
final _segments = find.descendant(
  of: find.byType(PositionBar),
  matching: find.byType(ColoredBox),
);

void main() {
  testWidgets('the bar is drawn, and divides in proportion', (tester) async {
    final size = await _pump(tester, owed: 7500, owe: 2500);
    expect(size.height, 6);
    expect(size.width, 300);

    final boxes = _segments;
    expect(boxes, findsNWidgets(2));
    final credit = tester.getSize(boxes.at(0)).width;
    final debit = tester.getSize(boxes.at(1)).width;
    // Three quarters out, one quarter owed, minus the two-pixel gap between.
    expect(credit / (credit + debit), closeTo(0.75, 0.01));
  });

  testWidgets('one direction only fills the whole bar', (tester) async {
    await _pump(tester, owed: 4800, owe: 0);
    final boxes = _segments;
    expect(boxes, findsOneWidget);
    expect(tester.getSize(boxes).width, 300);
  });

  testWidgets('a tiny debt is still visible beside a large credit', (
    tester,
  ) async {
    await _pump(tester, owed: 100000, owe: 100);
    final boxes = _segments;
    expect(boxes, findsNWidgets(2));
    // Drawn to scale it would be a third of a pixel; it is floored to a
    // readable sliver instead, because "you owe nothing" is a different fact.
    expect(tester.getSize(boxes.at(1)).width, greaterThan(4));
  });

  testWidgets('settled up is a flat neutral rule, not an absence', (
    tester,
  ) async {
    await _pump(tester, owed: 0, owe: 0);
    expect(_segments, findsNothing);
    expect(tester.getSize(find.byType(PositionBar)).height, 6);
  });
}
