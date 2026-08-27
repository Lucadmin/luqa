import 'dart:io';

import 'package:health/health.dart';
import 'package:luqa/features/health/domain/health_metric.dart';
import 'package:luqa_api/api.dart' as api;

/// Whether the platform health store can be used at all.
enum HealthAvailability {
  /// Health Connect is installed and usable.
  available,

  /// Installed but too old to talk to.
  updateRequired,

  /// Not installed.
  notInstalled,

  /// Not an Android device. Health Connect is Android-only; iOS will need a
  /// HealthKit path before sleep can sync there.
  unsupportedPlatform,
}

/// The platform types Luqa reads for one sleep session.
///
/// SLEEP_SESSION is the session itself; the rest are its stages. The plugin
/// returns every stage point carrying its parent session's record id as `uuid`,
/// which is what lets [HealthConnectReader.readSleep] rebuild whole sessions.
const _sleepTypes = <HealthDataType>[
  HealthDataType.SLEEP_SESSION,
  HealthDataType.SLEEP_ASLEEP,
  HealthDataType.SLEEP_AWAKE,
  HealthDataType.SLEEP_AWAKE_IN_BED,
  HealthDataType.SLEEP_OUT_OF_BED,
  HealthDataType.SLEEP_LIGHT,
  HealthDataType.SLEEP_DEEP,
  HealthDataType.SLEEP_REM,
  HealthDataType.SLEEP_UNKNOWN,
];

/// One device read, ready to push.
class HealthReadResult {
  const HealthReadResult({
    required this.sleep,
    required this.samples,
    required this.from,
    required this.to,
  });

  final List<api.SleepSessionImport> sleep;
  final List<api.HealthSampleImport> samples;
  final DateTime from;
  final DateTime to;

  bool get isEmpty => sleep.isEmpty && samples.isEmpty;
}

/// Reads health data from the on-device store.
///
/// Wraps the `health` plugin so the rest of the app never imports it directly,
/// which keeps the controller testable against a fake.
abstract interface class HealthReader {
  Future<HealthAvailability> availability();

  /// Whether every type Luqa needs is already granted.
  Future<bool> hasPermissions();

  /// Opens the platform permission sheet. Returns whether access was granted.
  Future<bool> requestPermissions();

  /// Sends the user to install or update Health Connect.
  Future<void> openInstall();

  Future<HealthReadResult> read({required DateTime from, required DateTime to});
}

class HealthConnectReader implements HealthReader {
  HealthConnectReader({Health? health, List<HealthMetricDescriptor>? metrics})
    : _health = health ?? Health(),
      _metrics = metrics ?? enabledHealthMetrics;

  final Health _health;
  final List<HealthMetricDescriptor> _metrics;
  bool _configured = false;

  List<HealthDataType> get _allTypes => [
    ..._sleepTypes,
    for (final descriptor in _metrics) ...descriptor.types,
  ];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<HealthAvailability> availability() async {
    if (!Platform.isAndroid) return HealthAvailability.unsupportedPlatform;
    await _ensureConfigured();
    final status = await _health.getHealthConnectSdkStatus();
    return switch (status) {
      HealthConnectSdkStatus.sdkAvailable => HealthAvailability.available,
      HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
        HealthAvailability.updateRequired,
      _ => HealthAvailability.notInstalled,
    };
  }

  @override
  Future<bool> hasPermissions() async {
    await _ensureConfigured();
    return await _health.hasPermissions(_allTypes) ?? false;
  }

  @override
  Future<bool> requestPermissions() async {
    await _ensureConfigured();
    return _health.requestAuthorization(
      _allTypes,
      permissions: List.filled(_allTypes.length, HealthDataAccess.READ),
    );
  }

  @override
  Future<void> openInstall() async {
    await _ensureConfigured();
    await _health.installHealthConnect();
  }

  @override
  Future<HealthReadResult> read({
    required DateTime from,
    required DateTime to,
  }) async {
    await _ensureConfigured();
    final points = await _health.getHealthDataFromTypes(
      types: _allTypes,
      startTime: from,
      endTime: to,
    );

    final samples = <api.HealthSampleImport>[];
    for (final descriptor in _metrics) {
      for (final point in points.where(
        (point) => descriptor.types.contains(point.type),
      )) {
        final sample = descriptor.convert(point);
        if (sample != null) samples.add(sample);
      }
    }

    return HealthReadResult(
      sleep: buildSleepSessions(points),
      samples: samples,
      from: from,
      to: to,
    );
  }
}

