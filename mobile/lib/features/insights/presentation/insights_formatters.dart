import 'package:luqa/features/today/domain/timeline_geometry.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';

/// "3–9 Aug", "28 Jul – 3 Aug", "9 Jun 2025 – 9 Aug 2026".
///
/// [to] is exclusive, the way every range in the app is; the label names the
/// last day that is actually in it.
String insightsRangeLabel(DateTime from, DateTime to) {
  final last = addDays(to, -1);
  if (from.year != last.year) {
    return '${shortDate(from)} ${from.year} – ${shortDate(last)} ${last.year}';
  }
  if (from.month == last.month) return '${from.day}–${shortDate(last)}';
  return '${shortDate(from)} – ${shortDate(last)}';
}

/// "+2h 15m" / "−45m" / "±0m". Uses a real minus sign, which lines up with the
/// plus at the same optical weight where a hyphen does not.
String signedDuration(double minutes) {
  final rounded = minutes.round();
  if (rounded == 0) return '±0m';
  final magnitude = compactDuration(Duration(minutes: rounded.abs()));
  return '${rounded > 0 ? '+' : '−'}$magnitude';
}

String percent(double fraction) => '${(fraction * 100).round()}%';

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// [weekday] as `DateTime.monday`..`DateTime.sunday` numbers it.
String weekdayName(int weekday) => _weekdayNames[weekday - 1];

/// One-letter column headers for the rhythm wall. Ambiguous on their own —
/// which is why the wall also carries dates and every column has a full
/// spoken label.
String weekdayInitial(int weekday) => _weekdayNames[weekday - 1][0];

bool isWeekend(DateTime day) =>
    day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
