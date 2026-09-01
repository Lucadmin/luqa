import 'package:luqa/features/insights/domain/insights_models.dart';
import 'package:luqa/features/insights/presentation/insights_formatters.dart';
import 'package:luqa/features/today/presentation/today_formatters.dart';

/// One derived fact, in the shape the readings list draws: a value that can be
/// read at a glance and a sentence saying what it is.
class InsightsReading {
  const InsightsReading({
    required this.id,
    required this.value,
    required this.headline,
    this.detail,
  });

  /// Stable across rebuilds, so the list can key on it.
  final String id;

  final String value;
  final String headline;
  final String? detail;
}

/// Turns the arithmetic into the handful of things worth saying about a span.
///
/// Only readings that are actually supported by data are returned, in a fixed
/// order. A number nobody can act on is worse than a shorter list: an average
/// over one day is not an average, and a weekend difference needs a weekday to
/// be different from.
List<InsightsReading> buildInsightsReadings(InsightsReport report) {
  final facts = report.facts;
  final readings = <InsightsReading>[];

  final start = facts.typicalStartMinutes;
  final end = facts.typicalEndMinutes;
  if (start != null && end != null && facts.daysTracked >= 2) {
    readings.add(
      InsightsReading(
        id: 'shape',
        value: '${clockFromMinutes(start)} → ${clockFromMinutes(end)}',
        headline: 'Your day, end to end',
        detail:
            'Averaged over the ${facts.daysTracked} days you tracked '
            'anything at all',
      ),
    );
  }

  final average = facts.averageSleepMinutes;
  final midpoint = facts.sleepMidpointMinutes;
  if (average != null && facts.nights > 0) {
    readings.add(
      InsightsReading(
        id: 'sleep',
        value: compactDuration(Duration(minutes: average.round())),
        headline: 'Asleep on an average night',
        detail: midpoint == null
            ? '${facts.nights} nights measured'
            : 'Midpoint ${clockFromMinutes(midpoint)} · '
                  '${facts.nights} nights measured',
      ),
    );
  }

  final drift = facts.weekendMidpointDrift;
  // Under a quarter of an hour is the width of the measurement, not a pattern.
  if (drift != null && drift.abs() >= 15) {
    readings.add(
      InsightsReading(
        id: 'drift',
        value: signedDuration(drift),
        headline: drift > 0 ? 'Later at the weekend' : 'Earlier at the weekend',
        detail:
            'Where your sleep midpoint lands after a Friday or Saturday, '
            'against the rest of the week',
      ),
    );
  }

  final longest = facts.longestBlock;
  if (longest != null) {
    readings.add(
      InsightsReading(
        id: 'longest',
        value: compactDuration(Duration(minutes: longest.minutes.round())),
        headline: 'Longest unbroken stretch',
        detail: '${longest.description} · ${fullDate(longest.day)}',
      ),
    );
  }

  final hour = facts.fullestHour;
  if (hour != null && facts.fullestHourMinutes > 0) {
    readings.add(
      InsightsReading(
        id: 'hour',
        value: '${hour.toString().padLeft(2, '0')}:00',
        headline: 'Your fullest hour',
        detail:
            '${compactDuration(Duration(minutes: facts.fullestHourMinutes.round()))} '
            'of this span passed through it',
      ),
    );
  }

  final weekday = facts.busiestWeekday;
  if (weekday != null && facts.busiestWeekdayMinutes > 0) {
    readings.add(
      InsightsReading(
        id: 'weekday',
        value: weekdayName(weekday),
        headline: 'Your heaviest weekday',
        detail:
            '${compactDuration(Duration(minutes: facts.busiestWeekdayMinutes.round()))} '
            'on an average one',
      ),
    );
  }

  if (facts.daysWithCompany > 0) {
    readings.add(
      InsightsReading(
        id: 'company',
        value: facts.daysWithCompany == 1
            ? '1 day'
            : '${facts.daysWithCompany} days',
        headline: 'Spent with someone',
        detail: 'Days with a person on at least one block',
      ),
    );
  }

  if (facts.accountedFraction > 0) {
    readings.add(
      InsightsReading(
        id: 'accounted',
        value: percent(facts.accountedFraction),
        headline: 'Accounted for',
        detail:
            'Of the time that has actually passed, this much is tracked '
            'time or measured sleep',
      ),
    );
  }

  return readings;
}