/// Stage type -> the stage name the server normalizes on.
const _stageNames = <HealthDataType, String>{
  HealthDataType.SLEEP_ASLEEP: 'ASLEEP',
  HealthDataType.SLEEP_AWAKE: 'AWAKE',
  HealthDataType.SLEEP_AWAKE_IN_BED: 'AWAKE_IN_BED',
  HealthDataType.SLEEP_OUT_OF_BED: 'OUT_OF_BED',
  HealthDataType.SLEEP_LIGHT: 'LIGHT',
  HealthDataType.SLEEP_DEEP: 'DEEP',
  HealthDataType.SLEEP_REM: 'REM',
  HealthDataType.SLEEP_UNKNOWN: 'UNKNOWN',
};

/// A nap, by the usual convention: a daytime sleep under three hours. Health
/// Connect has no nap flag, so this is inferred rather than reported.
bool _looksLikeNap(DateTime start, Duration length) =>
    length.inMinutes < 180 && start.hour >= 8 && start.hour < 20;

api.SleepSessionImportRecordingMethodEnum _recordingMethod(
  RecordingMethod method,
) => switch (method) {
  RecordingMethod.automatic =>
    api.SleepSessionImportRecordingMethodEnum.AUTOMATICALLY_RECORDED,
  RecordingMethod.active =>
    api.SleepSessionImportRecordingMethodEnum.ACTIVELY_RECORDED,
  RecordingMethod.manual =>
    api.SleepSessionImportRecordingMethodEnum.MANUAL_ENTRY,
  RecordingMethod.unknown =>
    api.SleepSessionImportRecordingMethodEnum.UNKNOWN,
};

/// Rebuilds whole sleep sessions from the flat point list the plugin returns.
///
/// Every point belonging to one Health Connect `SleepSessionRecord` — the
/// session and each of its stages — carries that record's id as `uuid`, so
/// grouping by uuid reassembles the session with its stage timeline intact.
/// Exposed for tests, which is why it takes points rather than a reader.
List<api.SleepSessionImport> buildSleepSessions(List<HealthDataPoint> points) {
  final sessions = <String, HealthDataPoint>{};
  final stages = <String, List<HealthDataPoint>>{};

  for (final point in points) {
    if (point.type == HealthDataType.SLEEP_SESSION) {
      sessions[point.uuid] = point;
    } else if (_stageNames.containsKey(point.type)) {
      stages.putIfAbsent(point.uuid, () => []).add(point);
    }
  }

  // A stage without its session still describes real sleep — keep it by falling
  // back to the span its stages cover.
  for (final uuid in stages.keys) {
    sessions.putIfAbsent(uuid, () => stages[uuid]!.first);
  }

  final result = <api.SleepSessionImport>[];
  for (final entry in sessions.entries) {
    // Copy before sorting: the no-stage fallback is a const list, and the map's
    // list must not be reordered underneath its owner.
    final own = [...?stages[entry.key]]
      ..sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
    final session = entry.value;

    final start = own.isEmpty
        ? session.dateFrom
        : own
              .map((point) => point.dateFrom)
              .reduce((a, b) => a.isBefore(b) ? a : b);
    final end = own.isEmpty
        ? session.dateTo
        : own.map((point) => point.dateTo).reduce((a, b) => a.isAfter(b) ? a : b);
    final windowStart = session.type == HealthDataType.SLEEP_SESSION
        ? session.dateFrom
        : start;
    final windowEnd = session.type == HealthDataType.SLEEP_SESSION
        ? session.dateTo
        : end;
    if (!windowEnd.isAfter(windowStart)) continue;

    result.add(
      api.SleepSessionImport(
        externalId: api.Optional.present(entry.key),
        startTime: windowStart.toUtc(),
        endTime: windowEnd.toUtc(),
        sourceApp: api.Optional.present(session.sourceName),
        isNap: api.Optional.present(
          _looksLikeNap(windowStart, windowEnd.difference(windowStart)),
        ),
        recordingMethod: api.Optional.present(
          _recordingMethod(session.recordingMethod),
        ),
        deviceModel: api.Optional.present(session.deviceModel),
        // Totals are left out on purpose: the server derives every minute count
        // and quality metric from this timeline, so there is one implementation
        // of that arithmetic rather than one per client.
        stages: api.Optional.present([
          for (final stage in own)
            api.SleepStage(
              stage: _stageNames[stage.type]!,
              startTime: stage.dateFrom.toUtc(),
              endTime: stage.dateTo.toUtc(),
            ),
        ]),
      ),
    );
  }

  result.sort((a, b) => a.startTime.compareTo(b.startTime));
  return result;
}
