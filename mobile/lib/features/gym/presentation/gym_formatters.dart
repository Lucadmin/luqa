import 'package:flutter/material.dart';
import 'package:luqa/features/gym/domain/gym_models.dart';

String gymDayLabel(BuildContext context, String dateKey, DateTime now) {
  final date = DateTime.tryParse(dateKey);
  if (date == null) return dateKey;
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  return MaterialLocalizations.of(context).formatMediumDate(day);
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
