import 'package:luqa/features/today/domain/timeline_geometry.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _shortWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String fullDate(DateTime value) =>
    '${_weekdays[value.weekday - 1]}, ${value.day} ${_months[value.month - 1]}';

String shortDate(DateTime value) =>
    '${value.day} ${_shortMonths[value.month - 1]}';

String shortWeekday(DateTime value) => _shortWeekdays[value.weekday - 1];

/// "Today", "Yesterday", "Tomorrow", or the weekday and date. `now` is passed
/// in so the label never reads the clock during a build.
String relativeDayLabel(DateTime day, DateTime now) {
  final today = dayNumber(startOfLogicalDay(now));
  final delta = dayNumber(day) - today;
  return switch (delta) {
    0 => 'Today',
    -1 => 'Yesterday',
    1 => 'Tomorrow',
    _ =>
      '${_shortWeekdays[day.weekday - 1]}, ${day.day} '
          '${_shortMonths[day.month - 1]}',
  };
}

String clock(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

String clockFromMinutes(num minutes) {
  final total =
      ((minutes.round() % minutesPerDay) + minutesPerDay) % minutesPerDay;
  return '${(total ~/ 60).toString().padLeft(2, '0')}:'
      '${(total % 60).toString().padLeft(2, '0')}';
}

/// "1h 25m", "45m", "2h" for durations on blocks and totals.
String compactDuration(Duration value) {
  final total = value.inMinutes < 0 ? 0 : value.inMinutes;
  final hours = total ~/ 60;
  final minutes = total % 60;
  if (hours == 0) return '${minutes}m';
  if (minutes == 0) return '${hours}h';
  return '${hours}h ${minutes}m';
}

/// "0:41:07" for the running timer, which ticks once a second.
String stopwatch(Duration value) {
  final total = value.inSeconds < 0 ? 0 : value.inSeconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  return '$hours:${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
