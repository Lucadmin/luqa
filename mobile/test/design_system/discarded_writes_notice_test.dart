import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/design_system/discarded_writes_notice.dart';
import 'package:luqa/design_system/luqa_theme.dart';

DiscardedWrite _lost(String description, {String reason = 'The server said no.'}) =>
    DiscardedWrite(
      description: description,
      reason: reason,
      discardedAt: DateTime(2026, 8, 27, 12),
    );

Future<int> _pump(
  WidgetTester tester,
  List<DiscardedWrite> discarded, {
  ThemeMode themeMode = ThemeMode.light,
}) async {
  var acknowledged = 0;
  await tester.pumpWidget(
    MaterialApp(
      theme: themeMode == ThemeMode.dark ? LuqaTheme.dark : LuqaTheme.light,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: DiscardedWritesNotice(
            discarded: discarded,
            onAcknowledge: () => acknowledged += 1,
          ),
        ),
      ),
    ),
  );
  return acknowledged;
}

void main() {
  testWidgets('nothing lost means nothing on screen', (tester) async {
    await _pump(tester, const []);
    expect(find.byKey(const ValueKey('discarded-writes')), findsNothing);
  });

  testWidgets('one loss names what it was and why', (tester) async {
    await _pump(tester, [
      _lost('the 42.50 Dinner', reason: 'Unknown person (invalid_input).'),
    ]);

    expect(find.text("Couldn't save the 42.50 Dinner"), findsOneWidget);
    expect(find.text('Unknown person (invalid_input).'), findsOneWidget);
    // Honest about the consequence rather than offering a retry that cannot
    // work — the server understood this write and refused it.
    expect(find.text('You will need to enter it again.'), findsOneWidget);
    expect(find.textContaining('Retry'), findsNothing);
  });

  testWidgets('several losses list what went missing, not five reasons', (
    tester,
  ) async {
    await _pump(tester, [
      _lost('the 42.50 Dinner'),
      _lost('adding Mira'),
      _lost('the group The flat'),
    ]);

    expect(find.text("Couldn't save 3 of your changes"), findsOneWidget);
    expect(find.text('· the 42.50 Dinner'), findsOneWidget);
    expect(find.text('· adding Mira'), findsOneWidget);
    expect(find.text('· the group The flat'), findsOneWidget);
  });

  testWidgets('a long list is summarised rather than turned into a log', (
    tester,
  ) async {
    await _pump(tester, [for (var i = 0; i < 9; i++) _lost('change $i')]);

    expect(find.text('· change 0'), findsOneWidget);
    expect(find.text('· change 3'), findsOneWidget);
    expect(find.text('· change 4'), findsNothing);
    expect(find.text('· and 5 more'), findsOneWidget);
  });

  testWidgets('dismissing is the one action, and it reports once', (
    tester,
  ) async {
    var acknowledged = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: LuqaTheme.light,
        home: Scaffold(
          body: DiscardedWritesNotice(
            discarded: [_lost('the 42.50 Dinner')],
            onAcknowledge: () => acknowledged += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('discarded-writes-dismiss')));
    await tester.pumpAndSettle();
    expect(acknowledged, 1);
  });

  testWidgets('it announces itself to a screen reader', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, [_lost('the 42.50 Dinner')]);

    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('discarded-writes')),
    );
    // Losing somebody's work is exactly the case a live region is for.
    expect(semantics.flagsCollection.isLiveRegion, isTrue);
    handle.dispose();
  });

  testWidgets('it reads on both schemes at large text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final mode in ThemeMode.values) {
      await _pump(tester, [_lost('the 42.50 Dinner')], themeMode: mode);
      expect(tester.takeException(), isNull);
    }
  });
}
