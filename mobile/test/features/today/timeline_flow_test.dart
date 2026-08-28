import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/today/presentation/widgets/draft_composer.dart';
import 'package:luqa/features/today/presentation/widgets/timeline_metrics.dart';
import 'package:luqa/features/today/presentation/widgets/timeline_view.dart';

import '../../helpers/pump_luqa.dart';

void main() {
  testWidgets('tapping empty grid opens a composer for a thirty-minute block', (
    tester,
  ) async {
    final repository = await pumpLuqa(tester);
    final before = repository.entries.length;

    await tapTimelineAt(tester, const Offset(220, 520));

    expect(find.byType(DraftComposer), findsOneWidget);
    expect(find.text('30m'), findsOneWidget);
    // Nothing is written until the composer is committed.
    expect(repository.entries, hasLength(before));
  });

  testWidgets('a composed block is saved onto the timeline', (tester) async {
    final repository = await pumpLuqa(tester);
    final before = repository.entries.length;

    await tapTimelineAt(tester, const Offset(220, 520));
    await tester.enterText(
      find.byKey(const ValueKey('draft-description')),
      'Reading',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-draft-button')));
    await tester.pumpAndSettle();

    expect(repository.entries, hasLength(before + 1));
    expect(repository.entries.last.description, 'Reading');
    expect(
      repository.entries.last.end!.difference(repository.entries.last.start),
      const Duration(minutes: 30),
    );
    expect(find.byType(DraftComposer), findsNothing);
  });

  testWidgets('tapping the grid again relocates the block being composed', (
    tester,
  ) async {
    await pumpLuqa(tester);

    await tapTimelineAt(tester, const Offset(220, 470));
    final first = _draftStart(tester);

    await tapTimelineAt(tester, const Offset(220, 420));

    expect(find.byType(DraftComposer), findsOneWidget);
    expect(_draftStart(tester), isNot(first));
  });

  testWidgets('dragging the end handle resizes the block in five-minute steps', (
    tester,
  ) async {
    final repository = await pumpLuqa(tester);
    const metrics = TimelineMetrics();

    await tapTimelineAt(tester, const Offset(220, 470));
    expect(_draftDuration(tester), const Duration(minutes: 30));

    // One hour further down the grid is one hour more on the block.
    await tester.drag(
      find.byKey(const ValueKey('draft-end-handle')),
      Offset(0, metrics.hourHeight),
    );
    await tester.pumpAndSettle();

    expect(_draftDuration(tester), const Duration(minutes: 90));

    await tester.tap(find.byKey(const ValueKey('save-draft-button')));
    await tester.pumpAndSettle();

    expect(
      repository.entries.last.end!.difference(repository.entries.last.start),
      const Duration(minutes: 90),
    );
  });

  testWidgets('dragging the start handle cannot cross the end', (tester) async {
    await pumpLuqa(tester);
    const metrics = TimelineMetrics();

    await tapTimelineAt(tester, const Offset(220, 470));

    // Push the start well past the end; it stops one snap step short.
    await tester.drag(
      find.byKey(const ValueKey('draft-start-handle')),
      Offset(0, metrics.hourHeight * 3),
    );
    await tester.pumpAndSettle();

    expect(_draftDuration(tester), const Duration(minutes: 5));
  });

  testWidgets('discarding the composer leaves the timeline untouched', (
    tester,
  ) async {
    final repository = await pumpLuqa(tester);
    final before = repository.entries.length;

    await tapTimelineAt(tester, const Offset(220, 520));
    await tester.tap(find.widgetWithIcon(IconButton, Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(DraftComposer), findsNothing);
    expect(repository.entries, hasLength(before));
  });

  testWidgets('tapping an entry opens the editor and can delete it', (
    tester,
  ) async {
    final repository = await pumpLuqa(tester);

    await tester.tap(_onGrid('Gym'));
    await tester.pumpAndSettle();
    expect(find.text('Edit entry'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    // The sheet's pop resolves first; the snackbar it triggers needs the
    // frame after that.
    await tester.pumpAndSettle();

    expect(repository.entries.any((entry) => entry.id == 'gym'), isFalse);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('undo puts a deleted entry back', (tester) async {
    final repository = await pumpLuqa(tester);

    await tester.tap(_onGrid('Gym'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(repository.entries.any((entry) => entry.description == 'Gym'), isTrue);
  });

  testWidgets('long-pressing an entry lifts it into the composer', (
    tester,
  ) async {
    await pumpLuqa(tester);

    await tester.longPress(_onGrid('Gym'));
    await tester.pumpAndSettle();

    expect(find.byType(DraftComposer), findsOneWidget);
    // Reshaping an existing entry offers deletion; a new block has nothing
    // to delete yet.
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
  });

  testWidgets('a timer can be started and stopped', (tester) async {
    final repository = await pumpLuqa(tester);

    await tester.tap(find.text('Start a timer'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('timer-description')),
      'Deep work',
    );
    await tester.tap(find.byKey(const ValueKey('start-timer-button')));
    // A running timer ticks forever, so this settles by hand rather than
    // waiting for a timeline that never goes quiet.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final started = repository.entries.last;
    expect(started.description, 'Deep work');
    expect(started.isRunning, isTrue);

    await tester.tap(find.byKey(const ValueKey('stop-timer-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.entries.last.isRunning, isFalse);
    expect(find.text('Start a timer'), findsOneWidget);
  });

  testWidgets('the day label follows the timeline as it scrolls', (
    tester,
  ) async {
    await pumpLuqa(tester);
    expect(_dayLabel(tester), 'Today');

    // A whole day upwards is yesterday, whatever the time of day on screen.
    await tester.drag(
      find.byType(TimelineView),
      Offset(0, const TimelineMetrics().dayHeight),
    );
    await tester.pumpAndSettle();

    expect(_dayLabel(tester), 'Yesterday');
  });
}

/// Narrows a text finder to the grid, so a label that also appears in the
/// navigation bar cannot match twice.
Finder _onGrid(String text) => find.descendant(
  of: find.byType(TimelineView),
  matching: find.text(text),
);

Duration _draftDuration(WidgetTester tester) =>
    tester.widget<DraftComposer>(find.byType(DraftComposer)).draft.duration;

String _dayLabel(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('visible-day-label'))).data!;

/// The composer renders the draft's own start time, which is the cheapest
/// stable handle on where the block currently sits.
String _draftStart(WidgetTester tester) {
  final composer = tester.widget<DraftComposer>(find.byType(DraftComposer));
  return composer.draft.start.toIso8601String();
}
