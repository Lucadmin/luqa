import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_luqa.dart';

void main() {
  testWidgets('uses bottom navigation on a compact Android-sized window', (
    tester,
  ) async {
    await pumpLuqa(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Today'), findsWidgets);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Continue workout'), findsOneWidget);
  });

  testWidgets('uses a navigation rail on expanded windows', (tester) async {
    await pumpLuqa(tester, size: const Size(900, 900));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('keeps one account action across top-level screens', (
    tester,
  ) async {
    await pumpLuqa(tester);

    void expectAccountAction() {
      final account = find.byKey(const ValueKey('top-level-account'));

      expect(account, findsOneWidget);
      expect(find.byKey(const ValueKey('top-level-settings')), findsNothing);
      expect(find.byKey(const ValueKey('top-level-profile')), findsNothing);
      expect(tester.getSize(account), const Size(48, 48));
    }

    expectAccountAction();

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();
    expectAccountAction();

    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();
    expectAccountAction();
  });

  testWidgets('opens profile details and preferences in one screen', (
    tester,
  ) async {
    await pumpLuqa(tester);

    await tester.tap(find.byKey(const ValueKey('top-level-account')));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Luca'), findsOneWidget);
    expect(find.text('luca@example.com'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Integrations'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('redirects the old profile route to merged settings', (
    tester,
  ) async {
    await pumpLuqa(tester, initialLocation: '/profile');

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Luca'), findsOneWidget);
  });

  testWidgets('merged settings fit a narrow window with larger text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpLuqa(
      tester,
      size: const Size(360, 800),
      initialLocation: '/settings',
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('top-level headers fit a narrow window', (tester) async {
    await pumpLuqa(tester, size: const Size(360, 800));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('top-level headers fit with larger text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpLuqa(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
