import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/features/money/application/money_controller.dart';
import 'package:luqa/features/people/domain/people_math.dart';
import 'package:luqa/features/people/domain/person.dart';
import 'package:luqa/features/today/application/timeline_controller.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

/// The blocks of time somebody was tagged on, newest first.
///
/// Read from the timeline the device already holds, so this works offline and
/// costs nothing extra — the entries are on screen anyway.
final sharedEntriesProvider = Provider<List<TimeEntry> Function(String)>((ref) {
  final entries = ref.watch(timelineControllerProvider).entries;
  return (personId) => [
    for (final entry in entries)
      if (entry.personIds.contains(personId)) entry,
  ]..sort((a, b) => b.start.compareTo(a.start));
});

/// When each person was really last seen.
///
/// The newest of: a date set by hand, the end of a timeline entry they were
/// tagged on, and the day of a bill shared with them. Money already knows you
/// had dinner together; it should not have to be typed twice.
final lastSeenProvider = Provider<DateTime? Function(Person)>((ref) {
  final entries = ref.watch(timelineControllerProvider).entries;
  final overview = ref.watch(moneyControllerProvider).overview;

  final taggedAt = <String, DateTime>{};
  for (final entry in entries) {
    final at = entry.end ?? entry.start;
    for (final personId in entry.personIds) {
      final known = taggedAt[personId];
      if (known == null || at.isAfter(known)) taggedAt[personId] = at;
    }
  }

  final sharedAt = <String, DateTime>{};
  for (final balance in overview?.people ?? const []) {
    final day = balance.lastActivity;
    if (day == null) continue;
    final parsed = DateTime.tryParse(day);
    if (parsed != null) sharedAt[balance.id] = parsed;
  }

  return (person) => effectiveLastSeen(
    person,
    taggedAt: taggedAt[person.id],
    sharedAt: sharedAt[person.id],
  );
});
