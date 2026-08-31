import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/today/data/outbox.dart';
import 'package:luqa/features/today/data/today_repository.dart';
import 'package:luqa/features/today/domain/category.dart';
import 'package:luqa/features/today/domain/time_entry.dart';

final _at = DateTime.utc(2026, 8, 31, 9);

TimeEntry _entry(
  String id, {
  String? categoryId,
  String description = 'Work',
}) => TimeEntry(
  id: id,
  description: description,
  categoryId: categoryId,
  start: DateTime.utc(2026, 8, 31, 10),
  end: DateTime.utc(2026, 8, 31, 11),
);

TimelineWindow _window(List<TimeEntry> entries) => TimelineWindow(
  from: DateTime.utc(2026, 8, 31),
  to: DateTime.utc(2026, 9, 1),
  entries: entries,
  sleep: const [],
);

void main() {
  group('folding', () {
    test('an edit to an unsent block changes the block itself', () {
      final queue = foldInto(
        const [],
        CreateEntry(entry: _entry('a'), queuedAt: _at),
      );

      final folded = foldInto(
        queue,
        UpdateEntry(
          entryId: 'a',
          patch: const EntryPatch(description: 'Reading'),
          queuedAt: _at,
        ),
      );

      expect(folded, hasLength(1));
      expect((folded.single as CreateEntry).entry.description, 'Reading');
    });

    test('deleting an unsent block sends nothing at all', () {
      var queue = foldInto(
        const [],
        CreateEntry(entry: _entry('a'), queuedAt: _at),
      );
      queue = foldInto(
        queue,
        UpdateEntry(
          entryId: 'a',
          patch: const EntryPatch(description: 'Reading'),
          queuedAt: _at,
        ),
      );

      queue = foldInto(queue, DeleteEntry(entryId: 'a', queuedAt: _at));

      expect(queue, isEmpty);
    });

    test(
      'deleting a synced block drops its queued edits but keeps the delete',
      () {
        var queue = foldInto(
          const [],
          UpdateEntry(
            entryId: 'server-1',
            patch: const EntryPatch(description: 'Reading'),
            queuedAt: _at,
          ),
        );

        queue = foldInto(
          queue,
          DeleteEntry(entryId: 'server-1', queuedAt: _at),
        );

        expect(queue.single, isA<DeleteEntry>());
      },
    );

    test('successive edits to one row collapse into a single patch', () {
      var queue = foldInto(
        const [],
        UpdateEntry(
          entryId: 'server-1',
          patch: const EntryPatch(description: 'Reading'),
          queuedAt: _at,
        ),
      );
      queue = foldInto(
        queue,
        UpdateEntry(
          entryId: 'server-1',
          patch: EntryPatch(end: DateTime.utc(2026, 8, 31, 12)),
          queuedAt: _at,
        ),
      );

      final patch = (queue.single as UpdateEntry).patch;
      expect(queue, hasLength(1));
      expect(patch.description, 'Reading');
      expect(patch.end, DateTime.utc(2026, 8, 31, 12));
    });

    test('mutations to different rows stay in the order they were made', () {
      var queue = foldInto(
        const [],
        CreateEntry(entry: _entry('a'), queuedAt: _at),
      );
      queue = foldInto(queue, DeleteEntry(entryId: 'b', queuedAt: _at));
      queue = foldInto(queue, CreateEntry(entry: _entry('c'), queuedAt: _at));

      expect(queue.map((pending) => pending.subjectId), ['a', 'b', 'c']);
    });
  });

  group('patch merging', () {
    test('a later removal wins over an earlier assignment', () {
      final merged = mergePatches(
        const EntryPatch(categoryId: 'food'),
        const EntryPatch(clearCategory: true),
      );

      expect(merged.clearCategory, isTrue);
      expect(merged.categoryId, isNull);
    });

    test('a patch that says nothing about the category leaves it alone', () {
      final merged = mergePatches(
        const EntryPatch(categoryId: 'food'),
        const EntryPatch(description: 'Lunch'),
      );

      expect(merged.categoryId, 'food');
      expect(merged.clearCategory, isFalse);
      expect(merged.description, 'Lunch');
    });
  });

  group('overlay', () {
    test('an unsent block appears on the timeline, marked pending', () {
      final overlaid = overlayPending(_window(const []), [
        CreateEntry(entry: _entry('a'), queuedAt: _at),
      ]);

      expect(overlaid.entries.single.id, 'a');
      expect(overlaid.entries.single.pendingSync, isTrue);
    });

    test('an unsent delete hides the row the server still has', () {
      final overlaid = overlayPending(_window([_entry('server-1')]), [
        DeleteEntry(entryId: 'server-1', queuedAt: _at),
      ]);

      expect(overlaid.entries, isEmpty);
    });

    test('an unsent edit is shown over the server copy', () {
      final overlaid = overlayPending(_window([_entry('server-1')]), [
        UpdateEntry(
          entryId: 'server-1',
          patch: const EntryPatch(description: 'Reading'),
          queuedAt: _at,
        ),
      ]);

      expect(overlaid.entries.single.description, 'Reading');
      expect(overlaid.entries.single.pendingSync, isTrue);
    });

    test('a block created outside the window does not leak into it', () {
      final elsewhere = TimeEntry(
        id: 'a',
        description: 'Work',
        categoryId: null,
        start: DateTime.utc(2026, 9, 5, 10),
        end: DateTime.utc(2026, 9, 5, 11),
      );

      final overlaid = overlayPending(_window(const []), [
        CreateEntry(entry: elsewhere, queuedAt: _at),
      ]);

      expect(overlaid.entries, isEmpty);
    });

    test(
      'a category invented offline is offered alongside the server list',
      () {
        final categories = overlayPendingCategories(
          const [Category(id: 'food', name: 'Food', colorValue: 0xFF000000)],
          [
            CreateCategory(
              category: const Category(
                id: 'local-1',
                name: 'Admin',
                colorValue: 0xFF111111,
              ),
              queuedAt: _at,
            ),
          ],
        );

        expect(categories.map((value) => value.name), ['Admin', 'Food']);
      },
    );
  });

  group('category remapping', () {
    test('queued entries follow the id the server actually chose', () {
      final queue = [
        CreateEntry(
          entry: _entry('a', categoryId: 'local-1'),
          queuedAt: _at,
        ),
        CreateEntry(
          entry: _entry('b', categoryId: 'food'),
          queuedAt: _at,
        ),
      ];

      final remapped = remapCategoryId(queue, 'local-1', 'server-9');

      expect((remapped[0] as CreateEntry).entry.categoryId, 'server-9');
      expect((remapped[1] as CreateEntry).entry.categoryId, 'food');
    });
  });

  group('persistence', () {
    test('every kind of mutation survives a round trip', () {
      final queue = <TimelineMutation>[
        CreateEntry(
          entry: _entry('a', categoryId: 'food'),
          queuedAt: _at,
        ),
        UpdateEntry(
          entryId: 'b',
          patch: const EntryPatch(description: 'Reading', clearCategory: true),
          queuedAt: _at,
        ),
        DeleteEntry(entryId: 'c', queuedAt: _at),
        CreateCategory(
          category: const Category(
            id: 'd',
            name: 'Admin',
            colorValue: 0xFF111111,
          ),
          queuedAt: _at,
        ),
      ];

      final restored = [
        for (final pending in queue)
          TimelineMutation.fromJson(pending.toJson())!,
      ];

      expect(restored.map((pending) => pending.subjectId), [
        'a',
        'b',
        'c',
        'd',
      ]);
      expect((restored[0] as CreateEntry).entry.categoryId, 'food');
      expect((restored[1] as UpdateEntry).patch.clearCategory, isTrue);
      expect((restored[3] as CreateCategory).category.name, 'Admin');
    });

    test('an op written by a newer build is skipped rather than fatal', () {
      expect(
        TimelineMutation.fromJson({
          'op': 'reticulateSplines',
          'queuedAt': _at.toIso8601String(),
        }),
        isNull,
      );
    });
  });
}
