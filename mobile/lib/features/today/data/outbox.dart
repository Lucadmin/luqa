import 'package:luqa/core/sync/outbox.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

/// The writes the timeline can make while offline.
sealed class TimelineMutation implements PendingMutation {
  const TimelineMutation({required this.queuedAt});

  @override
  final DateTime queuedAt;

  static TimelineMutation? fromJson(Map<String, Object?> json) {
    final queuedAt = DateTime.tryParse(json['queuedAt'] as String? ?? '');
    if (queuedAt == null) return null;
    return switch (json['op']) {
      'createEntry' => CreateEntry(
        entry: _entryFromJson(json['entry']! as Map<String, Object?>),
        queuedAt: queuedAt,
      ),
      'updateEntry' => UpdateEntry(
        entryId: json['entryId']! as String,
        patch: _patchFromJson(json['patch']! as Map<String, Object?>),
        queuedAt: queuedAt,
      ),
      'deleteEntry' => DeleteEntry(
        entryId: json['entryId']! as String,
        queuedAt: queuedAt,
      ),
      'createCategory' => CreateCategory(
        category: _categoryFromJson(json['category']! as Map<String, Object?>),
        queuedAt: queuedAt,
      ),
      // An op written by a newer build is not something this one can replay.
      _ => null,
    };
  }
}

final class CreateEntry extends TimelineMutation {
  const CreateEntry({required this.entry, required super.queuedAt});

  final TimeEntry entry;

  @override
  String get subjectId => entry.id;

  @override
  Map<String, Object?> toJson() => {
    'op': 'createEntry',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'entry': _entryToJson(entry),
  };
}

final class UpdateEntry extends TimelineMutation {
  const UpdateEntry({
    required this.entryId,
    required this.patch,
    required super.queuedAt,
  });

  final String entryId;
  final EntryPatch patch;

  @override
  String get subjectId => entryId;

  @override
  Map<String, Object?> toJson() => {
    'op': 'updateEntry',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'entryId': entryId,
    'patch': _patchToJson(patch),
  };
}

final class DeleteEntry extends TimelineMutation {
  const DeleteEntry({required this.entryId, required super.queuedAt});

  final String entryId;

  @override
  String get subjectId => entryId;

  @override
  Map<String, Object?> toJson() => {
    'op': 'deleteEntry',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'entryId': entryId,
  };
}

final class CreateCategory extends TimelineMutation {
  const CreateCategory({required this.category, required super.queuedAt});

  final Category category;

  @override
  String get subjectId => category.id;

  @override
  Map<String, Object?> toJson() => {
    'op': 'createCategory',
    'queuedAt': queuedAt.toUtc().toIso8601String(),
    'category': _categoryToJson(category),
  };
}

/// Appends [next], folding it into what is already queued for the same row.
///
/// Coalescing is not an optimisation here, it is correctness: a block that was
/// drawn, nudged twice and then deleted while offline must reach the server as
/// nothing at all, not as four requests racing to describe a row that no longer
/// exists.
List<TimelineMutation> foldInto(
  List<TimelineMutation> queue,
  TimelineMutation next,
) {
  switch (next) {
    case DeleteEntry(:final entryId):
      final createdHere = queue.any(
        (pending) => pending is CreateEntry && pending.entry.id == entryId,
      );
      final rest = [
        for (final pending in queue)
          if (pending.subjectId != entryId) pending,
      ];
      // Never created on the server, so there is nothing there to delete.
      return createdHere ? rest : [...rest, next];

    case UpdateEntry(:final entryId, :final patch):
      final folded = <TimelineMutation>[];
      var absorbed = false;
      for (final pending in queue) {
        switch (pending) {
          // An edit to a block the server has not seen yet is just a different
          // block to create.
          case CreateEntry(:final entry) when entry.id == entryId:
            folded.add(
              CreateEntry(
                entry: applyPatch(entry, patch),
                queuedAt: pending.queuedAt,
              ),
            );
            absorbed = true;
          case UpdateEntry(entryId: final id, patch: final earlier)
              when id == entryId:
            folded.add(
              UpdateEntry(
                entryId: entryId,
                patch: mergePatches(earlier, patch),
                queuedAt: pending.queuedAt,
              ),
            );
            absorbed = true;
          case _:
            folded.add(pending);
        }
      }
      return absorbed ? folded : [...folded, next];

    case CreateEntry() || CreateCategory():
      return [...queue, next];
  }
}

/// [later] wins field by field; anything it leaves unset keeps [earlier]'s
/// value, which is what applying the two in order would have produced.
EntryPatch mergePatches(EntryPatch earlier, EntryPatch later) {
  // The category needs both fields read together: null alone means "unchanged"
  // there, so removing one travels as its own flag.
  final laterSetsCategory = later.categoryId != null || later.clearCategory;
  return EntryPatch(
    description: later.description ?? earlier.description,
    categoryId: laterSetsCategory ? later.categoryId : earlier.categoryId,
    clearCategory: laterSetsCategory
        ? later.clearCategory
        : earlier.clearCategory,
    start: later.start ?? earlier.start,
    end: later.end ?? earlier.end,
  );
}

