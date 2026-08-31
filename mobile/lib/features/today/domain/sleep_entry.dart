import 'dart:math' as math;

/// One block of the stage timeline. Stage names are normalized server-side, so
/// both clients read the same vocabulary.
class SleepStage {
  const SleepStage({
    required this.stage,
    required this.start,
    required this.end,
  });

  final String stage;
  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);

  SleepStageKind get kind => switch (stage.toUpperCase()) {
    'DEEP' => SleepStageKind.deep,
    'REM' => SleepStageKind.rem,
    'LIGHT' => SleepStageKind.light,
    'ASLEEP' || 'SLEEPING' => SleepStageKind.asleep,
    'AWAKE' || 'RESTLESS' || 'AWAKE_IN_BED' => SleepStageKind.awake,
    'OUT_OF_BED' => SleepStageKind.outOfBed,
    _ => SleepStageKind.unknown,
  };
}

/// Ordered as a hypnogram reads, shallowest first. Anything the provider could
/// not classify keeps its own bucket rather than being silently counted as
/// sleep.
enum SleepStageKind {
  awake('Awake'),
  outOfBed('Out of bed'),
  rem('REM'),
  light('Light'),
  deep('Deep'),
  asleep('Asleep'),
  unknown('Unscored');

  const SleepStageKind(this.label);

  final String label;

  bool get isAsleep =>
      this == rem || this == light || this == deep || this == asleep;
}

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
    this.awakeInBedMinutes,
    this.outOfBedMinutes,
    this.unknownMinutes,
    this.inBedMinutes,
    this.efficiencyPercent,
    this.latencyMinutes,
    this.wasoMinutes,
    this.awakeningCount,
    this.midpoint,
    this.recordingMethod,
    this.deviceModel,
    this.stages = const [],
  });

  final String id;
  final String source;
  final String? sourceApp;
  final String? title;
  final DateTime start;
  final DateTime end;
  final int? sleepMinutes;
  final int? awakeMinutes;
  final int? awakeInBedMinutes;
  final int? outOfBedMinutes;
  final int? lightMinutes;
  final int? deepMinutes;
  final int? remMinutes;
  final int? unknownMinutes;
  final int? inBedMinutes;
  final double? efficiencyPercent;
  final int? latencyMinutes;
  final int? wasoMinutes;
  final int? awakeningCount;
  final DateTime? midpoint;
  final bool isNap;
  final String? recordingMethod;
  final String? deviceModel;
  final List<SleepStage> stages;

  /// Minutes actually asleep. Providers that only report time in bed leave
  /// `sleepMinutes` null, so fall back to the session minus known wake time.
  Duration get asleep {
    final reported = sleepMinutes;
    if (reported != null) return Duration(minutes: reported);
    final total = end.difference(start).inMinutes - (awakeMinutes ?? 0);
    return Duration(minutes: math.max(0, total));
  }

  /// Wall-clock length of the session, which is what the timeline occupies.
  Duration get inBed => inBedMinutes != null
      ? Duration(minutes: inBedMinutes!)
      : end.difference(start);

  /// Asleep over time in bed. Derived when the provider did not report it, so
  /// the number is present whenever it can be trusted.
  double? get efficiency {
    final reported = efficiencyPercent;
    if (reported != null) return reported;
    final bed = inBed.inMinutes;
    if (bed <= 0 || sleepMinutes == null) return null;
    return (sleepMinutes! / bed) * 100;
  }

  /// Minutes per stage, counting only what the provider actually scored.
  Map<SleepStageKind, int> get stageTotals {
    final totals = <SleepStageKind, int>{};

    void add(SleepStageKind kind, int? minutes) {
      if (minutes == null || minutes <= 0) return;
      totals[kind] = (totals[kind] ?? 0) + minutes;
    }

    add(SleepStageKind.deep, deepMinutes);
    add(SleepStageKind.rem, remMinutes);
    add(SleepStageKind.light, lightMinutes);
    add(SleepStageKind.unknown, unknownMinutes);
    add(SleepStageKind.awake, awakeMinutes);
    add(SleepStageKind.outOfBed, outOfBedMinutes);

    // A provider that reported nothing but a total still deserves a bar.
    if (totals.isEmpty && sleepMinutes != null && sleepMinutes! > 0) {
      totals[SleepStageKind.asleep] = sleepMinutes!;
    }
    return totals;
  }

  bool get hasStageTimeline => stages.length > 1;

  /// Provider application when it is known, otherwise the platform store.
  String get attribution => sourceApp ?? _sourceLabels[source] ?? source;
}

const _sourceLabels = {
  'HEALTH_CONNECT': 'Health Connect',
  'APPLE_HEALTH': 'Apple Health',
  'GOOGLE_HEALTH': 'Google Health',
  'MANUAL': 'Manual',
};
