import 'package:health/health.dart';
import 'package:luqa_api/api.dart' as api;

/// A platform data type Luqa knows how to ingest.
///
/// Adding a metric is meant to be one entry here plus the matching Android
/// permission in the manifest — the reader, the push, and the sync bookkeeping
/// are all driven off this list rather than written per metric.
class HealthMetricDescriptor {
  const HealthMetricDescriptor({
    required this.metric,
    required this.types,
    required this.convert,
  });

  /// The Luqa-side metric this maps onto.
  final api.HealthMetricType metric;

  /// Platform types to request permission for and read.
  final List<HealthDataType> types;

  /// Turns one platform point into a wire sample. Returning null skips it.
  final api.HealthSampleImport? Function(HealthDataPoint point) convert;
}

/// Reads a plain numeric value off a point, or null when it is not numeric.
double? numericValue(HealthDataPoint point) {
  final value = point.value;
  return value is NumericHealthValue ? value.numericValue.toDouble() : null;
}

/// Builds the standard sample shape for a scalar metric.
api.HealthSampleImport? scalarSample(
  api.HealthMetricType metric,
  HealthDataPoint point,
) {
  final value = numericValue(point);
  if (value == null) return null;
  return api.HealthSampleImport(
    externalId: point.uuid,
    metric: metric,
    startTime: point.dateFrom.toUtc(),
    endTime: point.dateTo.toUtc(),
    value: value,
    sourceApp: api.Optional.present(point.sourceName),
  );
}

/// Metrics currently switched on.
///
/// Sleep is deliberately absent: a session carries a stage timeline, so it takes
/// its own reader and its own endpoint payload rather than one row per sample.
/// The list is empty until a scalar metric is enabled — which also needs its
/// Health Connect permission declared in AndroidManifest.xml, since Play Console
/// reviews every health permission an app asks for.
const List<HealthMetricDescriptor> enabledHealthMetrics = <HealthMetricDescriptor>[
  // Example, once android.permission.health.READ_STEPS is declared:
  // HealthMetricDescriptor(
  //   metric: api.HealthMetricType.STEPS,
  //   types: [HealthDataType.STEPS],
  //   convert: (point) => scalarSample(api.HealthMetricType.STEPS, point),
  // ),
];