TimeEntry applyPatch(TimeEntry entry, EntryPatch patch) => entry.copyWith(
  description: patch.description,
  categoryId: patch.categoryId,
  clearCategory: patch.clearCategory,
  start: patch.start,
  end: patch.end,
);

/// Lays the queue over a server snapshot, so what the user sees is what they
/// did, whether or not it has been sent yet.
///
/// The snapshot itself is never rewritten. Once a mutation is acknowledged it
/// simply leaves the queue and the overlay stops applying it, which means a
/// dropped or rejected write can never leave a stale row behind.
TimelineWindow overlayPending(
  TimelineWindow window,
  List<TimelineMutation> queue,
) {
  if (queue.isEmpty) return window;

  final entries = <String, TimeEntry>{
    for (final entry in window.entries) entry.id: entry,
  };
  for (final pending in queue) {
    switch (pending) {
      case CreateEntry(:final entry):
        entries[entry.id] = entry.copyWith(pendingSync: true);
      case UpdateEntry(:final entryId, :final patch):
        final existing = entries[entryId];
        if (existing == null) continue;
        entries[entryId] = applyPatch(
          existing,
          patch,
        ).copyWith(pendingSync: true);
      case DeleteEntry(:final entryId):
        entries.remove(entryId);
      case CreateCategory():
        continue;
    }
  }

  final merged = entries.values.toList()
    ..sort((left, right) => left.start.compareTo(right.start));
  return TimelineWindow(
    from: window.from,
    to: window.to,
    // A block created while the window was elsewhere must not leak into a day
    // it does not belong to.
    entries: merged
        .where(
          (entry) =>
              entry.start.isBefore(window.to) &&
              entry.endOrNow().isAfter(window.from),
        )
        .toList(growable: false),
    sleep: window.sleep,
  );
}

List<Category> overlayPendingCategories(
  List<Category> categories,
  List<TimelineMutation> queue,
) {
  final pending = [
    for (final mutation in queue)
      if (mutation is CreateCategory &&
          !categories.any((existing) => existing.id == mutation.category.id))
        mutation.category,
  ];
  if (pending.isEmpty) return categories;
  return [...categories, ...pending]
    ..sort((left, right) => left.name.compareTo(right.name));
}

Map<String, Object?> _entryToJson(TimeEntry value) => {
  'id': value.id,
  'description': value.description,
  'categoryId': value.categoryId,
  'start': value.start.toUtc().toIso8601String(),
  'end': value.end?.toUtc().toIso8601String(),
};

TimeEntry _entryFromJson(Map<String, Object?> value) => TimeEntry(
  id: value['id']! as String,
  description: value['description']! as String,
  categoryId: value['categoryId'] as String?,
  start: DateTime.parse(value['start']! as String).toLocal(),
  end: value['end'] == null
      ? null
      : DateTime.parse(value['end']! as String).toLocal(),
  pendingSync: true,
);

Map<String, Object?> _patchToJson(EntryPatch value) => {
  'description': value.description,
  'categoryId': value.categoryId,
  'clearCategory': value.clearCategory,
  'start': value.start?.toUtc().toIso8601String(),
  'end': value.end?.toUtc().toIso8601String(),
};

EntryPatch _patchFromJson(Map<String, Object?> value) => EntryPatch(
  description: value['description'] as String?,
  categoryId: value['categoryId'] as String?,
  clearCategory: value['clearCategory'] as bool? ?? false,
  start: value['start'] == null
      ? null
      : DateTime.parse(value['start']! as String).toLocal(),
  end: value['end'] == null
      ? null
      : DateTime.parse(value['end']! as String).toLocal(),
);

Map<String, Object?> _categoryToJson(Category value) => {
  'id': value.id,
  'name': value.name,
  'colorValue': value.colorValue,
};

Category _categoryFromJson(Map<String, Object?> value) => Category(
  id: value['id']! as String,
  name: value['name']! as String,
  colorValue: value['colorValue']! as int,
);

/// Rewrites every reference to a locally minted id once the server has named
/// the row something else. Only categories need it: a name that already exists
/// server-side comes back under its original id, and the entries queued behind
/// it are still pointing at the one this device made up.
List<TimelineMutation> remapCategoryId(
  List<TimelineMutation> queue,
  String from,
  String to,
) {
  if (from == to) return queue;
  return [
    for (final pending in queue)
      switch (pending) {
        CreateEntry(:final entry) when entry.categoryId == from => CreateEntry(
          entry: entry.copyWith(categoryId: to),
          queuedAt: pending.queuedAt,
        ),
        UpdateEntry(:final entryId, :final patch)
            when patch.categoryId == from =>
          UpdateEntry(
            entryId: entryId,
            patch: EntryPatch(
              description: patch.description,
              categoryId: to,
              start: patch.start,
              end: patch.end,
            ),
            queuedAt: pending.queuedAt,
          ),
        _ => pending,
      },
  ];
}
