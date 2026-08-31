import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/design_system/luqa_theme.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/presentation/sleep_detail_sheet.dart';

import '../helpers/fake_timeline_repository.dart';
import '../helpers/pump_luqa.dart';

Future<void> _pumpSheet(
  WidgetTester tester,
  SleepEntry entry, {
  required ThemeMode themeMode,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(412, 915);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: LuqaTheme.light,
      darkTheme: LuqaTheme.dark,
      themeMode: themeMode,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showSleepDetailSheet(context, entry),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  final night = FakeTimelineRepository(today: fixedNow).sleep.single;

  testWidgets('Sleep detail light', (tester) async {
    await _pumpSheet(tester, night, themeMode: ThemeMode.light);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('sleep_detail_light.png'),
    );
  });

  testWidgets('Sleep detail dark', (tester) async {
    await _pumpSheet(tester, night, themeMode: ThemeMode.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('sleep_detail_dark.png'),
    );
  });

  testWidgets('a night reported without stages still reads', (tester) async {
    final totalsOnly = SleepEntry(
      id: 'sleep-2',
      source: 'HEALTH_CONNECT',
      sourceApp: null,
      title: null,
      start: night.start,
      end: night.end,
      sleepMinutes: 437,
      awakeMinutes: null,
      lightMinutes: null,
      deepMinutes: null,
      remMinutes: null,
      isNap: false,
    );

    await _pumpSheet(tester, totalsOnly, themeMode: ThemeMode.light);

    // A totals-only provider still gets a single "Asleep" band rather than an
    // apology, so the sheet never renders as an empty frame.
    expect(find.textContaining('without a stage breakdown'), findsNothing);
    expect(find.text('Asleep'), findsOneWidget);
    expect(find.text('7h 17m'), findsWidgets);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('sleep_detail_totals_only.png'),
    );
  });
}
