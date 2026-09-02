import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/habits/domain/habit.dart';
import 'package:luqa/features/habits/presentation/habits_screen.dart';
import 'package:luqa/features/habits/presentation/widgets/habits_strip.dart';

import '../../helpers/fake_habits_repository.dart';
import '../../helpers/pump_luqa.dart';

/// The check-in control for one habit, wherever it is being shown.
Finder controlFor(String id) => find.byKey(ValueKey('habit-control-$id'));

/// The strip is a scrolling line, so reaching a habit further along it means
/// scrolling to it first — the same thing a thumb does.
Future<void> scrollStripTo(WidgetTester tester, String key) async {
  await tester.scrollUntilVisible(
    find.byKey(ValueKey(key)),
    120,
    scrollable: find.descendant(
      of: find.byType(HabitsStrip),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapOnStrip(WidgetTester tester, String id) async {
  await scrollStripTo(tester, 'habit-control-$id');
  await tester.tap(controlFor(id));
  await tester.pumpAndSettle();
}

Future<void> openHabits(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('habits-strip-all')));
  await tester.pumpAndSettle();
}

/// Moves the timeline a day at a time, the way the header arrows do.
Future<void> shiftTimeline(WidgetTester tester, int days) async {
  final tooltip = days < 0 ? 'Previous day' : 'Next day';
  for (var step = 0; step < days.abs(); step++) {
    await tester.tap(find.byTooltip(tooltip));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('Today shows the habits due today, and not the ones that are not', (
    tester,
  ) async {
    await pumpLuqa(tester);

    expect(find.byType(HabitsStrip), findsOneWidget);
    expect(find.byKey(const ValueKey('habit-chip-read')), findsOneWidget);
    expect(find.byKey(const ValueKey('habit-chip-water')), findsOneWidget);
    // Mondays only, and the pinned day is a Thursday — so it is not on the
    // strip at all, however far it is scrolled.
    await scrollStripTo(tester, 'habit-chip-focus');
    expect(find.byKey(const ValueKey('habit-chip-focus')), findsOneWidget);
    expect(find.byKey(const ValueKey('habit-chip-stretch')), findsNothing);
  });

  testWidgets('the strip says how the day is going', (tester) async {
    await pumpLuqa(tester);

    // Three due, none finished: water is on two of four.
    expect(find.text('0/3'), findsOneWidget);
    // The chip is terse; the sentence lives in the semantics label.
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('habits-strip-all')))
          .label,
      'Habits, 0 of 3 done',
    );
  });

  testWidgets('ticking a habit on Today writes the resolved day', (
    tester,
  ) async {
    final habits = FakeHabitsRepository.sample(now: fixedNow);
    await pumpLuqa(tester, habitsRepository: habits);

    await tapOnStrip(tester, 'read');

    final written = habits.written.single;
    expect(written.habitId, 'read');
    expect(written.date, '2026-08-27');
    // The state, not the action: a replay of this lands on the same number.
    expect(written.count, 1);
    expect(written.completedAt, isNotNull);

    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('a count steps up one tap at a time and stops at its target', (
    tester,
  ) async {
    final habits = FakeHabitsRepository.sample(now: fixedNow);
    await pumpLuqa(tester, habitsRepository: habits);

    // Starts on two of four.
    await tapOnStrip(tester, 'water');
    expect(habits.written.last.count, 3);

    await tapOnStrip(tester, 'water');
    expect(habits.written.last.count, 4);
    expect(habits.written.last.completedAt, isNotNull);

    // Full, so the next tap takes one back off rather than overshooting.
    await tapOnStrip(tester, 'water');
    expect(habits.written.last.count, 3);
    expect(habits.written.last.completedAt, isNull);
  });

  testWidgets('the strip leads to the habits screen', (tester) async {
    await pumpLuqa(tester);
    await openHabits(tester);

    expect(find.byType(HabitsScreen), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    // The day list is what is due, so the Monday habit is still not here.
    expect(find.byKey(const ValueKey('habit-row-read')), findsOneWidget);
    expect(find.byKey(const ValueKey('habit-row-stretch')), findsNothing);
  });

  testWidgets('another day shows what that day actually holds', (tester) async {
    await pumpLuqa(tester);
    await openHabits(tester);

    // Monday the 24th, in the same week as the pinned Thursday, is the only
    // day Stretch is due.
    await tester.tap(find.text('24'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('habit-row-stretch')), findsOneWidget);
  });

  testWidgets('the habits screen browsing a day does not move the strip', (
    tester,
  ) async {
    final habits = FakeHabitsRepository.sample(now: fixedNow);
    await pumpLuqa(tester, habitsRepository: habits);
    await openHabits(tester);

    // Monday the 24th, three days before the pinned Thursday.
    await tester.tap(find.text('24'));
    await tester.pumpAndSettle();
    await tester.tap(controlFor('read'));
    await tester.pumpAndSettle();
    expect(habits.written.single.date, '2026-08-24');

    // Back on the timeline, the strip belongs to the day the timeline is
    // showing — not to a selection made on another screen — so it is still on
    // today and a tap lands on today.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapOnStrip(tester, 'read');
    expect(habits.written.last.date, '2026-08-27');
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('the strip follows the timeline onto another day', (
    tester,
  ) async {
    final habits = FakeHabitsRepository.sample(now: fixedNow);
    await pumpLuqa(tester, habitsRepository: habits);

    await shiftTimeline(tester, -1);

    // The row is Wednesday's now, and so is the tap.
    await tapOnStrip(tester, 'read');
    expect(habits.written.single.date, '2026-08-26');

    // And the tally is that day's, not today's.
    expect(find.text('1/3'), findsOneWidget);

    // Back on today, which was never ticked.
    await shiftTimeline(tester, 1);
    expect(find.text('0/3'), findsOneWidget);
  });

  testWidgets('a habit not due on the day scrolled to is not on the strip', (
    tester,
  ) async {
    await pumpLuqa(tester);

    // Monday the 24th is the only day Stretch is due, and the pinned day is
    // the Thursday after it.
    expect(find.byKey(const ValueKey('habit-chip-stretch')), findsNothing);
    await shiftTimeline(tester, -3);

    await scrollStripTo(tester, 'habit-chip-stretch');
    expect(find.byKey(const ValueKey('habit-chip-stretch')), findsOneWidget);
  });

  testWidgets('reopening the habits screen starts on today again', (
    tester,
  ) async {
    await pumpLuqa(tester);
    await openHabits(tester);

    await tester.tap(find.text('24'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await openHabits(tester);

    // The controller outlives the screen, so the day it was left on would
    // otherwise still be selected.
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('a day with nothing due says so rather than looking broken', (
    tester,
  ) async {
    await pumpLuqa(
      tester,
      habitsRepository: FakeHabitsRepository(
        now: fixedNow,
        habits: [
          Habit(
            id: 'stretch',
            name: 'Stretch',
            icon: null,
            colorValue: 0xFF6366F1,
            order: 0,
            goalType: HabitGoalType.task,
            goalPeriod: HabitGoalPeriod.day,
            targetCount: 1,
            targetSeconds: 0,
            categoryId: null,
            scheduleType: HabitScheduleType.weekdays,
            weekdays: const [1],
            weekInterval: 1,
            intervalDays: 2,
            intervalFromLastDone: false,
            timesPerPeriod: 3,
            anchorDate: null,
            dates: const [],
            excludedDates: const [],
            archived: false,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      ),
    );
    await openHabits(tester);

    expect(find.text('Nothing due'), findsOneWidget);
  });

  testWidgets('with no habits at all, Today offers the way to make one', (
    tester,
  ) async {
    await pumpLuqa(tester, habitsRepository: FakeHabitsRepository());

    expect(find.text('Add a habit'), findsOneWidget);
    await openHabits(tester);
    expect(find.text('No habits yet'), findsOneWidget);
  });

  testWidgets('a habit can be made from the habits screen', (tester) async {
    final habits = FakeHabitsRepository(now: fixedNow);
    await pumpLuqa(tester, habitsRepository: habits);
    await openHabits(tester);

    await tester.tap(find.byKey(const ValueKey('habits-new')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('habit-name')), 'Walk');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('habit-save')));
    await tester.pumpAndSettle();

    expect(await habits.loadHabits(), hasLength(1));
    expect((await habits.loadHabits()).single.name, 'Walk');
    expect(find.text('Walk'), findsOneWidget);
  });

  testWidgets('an every-few-days habit can be set to count from the last time', (
    tester,
  ) async {
    final habits = FakeHabitsRepository(now: fixedNow);
    await pumpLuqa(tester, habitsRepository: habits);
    await openHabits(tester);

    await tester.tap(find.byKey(const ValueKey('habits-new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('habit-name')), 'Shave');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Every N'));
    await tester.pumpAndSettle();
    // The default interval is two days, so the choice is offered.
    await tester.tap(find.text('From the last time'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Miss one and the whole cycle shifts along.'),
      findsOneWidget,
    );
    expect(find.text('Every 2 days · from the last'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('habit-save')));
    await tester.pumpAndSettle();

    final saved = (await habits.loadHabits()).single;
    expect(saved.scheduleType, HabitScheduleType.interval);
    expect(saved.intervalFromLastDone, isTrue);
  });

  testWidgets('a one-day interval is not offered the choice', (tester) async {
    await pumpLuqa(tester, habitsRepository: FakeHabitsRepository());
    await openHabits(tester);

    await tester.tap(find.byKey(const ValueKey('habits-new')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Every N'));
    await tester.pumpAndSettle();
    expect(find.text('From the last time'), findsOneWidget);

    // Counted from either end, every day is every day.
    await tester.tap(find.byTooltip('Fewer'));
    await tester.pumpAndSettle();
    expect(find.text('Every day'), findsWidgets);
    expect(find.text('From the last time'), findsNothing);
  });

  testWidgets('a habit with no name cannot be saved', (tester) async {
    await pumpLuqa(tester, habitsRepository: FakeHabitsRepository());
    await openHabits(tester);

    await tester.tap(find.byKey(const ValueKey('habits-new')));
    await tester.pumpAndSettle();

    final save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('habit-save')),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('logging time on a linked category moves its habit there and then', (
    tester,
  ) async {
    await pumpLuqa(
      tester,
      habitsRepository: FakeHabitsRepository(
        now: fixedNow,
        habits: [
          // A habit whose progress *is* tracked time: nothing is ever written
          // against it directly, so the only thing that can move it is a block
          // appearing on the timeline. Fifty minutes against the half hour
          // already on the day, so it takes one more block to finish.
          Habit(
            id: 'deep',
            name: 'Deep work',
            icon: null,
            colorValue: 0xFF6366F1,
            order: 0,
            goalType: HabitGoalType.time,
            goalPeriod: HabitGoalPeriod.day,
            targetCount: 1,
            targetSeconds: 50 * 60,
            categoryId: 'food',
            scheduleType: HabitScheduleType.daily,
            weekdays: const [],
            weekInterval: 1,
            intervalDays: 2,
            intervalFromLastDone: false,
            timesPerPeriod: 3,
            anchorDate: null,
            dates: const [],
            excludedDates: const [],
            archived: false,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      ),
    );

    expect(find.text('0/1'), findsOneWidget);

    // Compose a half-hour block on the grid and file it under the habit's
    // category — the ordinary way time gets logged.
    await tapTimelineAt(tester, const Offset(200, 560));
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-draft-button')));
    await tester.pumpAndSettle();

    // No sync round, no visit to the habits screen: the strip already knows.
    expect(find.text('0/1'), findsNothing);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('habits-strip-all'))).label,
      'Habits, 1 of 1 done',
    );
  });

  testWidgets('insights show a streak for each habit', (tester) async {
    await pumpLuqa(tester);
    await openHabits(tester);

    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();

    // Every habit is here, due today or not.
    expect(find.text('Stretch'), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsNWidgets(4));
  });
}
