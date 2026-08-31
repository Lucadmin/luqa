import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:luqa/features/health/data/health_connect_reader.dart';
import 'package:luqa_api/api.dart' as api;

/// Builds a point the way the plugin returns one: every point of a sleep session
/// carries the parent record's id as [uuid].
HealthDataPoint point({
  required String uuid,
  required HealthDataType type,
  required DateTime from,
  required DateTime to,
  String sourceName = 'Samsung Health',
  RecordingMethod recordingMethod = RecordingMethod.automatic,
}) => HealthDataPoint(
  uuid: uuid,
  value: NumericHealthValue(
    numericValue: to.difference(from).inMinutes.toDouble(),
  ),
  type: type,
  unit: HealthDataUnit.MINUTE,
  dateFrom: from,
  dateTo: to,
  sourcePlatform: HealthPlatformType.googleHealthConnect,
  sourceDeviceId: 'device',
  sourceId: '',
  sourceName: sourceName,
  recordingMethod: recordingMethod,
);

void main() {
  final night = DateTime.utc(2026, 8, 26, 22, 30);

  group('buildSleepSessions', () {
    test('rebuilds a session with its stage timeline, ordered', () {
      final sessions = buildSleepSessions([
        // Deliberately out of order — the reader must sort.
        point(
          uuid: 'rec-1',
          type: HealthDataType.SLEEP_REM,
          from: night.add(const Duration(hours: 2)),
          to: night.add(const Duration(hours: 3)),
        ),
        point(
          uuid: 'rec-1',
          type: HealthDataType.SLEEP_SESSION,
          from: night,
          to: night.add(const Duration(hours: 8)),
        ),
        point(
          uuid: 'rec-1',
          type: HealthDataType.SLEEP_DEEP,
          from: night,
          to: night.add(const Duration(hours: 2)),
        ),
      ]);

      expect(sessions, hasLength(1));
      final session = sessions.single;
      expect(session.externalId.value, 'rec-1');
      expect(session.startTime, night);
      expect(session.endTime, night.add(const Duration(hours: 8)));
      expect(session.sourceApp.value, 'Samsung Health');
      expect(session.stages.value?.map((stage) => stage.stage).toList(), [
        'DEEP',
        'REM',
      ]);
    });

    test('keeps sessions apart and does not merge stages across records', () {
      final sessions = buildSleepSessions([
        point(
          uuid: 'rec-1',
          type: HealthDataType.SLEEP_SESSION,
          from: night,
          to: night.add(const Duration(hours: 8)),
        ),
        point(
          uuid: 'rec-1',
          type: HealthDataType.SLEEP_LIGHT,
          from: night,
          to: night.add(const Duration(hours: 8)),
        ),
        point(
          uuid: 'rec-2',
          type: HealthDataType.SLEEP_SESSION,
          from: night.add(const Duration(days: 1)),
          to: night.add(const Duration(days: 1, hours: 7)),
        ),
      ]);

      expect(sessions.map((s) => s.externalId.value), ['rec-1', 'rec-2']);
      expect(sessions.first.stages.value, hasLength(1));
      expect(sessions.last.stages.value, isEmpty);
    });

    test('sends no totals, leaving the arithmetic to the server', () {
      final session = buildSleepSessions([
        point(
          uuid: 'rec-1',
          type: HealthDataType.SLEEP_SESSION,
          from: night,
          to: night.add(const Duration(hours: 8)),
        ),
        point(
          uuid: 'rec-1',
          type: HealthDataType.SLEEP_DEEP,
          from: night,
          to: night.add(const Duration(hours: 2)),
        ),
      ]).single;

      expect(session.sleepMinutes.isPresent, isFalse);
      expect(session.deepMinutes.isPresent, isFalse);
      expect(session.awakeMinutes.isPresent, isFalse);
    });

    test('recovers a session whose stages arrived without their parent', () {
      final sessions = buildSleepSessions([
        point(
          uuid: 'orphan',
          type: HealthDataType.SLEEP_LIGHT,
          from: night,
          to: night.add(const Duration(hours: 3)),
        ),
        point(
          uuid: 'orphan',
          type: HealthDataType.SLEEP_DEEP,
          from: night.add(const Duration(hours: 3)),
          to: night.add(const Duration(hours: 5)),
        ),
      ]);

      final session = sessions.single;
      expect(session.startTime, night);
      expect(session.endTime, night.add(const Duration(hours: 5)));
      expect(session.stages.value, hasLength(2));
    });

    test('maps every stage type Luqa reads onto a server stage name', () {
      final stageTypes = <HealthDataType>[
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_AWAKE_IN_BED,
        HealthDataType.SLEEP_OUT_OF_BED,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_UNKNOWN,
      ];
      final points = <HealthDataPoint>[
        point(
          uuid: 'rec-1',
          type: HealthDataType.SLEEP_SESSION,
          from: night,
          to: night.add(Duration(hours: stageTypes.length)),
        ),
        for (var i = 0; i < stageTypes.length; i++)
          point(
            uuid: 'rec-1',
            type: stageTypes[i],
            from: night.add(Duration(hours: i)),
            to: night.add(Duration(hours: i + 1)),
          ),
      ];

      final stages = buildSleepSessions(points).single.stages.value!;
      expect(stages.map((stage) => stage.stage), [
        'ASLEEP',
        'AWAKE',
        'AWAKE_IN_BED',
        'OUT_OF_BED',
        'LIGHT',
        'DEEP',
        'REM',
        'UNKNOWN',
      ]);
    });

    test('flags a short daytime sleep as a nap but not an overnight one', () {
      final nap = buildSleepSessions([
        point(
          uuid: 'nap',
          type: HealthDataType.SLEEP_SESSION,
          from: DateTime(2026, 8, 27, 14),
          to: DateTime(2026, 8, 27, 15),
        ),
      ]).single;
      final overnight = buildSleepSessions([
        point(
          uuid: 'night',
          type: HealthDataType.SLEEP_SESSION,
          from: DateTime(2026, 8, 26, 23),
          to: DateTime(2026, 8, 27, 7),
        ),
      ]).single;

      expect(nap.isNap.value, isTrue);
      expect(overnight.isNap.value, isFalse);
    });

    test('carries the recording method through as the wire enum', () {
      final manual = buildSleepSessions([
        point(
          uuid: 'rec-1',
          type: HealthDataType.SLEEP_SESSION,
          from: night,
          to: night.add(const Duration(hours: 8)),
          recordingMethod: RecordingMethod.manual,
        ),
      ]).single;

      expect(
        manual.recordingMethod.value,
        api.SleepSessionImportRecordingMethodEnum.MANUAL_ENTRY,
      );
    });

    test('drops points that are not sleep', () {
      final sessions = buildSleepSessions([
        point(
          uuid: 'steps',
          type: HealthDataType.STEPS,
          from: night,
          to: night.add(const Duration(hours: 1)),
        ),
      ]);

      expect(sessions, isEmpty);
    });
  });
}
