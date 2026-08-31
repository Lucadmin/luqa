import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/app/luqa_app.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/money/application/money_controller.dart';
import 'package:luqa/features/money/application/money_sync_engine.dart';

import '../../helpers/fake_money_repository.dart';
import '../../helpers/pump_luqa.dart';

Future<void> _openMoney(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the tab opens on the net position, not a list', (tester) async {
    await pumpLuqa(tester, moneyRepository: FakeMoneyRepository.sample());
    await _openMoney(tester);

    // 48.00 out, nothing owed: the headline is the one number that answers
    // "where do I stand".
    expect(find.byKey(const ValueKey('money-net')), findsOneWidget);
    expect(find.text('€48'), findsOneWidget);
    expect(find.text("You're owed"), findsOneWidget);
    expect(find.text('Owed to you'), findsOneWidget);
    expect(find.text('You owe'), findsOneWidget);
  });

  testWidgets('balances name the direction, never colour alone', (tester) async {
    await pumpLuqa(tester, moneyRepository: FakeMoneyRepository.sample());
    await _openMoney(tester);

    expect(find.text('Mira owes you'), findsOneWidget);
    expect(find.text('Jonas owes you'), findsOneWidget);
    // Settled people sink but stay legible, with the treat total beside them.
    expect(find.textContaining('Settled up'), findsWidgets);
  });

  testWidgets('a bill is split and lands on the screen without a round trip', (
    tester,
  ) async {
    final money = FakeMoneyRepository.sample();
    await pumpLuqa(tester, moneyRepository: money);
    await _openMoney(tester);

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('expense-amount')),
      '90',
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'What was it?'), 'Lunch');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('split-person-mira')));
    await tester.pumpAndSettle();

    // The split is previewed in exact cents while it is being decided: half
    // to Mira, half kept, adding up to the bill exactly.
    expect(find.text('€45.00'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('expense-save')));
    await tester.pumpAndSettle();

    expect(money.savedExpenses, hasLength(1));
    expect(money.savedExpenses.single.amountCents, 9000);
    expect(money.savedExpenses.single.participants.single.personId, 'mira');
    // The row is on the feed, and the balance already moved.
    expect(find.text('Lunch'), findsOneWidget);
  });

  testWidgets('an over-assigned split is refused before it can be saved', (
    tester,
  ) async {
    await pumpLuqa(tester, moneyRepository: FakeMoneyRepository.sample());
    await _openMoney(tester);

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('expense-amount')), '100');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('split-person-mira')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('split-person-jonas')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Percent'));
    await tester.pumpAndSettle();
    // Seventy plus sixty is more of the bill than there is.
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('share-mira')),
        matching: find.byType(TextField),
      ),
      '70',
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('share-jonas')),
        matching: find.byType(TextField),
      ),
      '60',
    );
    await tester.pumpAndSettle();

    expect(find.text('The shares add up to more than 100%.'), findsOneWidget);
    final save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('expense-save')),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('a group starts a bill with its members already on it', (
    tester,
  ) async {
    await pumpLuqa(tester, moneyRepository: FakeMoneyRepository.sample());
    await _openMoney(tester);

    await tester.tap(find.byKey(const ValueKey('quick-group-flat')));
    await tester.pumpAndSettle();

    // Both flatmates are selected, and the three-way split is already shown.
    expect(find.text('New expense'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
  });

  testWidgets('opening a person shows their history and offers to settle up', (
    tester,
  ) async {
    await pumpLuqa(tester, moneyRepository: FakeMoneyRepository.sample());
    await _openMoney(tester);

    await tester.tap(find.byKey(const ValueKey('balance-mira')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ledger-balance')), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settle up'), findsOneWidget);
  });

  testWidgets('settling up opens pre-filled with the whole balance', (
    tester,
  ) async {
    final money = FakeMoneyRepository.sample();
    await pumpLuqa(tester, moneyRepository: money);
    await _openMoney(tester);

    await tester.tap(find.byKey(const ValueKey('balance-mira')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settle up'));
    await tester.pumpAndSettle();

    final amount = tester.widget<TextField>(
      find.byKey(const ValueKey('settle-amount')),
    );
    expect(amount.controller!.text, '30.00');
    expect(find.text('Clears the balance'), findsOneWidget);

    await tester.tap(find.text('Record payback'));
    await tester.pumpAndSettle();

    expect(money.savedSettlements.single.amountCents, 3000);
    expect(money.savedSettlements.single.personId, 'mira');
  });

  testWidgets('a settled person cannot be settled again', (tester) async {
    await pumpLuqa(tester, moneyRepository: FakeMoneyRepository.sample());
    await _openMoney(tester);

    await tester.tap(find.byKey(const ValueKey('balance-sara')));
    await tester.pumpAndSettle();

    expect(find.text('Nothing to settle'), findsOneWidget);
  });

  testWidgets('the money tab survives two hundred percent text size', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpLuqa(tester, moneyRepository: FakeMoneyRepository.sample());
    await _openMoney(tester);

    // Compact layouts reflow; they do not silently cap accessible text size.
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('money-net')), findsOneWidget);
    expect(find.text('Owed to you'), findsOneWidget);
  });

  testWidgets('the composer reflows rather than clipping its own controls', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpLuqa(tester, moneyRepository: FakeMoneyRepository.sample());
    await _openMoney(tester);
    await tester.tap(find.byKey(const ValueKey('quick-group-flat')));
    await tester.pumpAndSettle();
    // A four-figure bill is the widest an amount realistically gets.
    await tester.enterText(
      find.byKey(const ValueKey('expense-amount')),
      '1234.56',
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('managing people reflows at large text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpLuqa(
      tester,
      moneyRepository: FakeMoneyRepository.sample(),
      initialLocation: '/money/people',
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Add person'), findsOneWidget);
    // The list explains how each person splits, not just who they are.
    expect(find.textContaining('Shares equally'), findsWidgets);
    expect(find.textContaining('Usually 0%'), findsOneWidget);
  });

  testWidgets('managing groups reflows at large text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpLuqa(
      tester,
      moneyRepository: FakeMoneyRepository.sample(),
      initialLocation: '/money/groups',
    );

    expect(tester.takeException(), isNull);
    expect(find.text('The flat'), findsOneWidget);
    expect(find.text('Mira, Jonas'), findsOneWidget);
  });

  testWidgets('a change the server refused is reported on the tab itself', (
    tester,
  ) async {
    await pumpLuqa(tester, moneyRepository: FakeMoneyRepository.sample());
    await _openMoney(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LuqaApp)),
    );
    expect(find.byKey(const ValueKey('discarded-writes')), findsNothing);

    // What the engine does when the server understood a write and refused it.
    container.read(moneySyncEngineProvider.notifier).state = container
        .read(moneySyncEngineProvider)
        .copyWith(
          discarded: [
            DiscardedWrite(
              description: 'the 42.50 Dinner',
              reason: 'Unknown person (invalid_input).',
              discardedAt: fixedNow,
            ),
          ],
        );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('discarded-writes')), findsOneWidget);
    expect(find.text("Couldn't save the 42.50 Dinner"), findsOneWidget);
    expect(container.read(moneyControllerProvider).discarded, hasLength(1));

    await tester.tap(find.byKey(const ValueKey('discarded-writes-dismiss')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('discarded-writes')), findsNothing);
  });

  testWidgets('a person ledger reflows at large text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpLuqa(
      tester,
      moneyRepository: FakeMoneyRepository.sample(),
      initialLocation: '/money/people/jonas',
    );

    expect(tester.takeException(), isNull);
    expect(find.text('History'), findsOneWidget);
    // A bill they fronted reads as debt, not credit.
    expect(find.text('You owe Jonas'), findsNothing);
    expect(find.text('Jonas owes you'), findsOneWidget);
  });
}
