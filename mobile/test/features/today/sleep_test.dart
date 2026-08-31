import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';
import 'package:luqa/features/today/domain/time_entry.dart';
import 'package:luqa/features/today/domain/timeline_geometry.dart';

void main() {
  final day = DateTime(2026, 8, 27);
  DateTime at(int hour, [int minute = 0]) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  SleepEntry night({
    required DateTime start,
    required DateTime end,
    int? sleepMinutes,
    int? awakeMinutes,
    int? lightMinutes,
    int? deepMinutes,
    int? remMinutes,
    List<SleepStage> stages = const [],
  }) => SleepEntry(
    id: 'sleep-1',
    source: 'HEALTH_CONNECT',
    sourceApp: 'Pixel Watch',
    title: null,
    start: start,
    end: end,
    sleepMinutes: sleepMinutes,
    awakeMinutes: awakeMinutes,
    lightMinutes: lightMinutes,
    deepMinutes: deepMinutes,
    remMinutes: remMinutes,
    isNap: false,
    stages: stages,
  );

  TimeEntry entry(DateTime start, DateTime end) => TimeEntry(
    id: '${start.hour}',
    description: 'Work',
    categoryId: null,
    start: start,
    end: end,
  );

  group('gaps', () {
    test('a night is not offered as untracked time', () {
      // Without this the morning gap runs from midnight, inviting the owner to
      // log eight hours they spent asleep.
      final gaps = computeGaps(
        [entry(at(9), at(11))],
        [night(start: at(0), end: at(7))],
        day,
        at(12),
        isToday: true,
      );

      expect(gaps.any((gap) => gap.startMin < 7 * 60), isFalse);
    });

    test('a gap beside a night starts where the night ended', () {
      final gaps = computeGaps(
        [entry(at(9), at(11))],
        [night(start: at(23).subtract(const Duration(days: 1)), end: at(7))],
        day,
        at(12),
        isToday: true,
      );

      final morning = gaps.firstWhere((gap) => gap.startMin < 9 * 60);
      expect(morning.startMin, 7 * 60);
      expect(morning.endMin, 9 * 60);
    });

    test('sleep alone still leaves the rest of the day open', () {
      final gaps = computeGaps(
        const [],
        [night(start: at(0), end: at(7))],
        day,
        at(10),
        isToday: true,
      );

      expect(gaps.single.startMin, 7 * 60);
      expect(gaps.single.endMin, 10 * 60);
    });

    test('a nap in the middle of the day splits the gap around it', () {
      final gaps = computeGaps(
        [entry(at(9), at(11))],
        [night(start: at(13), end: at(14))],
        day,
        at(16),
        isToday: true,
      );

      expect(gaps.map((gap) => (gap.startMin, gap.endMin)), [
        (11 * 60.0, 13 * 60.0),
        (14 * 60.0, 16 * 60.0),
      ]);
    });
  });

  group('sleep metrics', () {
    test('asleep falls back to the session minus known wake time', () {
      final session = night(
        start: at(23),
        end: at(23).add(const Duration(hours: 8)),
        awakeMinutes: 30,
      );

      expect(session.asleep, const Duration(minutes: 450));
    });

    test('efficiency is derived when the provider did not report it', () {
      final session = night(
        start: at(22),
        end: at(22).add(const Duration(hours: 8)),
        sleepMinutes: 420,
      );

      // 420 asleep of 480 in bed.
      expect(session.efficiency!.round(), 88);
    });

    test('stage totals keep unscored time out of the sleep stages', () {
      final session = night(
        start: at(22),
        end: at(22).add(const Duration(hours: 8)),
        sleepMinutes: 420,
        awakeMinutes: 30,
        lightMinutes: 240,
        deepMinutes: 90,
        remMinutes: 90,
      );

      expect(session.stageTotals, {
        SleepStageKind.deep: 90,
        SleepStageKind.rem: 90,
        SleepStageKind.light: 240,
        SleepStageKind.awake: 30,
      });
    });

    test('a totals-only night still gets one bar to show', () {
      final session = night(
        start: at(22),
        end: at(22).add(const Duration(hours: 7)),
        sleepMinutes: 400,
      );

      expect(session.stageTotals, {SleepStageKind.asleep: 400});
      expect(session.hasStageTimeline, isFalse);
    });

    test('stage names map onto the kinds the chart draws', () {
      String kindOf(String stage) =>
          SleepStage(stage: stage, start: at(1), end: at(2)).kind.name;

      expect(kindOf('DEEP'), 'deep');
      expect(kindOf('REM'), 'rem');
      expect(kindOf('LIGHT'), 'light');
      expect(kindOf('RESTLESS'), 'awake');
      expect(kindOf('AWAKE_IN_BED'), 'awake');
      expect(kindOf('OUT_OF_BED'), 'outOfBed');
      expect(kindOf('SLEEPING'), 'asleep');
      expect(kindOf('SOMETHING_NEW'), 'unknown');
    });
  });
}
