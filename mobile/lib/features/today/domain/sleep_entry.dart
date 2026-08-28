import 'dart:math' as math;

/// A sleep session read from the platform health store. Sleep is measured, not
/// tracked: the timeline shows it as context behind the day rather than as
/// something the owner logged.
class SleepEntry {
  const SleepEntry({
    required this.id,
    required this.source,
    required this.sourceApp,
    required this.title,
    required this.start,
    required this.end,
    required this.sleepMinutes,
    required this.awakeMinutes,
    required this.lightMinutes,
    required this.deepMinutes,
    required this.remMinutes,
    required this.isNap,
  });

  final String id;
  final String source;
  final String? sourceApp;
  final String? title;
  final DateTime start;
  final DateTime end;
  final int? sleepMinutes;
  final int? awakeMinutes;
  final int? lightMinutes;
  final int? deepMinutes;
  final int? remMinutes;
  final bool isNap;

  /// Minutes actually asleep. Providers that only report time in bed leave
  /// `sleepMinutes` null, so fall back to the session minus known wake time.
  Duration get asleep {
    final reported = sleepMinutes;
    if (reported != null) return Duration(minutes: reported);
    final total = end.difference(start).inMinutes - (awakeMinutes ?? 0);
    return Duration(minutes: math.max(0, total));
  }

  /// Provider application when it is known, otherwise the platform store.
  String get attribution => sourceApp ?? _sourceLabels[source] ?? source;
}

const _sourceLabels = {
  'HEALTH_CONNECT': 'Health Connect',
  'APPLE_HEALTH': 'Apple Health',
  'GOOGLE_HEALTH': 'Google Health',
  'MANUAL': 'Manual',
};
