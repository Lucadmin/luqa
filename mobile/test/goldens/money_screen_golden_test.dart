import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_luqa.dart';

/// Light and dark are separately tuned schemes with equal product status, so
/// each is pinned on its own rather than one being checked and the other
/// assumed to follow.
Future<void> _openMoney(
  WidgetTester tester, {
  required ThemeMode themeMode,
}) async {
  await pumpLuqa(tester, themeMode: themeMode);
  await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
  await tester.pumpAndSettle();
}

Future<void> _openComposer(
  WidgetTester tester, {
  required ThemeMode themeMode,
}) async {
  await _openMoney(tester, themeMode: themeMode);
  await tester.tap(find.byKey(const ValueKey('quick-group-flat')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('expense-amount')), '90');
  await tester.pumpAndSettle();
}

Future<void> _openLedger(
  WidgetTester tester, {
  required ThemeMode themeMode,
}) async {
  await _openMoney(tester, themeMode: themeMode);
  await tester.tap(find.byKey(const ValueKey('balance-mira')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Money overview light', (tester) async {
    await _openMoney(tester, themeMode: ThemeMode.light);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('money_overview_light.png'),
    );
  });

  testWidgets('Money overview dark', (tester) async {
    await _openMoney(tester, themeMode: ThemeMode.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('money_overview_dark.png'),
    );
  });

  testWidgets('Expense composer light', (tester) async {
    await _openComposer(tester, themeMode: ThemeMode.light);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('money_composer_light.png'),
    );
  });

  testWidgets('Expense composer dark', (tester) async {
    await _openComposer(tester, themeMode: ThemeMode.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('money_composer_dark.png'),
    );
  });

  testWidgets('Person ledger light', (tester) async {
    await _openLedger(tester, themeMode: ThemeMode.light);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('money_ledger_light.png'),
    );
  });

  testWidgets('Person ledger dark', (tester) async {
    await _openLedger(tester, themeMode: ThemeMode.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('money_ledger_dark.png'),
    );
  });
}
