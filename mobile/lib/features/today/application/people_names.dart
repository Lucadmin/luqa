import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luqa/features/people/application/people_controller.dart';

/// Turns a set of person ids into the names a timeline row shows.
///
/// Lives on the Today side because it is a presentation concern: People owns
/// who these are, Today decides how many of them fit on one line.
final personNamesProvider = Provider<String Function(List<String>)>((ref) {
  final people = ref.watch(peopleControllerProvider).people;
  final byId = {for (final person in people) person.id: person.displayName};

  return (ids) {
    final names = [
      for (final id in ids)
        // An id with no name is somebody this device has not synced yet. It is
        // dropped rather than rendered as a ULID, and the row simply shows the
        // people it can name.
        if (byId[id] != null) byId[id]!,
    ]..sort();
    if (names.isEmpty) return ids.isEmpty ? '' : 'Someone';
    if (names.length <= 2) return names.join(' and ');
    // Three names is already longer than a timeline row wants.
    return '${names.take(2).join(', ')} +${names.length - 2}';
  };
});
