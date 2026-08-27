import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_luqa.dart';

void main() {
  testWidgets('recent activity fills description and category, then saves', (
    tester,
  ) async {
    await pumpLuqa(tester);

    await tester.tap(find.byKey(const ValueKey('log-time-button')));
    await tester.pumpAndSettle();

    expect(find.text('Log time'), findsWidgets);
    expect(find.text('Recent'), findsOneWidget);

    await tester.tap(find.text('Lunch'));
    await tester.pump();

    final description = tester.widget<TextField>(
      find.byKey(const ValueKey('description-field')),
    );
    expect(description.controller?.text, 'Lunch');
    expect(find.text('Food'), findsWidgets);

    final addEntryButton = find.byKey(const ValueKey('add-entry-button'));
    expect(tester.widget<FilledButton>(addEntryButton).onPressed, isNotNull);
    await tester.ensureVisible(addEntryButton);
    await tester.tap(addEntryButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('add-entry-button')), findsNothing);
    expect(find.text('Lunch'), findsOneWidget);
  });

  testWidgets('category picker can create and return a category', (
    tester,
  ) async {
    await pumpLuqa(tester);

    await tester.tap(find.byKey(const ValueKey('log-time-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No category'));
    await tester.pumpAndSettle();

    expect(find.text('Choose category'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Research');
    await tester.pump();
    await tester.tap(find.text('Create “Research”'));
    await tester.pumpAndSettle();

    expect(find.text('Research'), findsOneWidget);
  });
}
