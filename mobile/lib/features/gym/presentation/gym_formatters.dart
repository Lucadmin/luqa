import 'package:flutter/material.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

/// A workout's day, as short as it can be without becoming ambiguous.
///
/// The year is only dropped for the year we are in. A log that goes back
/// years otherwise reads as though every entry happened this season, which is
/// exactly what makes an old set impossible to place.
String gymDayLabel(BuildContext context, String dateKey, DateTime now) {
  final date = DateTime.tryParse(dateKey);
  if (date == null) return dateKey;
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  final label = MaterialLocalizations.of(context).formatMediumDate(day);
  return day.year == now.year ? label : '$label, ${day.year}';
}

/// The same day with the year always shown, for lists that are read as
/// history rather than as recent activity.
String gymDatedLabel(BuildContext context, DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return '${MaterialLocalizations.of(context).formatMediumDate(day)}, '
      '${day.year}';
}

String gymSessionSummary(GymSession session) {
  final exerciseCount = session.exercises.length;
  final setCount = session.completedSetCount;
  if (exerciseCount == 0) return 'Workout started';
  final exercises =
      '$exerciseCount ${exerciseCount == 1 ? 'exercise' : 'exercises'}';
  final sets = '$setCount ${setCount == 1 ? 'set' : 'sets'}';
  return '$exercises · $sets';
}

String gymReferenceSummary(GymExercisePoint? point) {
  if (point == null || point.sets.isEmpty) return '';
  return point.sets.map(formatGymSet).join(' · ');
}
